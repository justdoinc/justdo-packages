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

  @show_send_button_rv = new ReactiveVar false
  @showSendButton = ->
    @show_send_button_rv.set true
    return
  @hideSendButton = ->
    @show_send_button_rv.set false
    return

  @getInputElement = -> @$("textarea")
  @getInputValue = -> @getInputElement().val()
  @getTrimmedInputValue = -> @getInputValue().trim()
  @setInputValue = (value) -> 
    @getInputElement().val(value)
    @getInputElement().trigger("autosize.resize")
    return

  @sendMessage = (e) ->
    if @isSendingState()
      @data.getChannelObject().logger.log("Sending in progress...")
      return

    $input = @getInputElement()
    input_val = @getTrimmedInputValue()

    if _.isEmpty(input_val)
      return

    @clearError()

    task_chat_object = @data.getChannelObject()

    @setSendingState()
    @hideSendButton()

    task_chat_object.sendMessage input_val, (err) =>
      @unsetSendingState()

      if err?
        @setError(err.reason)
        @showSendButton()
        return

      @setInputValue("")
      task_chat_object.clearTempMessage()

      Meteor.defer ->
        $input.focus()

      return

    return

  return

Template.common_chat_message_editor.onRendered ->
  @autorun =>
    channel = @data.getChannelObject()

    $message_editor = $(this.firstNode).parent().find(".message-editor")
    if _.isEmpty(stored_temp_message = channel.getTempMessage())
      @setInputValue("")
    else
      @setInputValue(stored_temp_message)

      Tracker.nonreactive ->
        # We don't want potential reactive resources called by handlers of the keyup to trigger invalidation of
        # this autorun (it actually happened, Daniel C.)
        $message_editor.keyup() # To trigger stuff like the proposed subscribers emulation mode (see "keyup .message-editor" event in chat-section.coffee)

    return

  # Hide the send button when switching between tasks
  @autorun =>
    JD.activeItemId() # For reactivity
    
    # Wrap the following in a Meteor.defer to allow UI refresh before checking if the input is empty
    Meteor.defer =>
      if _.isEmpty @getTrimmedInputValue()
        @hideSendButton()
    
    return

  $(this.firstNode).focus =>
    @data.getChannelObject().enterFocusMode()

    return

  if ($window_container = $(this.firstNode).closest(".window-container")).length == 0
    # Isn't rendered inside a window, take care of exiting focus mode
    # when focus out.
    #
    # For windows, we are counting on the task-opne.html mouseup/down handlers
    # to take care of bluring (as the concept of bluring out of the window
    # is more complex in that case).

    $(this.firstNode).blur (e) =>
      @data.getChannelObject().exitFocusMode()

      return

    return

  return

Template.common_chat_message_editor.helpers
  isSendingState: ->
    tpl = Template.instance()

    return tpl.isSendingState()

  error: ->
    tpl = Template.instance()

    return tpl.getError()
  
  showSendButton: ->
    tpl = Template.instance()

    return tpl.show_send_button_rv.get()

Template.common_chat_message_editor.events
  "keyup .message-editor": (e, tpl) ->
    @getChannelObject().saveTempMessage tpl.getInputValue()

    if tpl.getTrimmedInputValue()
      tpl.showSendButton()
    else
      tpl.hideSendButton()

    return

  "keydown .message-editor": (e, tpl) ->
    $input = tpl.getInputElement()
    if e.which == 13
      # Don't add a new line
      e.preventDefault()

      if (e.altKey or e.ctrlKey or e.shiftKey)
        current_pos = $input.prop("selectionStart")
        tpl.setInputValue(JustdoHelpers.splice(tpl.getInputValue(), current_pos, 0, "\n"))
        $input.prop("selectionStart", current_pos + 1)

        return

      tpl.sendMessage(e)

    return

  "click .message-editor-send": (e, tpl) ->
    tpl.sendMessage(e)
    return


Template.common_chat_message_editor.onRendered ->
  $textarea = @getInputElement()

  $textarea.keydown =>
    # The following fixes an issue we got that when the max height of the textarea
    # is reached, the viewport doesn't focus the caret when additional lines are added
    textarea = $textarea.get(0)

    if @getInputValue().length == textarea.selectionStart
      Meteor.defer ->
        textarea.scrollTop = textarea.scrollHeight

        return

    return

  $textarea.autosize
    callback: =>
      Meteor.defer =>
        $chat_window = @$(@firstNode).closest(".chat-window")
        $chat_header = $chat_window.find(".chat-header")
        $message_editor = @getInputElement()
        $message_board_viewport = $chat_window.find(".messages-board-viewport")

        new_message_board_viewport_height =
          $chat_window.outerHeight() - $chat_header.outerHeight() - $message_editor.outerHeight()

        $message_board_viewport.height(new_message_board_viewport_height)

        return

      return

  return
