OpenAI = Npm.require "openai"

_.extend JustdoAiKit.prototype,
  _ollamaRequiredConf: []

  _setupOllama: ->
    ollama_secret_conf = @secret_conf.vendors?.ollama
    for required_conf in @_ollamaRequiredConf
      if _.isEmpty(ollama_secret_conf[required_conf])
        throw @_error "missing-argument", "#{required_conf} is missing from JUSTDO_AI_SECRET_CONF.ollama. Aborting."

    self = @

    # Ollama API can be accessed via OpenAI client with a different base URL
    @apis.ollama = new OpenAI
      apiKey: "ollama" # While Ollama does not require an api key, OpenAI SDK requires one.
      baseURL: @conf.vendors?.ollama?.base_url or JustdoAiKit.default_ollama_base_url

    @ollama = 
      # Implementation for Ollama using OpenAI SDK
      _newChatCompletion: (template, template_data, log_id, user_id) ->
        if _.isString template
          template = self.requireRequestTemplate template

        # Generate the request before logging it to query_collection
        # so that if it throws an error, we won't log it.
        req = template.requestGenerator template_data
        
        req.model = JustdoAiKit.ollama_template_generation_model

        # Map any OpenAI-specific parameters to Ollama equivalents if needed
        req = self.ollama._mapOpenAIToOllamaParams(req)

        # Calls the api, logs the API response to query_collection once full response is received.
        if req.stream
          chat_completion_obj = self.apis.ollama.beta.chat.completions.stream req
          do (chat_completion_obj, log_id) ->
            chat_completion_obj
              .on "chatCompletion", Meteor.bindEnvironment (res) ->
                self.query_collection.update log_id, {$set: {res}}
                return
              .on "abort", (abort_err) ->
                modifier = 
                  $set:
                    aborted: true
                if (incomplete_res = chat_completion_obj.currentChatCompletionSnapshot)?
                  modifier.$set.res = incomplete_res
                self.query_collection.update log_id, modifier
                return
              .on "error", (err) -> 
                modifier = 
                  $set:
                    err: 
                      message: err.message
                      stack: err.stack
                if (incomplete_res = chat_completion_obj.currentChatCompletionSnapshot)?
                  modifier.$set.res = incomplete_res
                self.query_collection.update log_id, modifier
                return
            return
        else
          chat_completion_obj = self.apis.ollama.chat.completions.create req
          do (chat_completion_obj, log_id) ->
            chat_completion_obj
              .then (res) ->
                self.query_collection.update log_id, {$set: {res}}
                return
              .catch (err) ->
                modifier = 
                  $set:
                    err: 
                      message: err.message
                      stack: err.stack
                self.query_collection.update log_id, modifier
                return
            return
            
        await return chat_completion_obj

      # Map any OpenAI specific parameters to Ollama equivalents
      _mapOpenAIToOllamaParams: (req) ->
        # Clone the request to avoid modifying the original
        mapped_req = _.clone(req)

        # Ollama-specific parameter adjustments
        # For example, Ollama might use different parameter names or values
        # This ensures compatibility with the OpenAI SDK interface

        # Map response_format to format if it exists
        if (json_schema = mapped_req.response_format?.json_schema)?
          mapped_req.format = json_schema
          delete mapped_req.response_format

        return mapped_req

      _newStream: (stream_type, template, template_data, log_id, user_id) ->
        ret = new EventEmitter()
        if not (stream_type_def = JustdoAiKit.supported_streamed_response_types[stream_type])?
          throw self._error "invalid-argument", "Stream type #{stream_type} not supported"

        stream = await self.ollama._newChatCompletion template, template_data, log_id, user_id

        stream_state = {} # State to be passed to the parser to allow it to keep track of intermediate results
        stream
          .on "chunk", (chunk, snapshot) ->
            ret.emit "chunk", chunk, snapshot
            if (parsed_item = stream_type_def.parser chunk, snapshot, stream_state)
              ret.emit "parsed_item", parsed_item
            return
          .on "abort", (abort_err) ->
            ret.emit "abort", abort_err
            return
          .on "error", (err) ->
            ret.emit "error", err
            return
          .on "end", -> ret.emit "end"
        
        ret.stop = ->
          stream.abort()
          return
        
        return ret

    return 