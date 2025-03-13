_.extend JustdoAiKit.prototype, 
  createStreamRequestAndSubscribeToResponse: (options, cb) ->
    self = @

    # Modify the options schema:
    # subOnReady and subOnStop are client side only. req_id will be generated below.
    # The rest of the options are defined in _createStreamRequestPublicationOptionsSchema
    options_schema = _.extend _.omit(self._createStreamRequestPublicationOptionsSchema, "req_id"),
      subOnReady: 
        type: Function
        optional: true
      subOnStop: 
        type: Function
        optional: true
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        new SimpleSchema(options_schema),
        options,
        {self: self, throw_on_error: true}
      )
    options = cleaned_val

    ret = null

    # If we are inside a computation, we need to stop the subscription when the computation is invalidated
    if Tracker.active
      Tracker.onInvalidate (computation) ->
        if ret?
          ret.stopSubscription()
      return

    Tracker.nonreactive =>
      req_id = Random.id()
      options.req_id = req_id

      if not Meteor.userId()?
        options.pre_register_id = APP.accounts.getPreRegisterId()

      sub_handle = Meteor.subscribe "createStreamRequest", options, 
        onReady: options?.subOnReady
        onStop: options?.subOnStop

      @setSubHandle options.req_id, sub_handle

      ret = 
        req_id: req_id

        _ensureQuerySubId: (query) ->
          query = _.extend {}, query, {req_id: @req_id}
          return query

        find: (query, query_options) ->
          query = @_ensureQuerySubId query
          return self.response_collection.find query, query_options
        
        findOne: (query, query_options) ->
          query = @_ensureQuerySubId query
          return self.response_collection.findOne query, query_options

        stopSubscription: ->
          self.stopAndDeleteSubHandle @req_id
          return
        
        stopStream: ->
          # Stops the stream generation, but won't stop the subscription
          # which means the client can still access the response_collection
          self.stopStream @req_id

          return
        
        logResponseUsage: (choice, choice_data) ->
          self.logResponseUsage @req_id, choice, choice_data
          return
        
        isSubscriptionReady: ->
          return sub_handle.ready()

      return
    return ret
  
  stopStream: (req_id) ->
    # We expect this one to never be called directly
    # Instead, it should be called from the object returned by createStreamRequestAndSubscribeToResponse
    return Meteor.call "stopStream", req_id

  getAIRequestsLog: (options, cb) ->
    return Meteor.call "getAIRequestsLog", options, cb
  
  generateProjectTitle: (msg, cb) ->
    return Meteor.call "generateProjectTitle", msg, cb
  
  generateTaskTitle: (msg, cb) ->
    return Meteor.call "generateTaskTitle", msg, cb

  logResponseUsage: (req_id, choice, choice_data) ->
    return Meteor.call "logResponseUsage", req_id, choice, choice_data
    
  callChatAssistant: (msg, cb) ->
    if not (active_justdo = JD.activeJustdo({title: 1}))?
      return
    
    context = 
      msg: msg
      project_title: active_justdo.title
      tasks: APP.collections.Tasks.find({project_id: active_justdo._id}).fetch()
      project_members: Meteor.users.find().map (user) -> return {_id: user._id, first_name: user.profile.first_name, last_name: user.profile.last_name}
    
    if (gc = APP.modules.project_page.gridControl())? and (state_options = gc.getSchemaExtendedWithCustomFields()?.state?.grid_values)?
      context.state_options = state_options
    
    return Meteor.call "callChatAssistant", context, cb
      