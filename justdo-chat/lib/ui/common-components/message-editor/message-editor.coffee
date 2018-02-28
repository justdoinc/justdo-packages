# The common chat messages editor expect to have in its data context
# a getChannelObject() method that returns an object that has the
# following methods:
#
# * getChannelObject().logger -> the common logger object in use in JustDo
# * getChannelObject().sendMessage(message_body) -> will be called with the message body as its first param

Template.common_chat_message_editor.onCreated ->
  @_sendingState = new ReactiveVar false
  @setSendingState = -> @_sendingState.set true
  @unsetSendingState = -> @_sendingState.set false
  @isSendingState = -> @_sendingState.get()

  @_error = new ReactiveVar(null)
  @setError = (error_message) -> @_error.set(error_message)
  @clearError = -> @setError(null)
  @getError = -> @_error.get()

Template.common_chat_message_editor.onRendered ->
  @autorun =>
    channel = @data.getChannelObject()

    $message_editor = $(this.firstNode).parent().find(".message-editor")
    if _.isEmpty(stored_temp_message = channel.getTempMessage())
      $message_editor.val("")
    else
      $message_editor.val(stored_temp_message)

      Tracker.nonreactive ->
        # We don't want potential reactive resources called by handlers of the keyup to trigger invalidation of
        # this autorun (it actually happened, Daniel C.)
        $message_editor.keyup() # To trigger stuff like the proposed subscribers emulation mode (see "keyup .message-editor" event in chat-section.coffee)

    return

  return

Template.common_chat_message_editor.helpers
  isSendingState: ->
    tpl = Template.instance()

    return tpl.isSendingState()

  error: ->
    tpl = Template.instance()

    return tpl.getError()

Template.common_chat_message_editor.events
  "keyup .message-editor": (e, tpl) ->
    @getChannelObject().saveTempMessage $(e.target).val().trim()

    return

  "keydown .message-editor": (e, tpl) ->
    $input = $(e.target)
    if e.which == 13
      # Don't add a new line
      e.preventDefault()

      if (e.altKey or e.ctrlKey or e.shiftKey)
        current_pos = $input.prop("selectionStart")

        $input.val(JustdoHelpers.splice($input.val(), current_pos, 0, "\n"))

        $input.prop("selectionStart", current_pos + 1)

        $input.trigger("autosize.resize")

        return

      if tpl.isSendingState()
        @getChannelObject().logger.log("Sending in progress...")

        return

      # When user press enter without alt/ctrl key pressed , when we aren't already in
      # sending state
      tpl.clearError()

      input_val = $input.val().trim()
        
      if _.isEmpty(input_val)
        # Empty input ...
        return

      task_chat_object = @getChannelObject()

      tpl.setSendingState()
      task_chat_object.sendMessage input_val, (err) ->
        tpl.unsetSendingState()

        if err?
          tpl.setError(err.reason)

          return

        $input.val("")
        task_chat_object.clearTempMessage()

        $input.trigger("autosize.resize")

        Meteor.defer ->
          $input.focus()

        return

    return

Template.common_chat_message_editor.onRendered ->
  $textarea = @$("textarea")

  $textarea.autosize()

  return
