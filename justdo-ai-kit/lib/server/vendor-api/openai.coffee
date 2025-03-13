OpenAI = Npm.require "openai"

_.extend JustdoAiKit.prototype,
  _openAIRequiredConf: ["api_key"]

  _setupOpenAI: ->
    openai_secret_conf = @secret_conf.vendors?.openai
    for required_conf in @_openAIRequiredConf
      if _.isEmpty(openai_secret_conf[required_conf])
        throw @_error "missing-argument", "#{required_conf} is missing from JUSTDO_AI_SECRET_CONF.openai. Aborting."

    self = @

    @apis.openai = new OpenAI
      apiKey: openai_secret_conf.api_key

    @openai = 
      # For future devs: When supporting other API vendors (Google Gemini, Mixtral, etc.), if you wish to support streamed responses,
      # you should implement _newChatCompletion with the same name and parameters so the higher level newStream can call it properly.
      _newChatCompletion: (template, template_data, log_id, user_id) ->
        if _.isString template
          template = self.requireRequestTemplate template

        # Generate the request before logging it to query_collection
        # so that if it throws an error, we won't log it.
        req = template.requestGenerator template_data
        if _.isEmpty req.model
          req.model = JustdoAiKit.openai_template_generation_model

        # Calls the api, logs the API response to query_collection once full response is received.
        # Note we use different APIs for stream/non-stream calls, as stream api (beta) provides more useful events and methods.
        # For non-stream calls, chat_completion_obj is a Promise object;
        # For stream calls, chat_completion_obj is a ChatCompletionStreamingRunner object (refer to OpenAI Node API Lib).
        if req.stream
          chat_completion_obj = self.apis.openai.beta.chat.completions.stream req
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
          chat_completion_obj = self.apis.openai.chat.completions.create req
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

      # For future devs: When supporting other API vendors (Google Gemini, Mixtral, etc.), if you wish to support streamed responses,
      # you should implement _newStream with the same name and parameters so the higher level newStream can call it properly.
      _newStream: (stream_type, template, template_data, log_id, user_id) ->
        ret = new EventEmitter()
        if not (stream_type_def = JustdoAiKit.supported_streamed_response_types[stream_type])?
          throw self._error "invalid-argument", "Stream type #{stream_type} not supported"

        stream = await self.openai._newChatCompletion template, template_data, log_id, user_id

        stream_state = {} # State to be passed to the parser to allow it to keep track of intermediate results (or any other state)
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
  
