_.extend JustdoAiKit.prototype,
  _setupJustdo: ->
    http_module = Npm.require "https" 
    self = @

    @justdo = 
      # For future devs: When supporting other API vendors (Google Gemini, Mixtral, etc.), if you wish to support streamed responses,
      # you should implement _newChatCompletion with the same name and parameters so the higher level newStream can call it properly.
      _newChatCompletion: (template, template_data, log_id, user_id) ->
        if _.isString template
          template = self.requireRequestTemplate template

        # Generate the request before logging it to query_collection
        # so that if it throws an error, we won't log it.
        req = template.requestGenerator template_data

        # If external requests endpoint is configured, make HTTP request to it
        if not JustdoAiKit.default_api_provider_endpoint?
          throw self._error "missing-argument", "External requests endpoint is not configured"

        try
          # Create the request to the external server
          request_options = 
            template: template.template_id or template
            template_data: template_data
            user_id: user_id
            installation_id: APP.justdo_system_records?.getRecord?(JustdoSiteAdmins.installation_id_system_record_key)?.value
          
          # Add pre_register_id if user_id is not provided
          if not user_id? and (pre_register_id = self.query_collection.findOne(log_id)?.pre_register_id)?
            request_options.pre_register_id = pre_register_id
          
          # Make the HTTP request to the external server
          endpoint = "#{JustdoAiKit.default_api_provider_endpoint}/chat-completion"
          
          # Use HTTP package to make the request
          httpRequest = HTTP.post endpoint,
            data: request_options
            headers:
              "Content-Type": "application/json"
          
          # Process the response
          if httpRequest.statusCode is 200
            response = JSON.parse(httpRequest.content)
            
            # Update the local log with the response from the external server
            self.query_collection.update log_id, {$set: {res: response.res}}
            
            return response.res
          else
            throw new Error("External server returned status code #{httpRequest.statusCode}")
        catch err
          # Log the error and mark the request as failed
          console.error "Error setting up stream with external server:", err
          modifier = 
            $set:
              err: 
                message: err.message
          self.query_collection.update log_id, modifier
          throw err

      # For future devs: When supporting other API vendors (Google Gemini, Mixtral, etc.), if you wish to support streamed responses,
      # you should implement _newStream with the same name and parameters so the higher level newStream can call it properly.
      _newStream: (stream_type, template, template_data, log_id, user_id) ->
        if not (stream_type_def = JustdoAiKit.supported_streamed_response_types[stream_type])?
          throw self._error "invalid-argument", "Stream type #{stream_type} not supported"

        # If external requests endpoint is configured, use the external server
        if not JustdoAiKit.default_api_provider_endpoint?
          throw self._error "missing-argument", "External requests endpoint is not configured"

        try
          ret = new EventEmitter()
          
          # Get the req_id and pre_register_id from the log
          log_entry = self.query_collection.findOne(log_id)
          req_id = log_entry?.req_id
          pre_register_id = log_entry?.pre_register_id
          
          if not req_id?
            throw self._error "invalid-argument", "req_id is required for streaming requests"
          
          # Prepare the request data
          request_data = 
            template: template.template_id or template
            template_data: template_data
            req_id: req_id
            user_id: user_id
            installation_id: APP.justdo_system_records?.getRecord?(JustdoSiteAdmins.installation_id_system_record_key)?.value
          
          # Add pre_register_id if user_id is not provided
          if not user_id? and pre_register_id?
            request_data.pre_register_id = pre_register_id
          
          endpoint = "#{JustdoAiKit.default_api_provider_endpoint}/stream-chat-completion"
          
          # Prepare the request options
          post_data = JSON.stringify(request_data)
          request_options = 
            method: 'POST'
            headers:
              'Content-Type': 'application/json'
              'Content-Length': Buffer.byteLength(post_data)
          
          # For SSE parsing
          buffer = ""
          stream_state = {} # State for the parser
          
          # Create a flag to track if the connection is active
          connection_active = true
          
          req = http_module.request endpoint, request_options, Meteor.bindEnvironment (res) ->
            if res.statusCode isnt 200
              connection_active = false
              error = new Error("External server returned status code #{res.statusCode}")
              ret.emit "error", error
              
              # Log the error
              modifier = 
                $set:
                  err: 
                    message: error.message
              self.query_collection.update log_id, modifier
              
              return
            
            # Set encoding to UTF-8 for text processing
            res.setEncoding('utf8')
            
            # Process data chunks as they arrive
            res.on 'data', Meteor.bindEnvironment (chunk) ->
              if not connection_active
                return
                
              # Add the chunk to our buffer
              buffer += chunk
              
              # Process events until we can't find more double newlines
              while (eventEnd = buffer.indexOf("\n\n")) != -1
                # Extract the event data
                eventData = buffer.substring(0, eventEnd)
                # Remove the processed event from the buffer
                buffer = buffer.substring(eventEnd + 2)
                
                # Parse the event
                eventLines = eventData.split("\n")
                event = {}
                
                for line in eventLines
                  if line.indexOf("event: ") == 0
                    event.type = line.substring(7)
                  else if line.indexOf("data: ") == 0
                    event.data = line.substring(6)
                
                # Process the event if we have both type and data
                if event.type? and event.data?
                  try
                    switch event.type
                      when "chunk"
                        data = JSON.parse(event.data)
                        ret.emit "chunk", data.chunk, data.snapshot
                        if (parsed_item = stream_type_def.parser data.chunk, data.snapshot, stream_state)
                          ret.emit "parsed_item", parsed_item
                      when "parsed_item"
                        ret.emit "parsed_item", JSON.parse(event.data)
                      when "abort"
                        ret.emit "abort", JSON.parse(event.data)
                        connection_active = false
                      when "error"
                        ret.emit "error", JSON.parse(event.data)
                        connection_active = false
                      when "end"
                        ret.emit "end"
                        connection_active = false
                  catch parse_error
                    console.error "Error parsing SSE data:", parse_error, "Event data:", event
              
              return
            
            # Handle end of response
            res.on 'end', Meteor.bindEnvironment ->
              if not connection_active
                return
                
              connection_active = false
              
              # Process any remaining data in the buffer
              if buffer.length > 0
                # Try to process any remaining events
                eventLines = buffer.split("\n")
                event = {}
                
                for line in eventLines
                  if line.indexOf("event: ") == 0
                    event.type = line.substring(7)
                  else if line.indexOf("data: ") == 0
                    event.data = line.substring(6)
                
                # Process the event if we have both type and data
                if event.type? and event.data?
                  try
                    switch event.type
                      when "chunk"
                        data = JSON.parse(event.data)
                        ret.emit "chunk", data.chunk, data.snapshot
                        if (parsed_item = stream_type_def.parser data.chunk, data.snapshot, stream_state)
                          ret.emit "parsed_item", parsed_item
                      when "parsed_item"
                        ret.emit "parsed_item", JSON.parse(event.data)
                      when "abort"
                        ret.emit "abort", JSON.parse(event.data)
                      when "error"
                        ret.emit "error", JSON.parse(event.data)
                      when "end"
                        ret.emit "end"
                  catch parse_error
                    console.error "Error parsing remaining SSE data:", parse_error
              
              # Signal completion if we haven't already
              ret.emit "end"
              return
          
          # Handle request errors
          req.on 'error', Meteor.bindEnvironment (err) ->
            if not connection_active
              return
              
            connection_active = false
            console.error "Error in stream request:", err
            ret.emit "error", err
            
            # Log the error
            modifier = 
              $set:
                err: 
                  message: err.message
            self.query_collection.update log_id, modifier
            
            return
          
          # Implement stop method to abort the stream
          ret.stop = ->
            if not connection_active
              return
              
            connection_active = false
            
            # First try to abort the request
            req.abort?()
            
            # Send a stop request to the external server
            try
              stop_endpoint = "#{JustdoAiKit.default_api_provider_endpoint}/stop-stream"
              stop_data = JSON.stringify({req_id})
              
              stop_options = 
                method: 'POST'
                headers:
                  'Content-Type': 'application/json'
                  'Content-Length': Buffer.byteLength(stop_data)
              
              stop_req = http_module.request stop_endpoint, stop_options
              stop_req.on 'error', (err) ->
                console.error "Error sending stop request:", err
              
              stop_req.write(stop_data)
              stop_req.end()
            catch stop_err
              console.error "Error stopping external stream:", stop_err
          
            return
          
          # Send the request data
          req.write(post_data)
          req.end()
          
          return ret
        catch err
          # Log the error and mark the request as failed
          console.error "Error setting up stream with external server:", err
          modifier = 
            $set:
              err: 
                message: err.message
          self.query_collection.update log_id, modifier
          throw err
          
    return
