_.extend JustdoAiKit.prototype,
  apis: {}

  _createVendorApiObjOptionsSchema: new SimpleSchema
    model_name: 
      type: String
    requestOptionsMapper:
      type: Function
      optional: true
  _createVendorApiObj: (vendor_name, options) ->
    check vendor_name, String
    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @_createVendorApiObjOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
    options = cleaned_val

    self = @
    model_name = options.model_name
    requestOptionsMapper = options.requestOptionsMapper

    vendor_api_obj = 
      _newChatCompletion: (template, template_data, log_id, user_id) ->
        if _.isString template
          template = self.requireRequestTemplate template

        # Generate the request before logging it to query_collection
        # so that if it throws an error, we won't log it.
        req = template.requestGenerator template_data
        if _.isEmpty req.model
          req.model = model_name
        
        # Map any OpenAI-specific parameters if provided
        if _.isFunction requestOptionsMapper
          req = requestOptionsMapper req
        
        # Calls the api, logs the API response to query_collection once full response is received.
        # Note we use different APIs for stream/non-stream calls, as stream api (beta) provides more useful events and methods.
        # For non-stream calls, chat_completion_obj is a Promise object;
        # For stream calls, chat_completion_obj is a ChatCompletionStreamingRunner object (refer to OpenAI Node API Lib).
        if req.stream
          # For stream calls, we need to explicitly add this option to receive the usage data.
          req.stream_options = 
            include_usage: true
          chat_completion_obj = self.apis[vendor_name].beta.chat.completions.stream req
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
          chat_completion_obj = self.apis[vendor_name].chat.completions.create req
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
      
      _newStream: (stream_type, template, template_data, log_id, user_id) ->
        ret = new EventEmitter()
        if not (stream_type_def = JustdoAiKit.supported_streamed_response_types[stream_type])?
          throw self._error "invalid-argument", "Stream type #{stream_type} not supported"

        stream = await self[vendor_name]._newChatCompletion template, template_data, log_id, user_id

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

    return vendor_api_obj

  registerVendorAPiOptionsSchema: new SimpleSchema
    sdk_type:
      type: String
      allowedValues: _.keys JustdoAiKit.sdk_map
      defaultValue: JustdoAiKit.default_sdk_type
    sdk_constructor_options:
      type: Object
      blackbox: true
    default_model:
      type: String
    requestOptionsMapper:
      type: Function
      optional: true
  registerVendorApi: (vendor_name, options) ->
    check vendor_name, String
    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @registerVendorAPiOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
    options = cleaned_val

    sdk_constructor = JustdoAiKit.sdk_map[options.sdk_type].constructor
    @apis[vendor_name] = new sdk_constructor(options.sdk_constructor_options)

    create_vendor_api_obj_options = 
      model_name: options.default_model
      requestOptionsMapper: options.requestOptionsMapper
    @[vendor_name] = @_createVendorApiObj(vendor_name, create_vendor_api_obj_options)

    return

  getVendorConf: (vendor_name, required_conf_keys, is_secret = false) ->
    check vendor_name, String
    check required_conf_keys, [String]
    check is_secret, Boolean
    
    ret = {}

    conf_key = "conf"
    if is_secret
      conf_key = "secret_conf"
    
    if _.isEmpty(vendor_conf = @[conf_key].vendors?[vendor_name])
      return ret

    for required_conf_key in required_conf_keys
      ret[required_conf_key] = vendor_conf[required_conf_key]
    
    return ret
  
  requireVendorConf: (vendor_name, required_conf_keys, is_secret = false) ->
    conf_name = "JUSTDO_AI_CONF"
    if is_secret
      conf_name = "JUSTDO_AI_SECRET_CONF"

    ret = @getVendorConf vendor_name, required_conf_keys, is_secret

    for required_conf_key in required_conf_keys
      if _.isEmpty ret[required_conf_key]
        throw @_error "missing-argument", "#{required_conf_key} is missing from #{conf_name}.vendors.#{vendor_name}. Aborting."
    
    return ret
