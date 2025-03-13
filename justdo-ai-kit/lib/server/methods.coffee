_.extend JustdoAiKit.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods 
      "stopStream": (req_id) ->
        check req_id, String
        self.emit "stop_stream_#{req_id}"
        return
      
      "getAIRequestsLog": (options) ->
        check @userId, String

        # security check is done in getAIRequestsLog

        return self.getAIRequestsLog options, @userId

      "generateProjectTitle": (msg) ->
        check msg, String
        check @userId, String
        return self.generateProjectTitle msg, @userId
      
      "generateTaskTitle": (msg) ->
        check msg, String
        check @userId, String
        return self.generateTaskTitle msg, @userId
      
      "logResponseUsage": (req_id, choice, choice_data) ->
        check req_id, String
        check choice, String

        return self.logResponseUsage req_id, choice, choice_data, @userId
      
      "callChatAssistant": (context) ->
        check @userId, String
        context.user_id = @userId
        context.timestamp = new Date().valueOf()
        return self.callChatAssistant context, @userId

    return