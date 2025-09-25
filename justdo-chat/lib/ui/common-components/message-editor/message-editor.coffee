# The common chat messages editor expect to have in its data context
# a getChannelObject() method that returns an object that has the
# following methods:
#
# * getChannelObject().logger -> the common logger object in use in JustDo
# * getChannelObject().sendMessage(message_body) -> will be called with the message body as its first param

Template.common_chat_message_editor.onCreated ->
  tpl = @

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
  @showOrHideSendButtonBasedOnUserInput = ->
    if @getTrimmedInputValue() or @getFilesCount() > 0
      @showSendButton()
    else
      @hideSendButton()
    return
  
  @getInputElement = -> @$("textarea")
  @getInputValue = -> @getInputElement().val()
  @getTrimmedInputValue = -> @getInputValue()?.trim()
  @setInputValue = (value) -> 
    @getInputElement().val(value)
    @getInputElement().trigger("autosize.resize")
    return
  
  @getFileInputElement = -> @$(".message-editor-file-input")
  @attached_files = []
  @attached_files_dep = new Tracker.Dependency()
  @getFileKey = (file) -> "#{file.name}:#{file.size}:#{file.lastModified}"
  @attachFiles = (files) ->
    # Note: this method accept `files` as `FileList` object from the input element, not an Array.
    @clearError()

    file_size_limit = APP.justdo_file_interface.getFileSizeLimit()
    files_not_exceeding_size_limit = _.filter files, (file) -> file.size <= file_size_limit
    files_exceeding_size_limit = _.filter files, (file) -> file.size > file_size_limit

    # Filter out files that exceeds size limit and set error to notify user
    if not _.isEmpty files_exceeding_size_limit
      human_readable_size_limit = JustdoHelpers.bytesToHumanReadable file_size_limit
      name_of_files_exceeding_size_limit = _.map(files_exceeding_size_limit, (file) -> "<li>#{file.name} (#{JustdoHelpers.bytesToHumanReadable file.size})</li>").join("")
      # Add a new line to the beginning of the string to make it more readable
      name_of_files_exceeding_size_limit = "\n" + "<ul>#{name_of_files_exceeding_size_limit}</ul>"
      @setError TAPi18n.__("chat_files_exceeds_size_limit_error", {limit: human_readable_size_limit, files: name_of_files_exceeding_size_limit, count: files_exceeding_size_limit.length})

    files_not_exceeding_size_limit = _.map files_not_exceeding_size_limit, (file) =>
      # The key to identify the file uniquely to avoid duplicates.
      file_key = @getFileKey file
      file._id = file_key
      return file
    
    @addFiles files_not_exceeding_size_limit

    return
  @addFiles = (files) ->
    @attached_files = @attached_files.concat files
    @attached_files = _.uniq @attached_files, false, "_id"
    @attached_files_dep.changed()
  @sortFilesByArrayOrder = (file_ids) ->
    @attached_files = _.sortBy @attached_files, (file) =>
      file_ids.indexOf file._id
    @attached_files_dep.changed()
    return
  @getFilesArray = ->
    @attached_files_dep.depend()
    return @attached_files
  @removeFilesByKey = (file_keys) ->
    if _.isString file_keys
      file_keys = [file_keys]

    @attached_files = _.filter @attached_files, (file) => file._id not in file_keys
        
    @attached_files_dep.changed()
    
    return
  @clearFiles = ->
    @attached_files = []
    # Clear the file input element
    @getFileInputElement().val("")
    @attached_files_dep.changed()
    
    return
  @getFilesCount = -> 
    @attached_files_dep.depend()
    return _.size @attached_files

  # Since the bound element of the dropdown has animation that rotates the element upon hovering,
  # `is_files_dropdown_open` is introduced to prevent flickering caused by rapidly opening/closing of the dropdown
  #  when the cursor is at the edge of the bound element
  @is_files_dropdown_open = false
  FilesDropdown = JustdoHelpers.generateNewTemplateDropdown "chat-editor-files-dropdown", "common_chat_message_editor_files_dropdown",
    custom_bound_element_options:
      close_button_html: null
      close_on_bound_elements_show: false
      openedHandler: ->
        tpl.is_files_dropdown_open = true
        $(tpl.files_dropdown.current_dropdown_node.node).sortable
          handle: ".sort-handle"
          items: ".dropdown-item"
          axis: "y"
          appendTo: document.body
          dropOnEmpty: false
          tolerance: "pointer"
          update: (e, ui) ->
            updated_file_order = $(@).sortable("toArray", {attribute: "data-file-key"})
            tpl.sortFilesByArrayOrder updated_file_order
            return

        return
      closedHandler: =>
        @is_files_dropdown_open = false
        return

    updateDropdownPosition: ($connected_element, is_called_upon_open=true) ->
      @$dropdown
        .position
          of: $connected_element
          my: "left top"
          at: "right bottom"
          collision: "flipfit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg"

            new_top = new_position.top
            new_left = new_position.left

            if is_called_upon_open
              # The `slideIn` animation increases the top by 1rem,
              # so we need to subtract it to keep the dropdown in the same position.
              # This only happens when the dropdown is opened upon mouse enter, and not subsquent calls.
              new_top -= parseInt(getComputedStyle(document.documentElement).fontSize)

            element.element.css
              top: new_top
              left: new_left
            return

  @files_dropdown = new FilesDropdown()
  @showFilesDropdown = (e) ->
    @files_dropdown.$connected_element = $(e.currentTarget)
    @files_dropdown.template_data = {parent_tpl: @}
    @files_dropdown.openDropdown()
    return
  @hideFilesDropdown = ->
    @files_dropdown.closeDropdown()
    return
  @autorun =>
    @attached_files_dep.depend()
    if not @is_files_dropdown_open
      return

    Meteor.defer =>
      @files_dropdown.updateDropdownPosition @files_dropdown.$connected_element, false
      $(@files_dropdown.current_dropdown_node.node).sortable "refresh"
      return

    return

  @is_dragging_files_into_drop_pane = new ReactiveVar false

  @sendMessage = (e) ->
    if @isSendingState()
      @data.getChannelObject().logger.log("Sending in progress...")
      return

    $input = @getInputElement()
    input_val = @getTrimmedInputValue()
    files = @getFilesArray()

    if _.isEmpty(input_val) and _.isEmpty(files)
      return

    @clearError()

    task_chat_object = @data.getChannelObject()

    @setSendingState()
    @hideSendButton()

    callSendMessageMethod = (input_val, files) =>
      data = 
        body: input_val

      if not _.isEmpty(files)
        data.files = files

      task_chat_object.sendMessage data, (err) =>
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

    # File handling
    if not _.isEmpty(files = @getFilesArray())
      task_id = task_chat_object.getChannelIdentifier().task_id
      uploaded_files = []

      # Since file preview modal shows the most recent file first, we need to upload the files in reverse order
      # to match the order of the files in the dropdown by using `file_to_upload_index`.
      # If this order is updated, please also update the order below searching by the key "FILE_ORDER_IN_MESSAGE"
      file_to_upload_index = _.size(files) - 1
      uploadNextFile = ->
        if _.isEmpty(files)
          return
        
        file = files[file_to_upload_index]
        file_to_upload_index -= 1
        APP.justdo_file_interface.uploadTaskFile task_id, file, uploadFileCb
        return

      # Note: This callback is used to handle the upload of a single file
      uploadFileCb = (err, file_details) =>
        if err?
          @setError(err.reason or err)
          @showSendButton()
          return
        else 
          # Typically, after uploaded a file, `jd_file_id_obj` should be stored for identifying the file in the future
          # since it's considered the primary key of the file.
          # However, in the context of justdo-chat, we can derive the `bucket_id` and `folder_name`
          # from the channel type and channel identifier, so we don't need to store it.
          # In addition, since we want to keep a record of what file got attached to a message
          # even after the deletion of such file, we store `additional_details` which includes the file name and size
          # and extend it with the `fs_id` to identify the file system.
          # With file_id, fs_id, channel type and channel identifier, we can identify the file uniquely.
          jd_file_id_obj = file_details[0]
          additional_details = file_details[1]
          # _id exists in `jd_file_id_obj` as `file_id` already, no need to store it again
          additional_details = _.omit additional_details, "_id"

          file_meta_to_store = {jd_file_id_obj, additional_details}

          uploaded_files.push file_meta_to_store

        all_files_uploaded = uploaded_files.length is files.length
        if all_files_uploaded
          # Clear the file input
          @clearFiles()
          # FILE_ORDER_IN_MESSAGE
          uploaded_files = uploaded_files.reverse()
          callSendMessageMethod input_val, uploaded_files
        else
          uploadNextFile()
        
        return
      
      uploadNextFile()
    else
      callSendMessageMethod input_val

    return

  return

Template.common_chat_message_editor.onRendered ->
  @autorun =>
    channel = @data.getChannelObject()

    $message_editor = $(this.firstNode).parent().find(".message-editor")

    @clearError()
    @clearFiles()

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

  @dragEnterHandler = (e) =>
    # Setup a event handler on the parent element to handle the dragenter event
    # so that when a file is dragged into the chat window (instead of only the editor element),
    # the .drop-pane element will be activated to handle file drop event.
    e.stopPropagation()
    e.preventDefault()
    @is_dragging_files_into_drop_pane.set true
    return false
  @$(".message-editor-wrapper").parent().on "dragenter", @dragEnterHandler

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

    return JustdoHelpers.nl2br tpl.getError()
  
  showSendButton: ->
    tpl = Template.instance()

    return tpl.show_send_button_rv.get()
  
  isSendButtonDisabled: ->
    tpl = Template.instance()

    if not tpl.show_send_button_rv.get()
      return "disabled"

    return ""
  
  isFilesEnabled: ->
    tpl = Template.instance()
    if not (channel_obj = tpl.data.getChannelObject())?
      return false

    is_files_enabled = APP.justdo_chat.isFilesEnabled channel_obj.channel_type
    if not is_files_enabled
      return false
    
    is_user_allowed_to_upload = APP.justdo_file_interface.isUserAllowedToUploadTaskFile channel_obj.getChannelIdentifier().task_id, Meteor.userId()

    return is_files_enabled and is_user_allowed_to_upload
    
  filesCount: ->
    tpl = Template.instance()
    return tpl.getFilesCount()
  
  isDraggingFilesIntoDropPane: ->
    tpl = Template.instance()
    return tpl.is_dragging_files_into_drop_pane.get()

Template.common_chat_message_editor.events
  "keyup .message-editor": (e, tpl) ->
    @getChannelObject().saveTempMessage tpl.getInputValue()

    tpl.showOrHideSendButtonBasedOnUserInput()

    return

  "keydown .message-editor": (e, tpl) ->
    $input = tpl.getInputElement()
    if e.which == 13
      # Don't add a new line
      e.preventDefault()

      if (e.altKey or e.ctrlKey or e.shiftKey)
        current_pos = $input.prop("selectionStart")
        tpl.setInputValue(JustdoHelpers.splice(tpl.getInputValue(), current_pos, 0, "\n"))
        new_pos = current_pos + 1
        $input.prop("selectionStart", new_pos)
        $input.prop("selectionEnd", new_pos)

        return

      tpl.sendMessage(e)

    return

  "click .message-editor-send": (e, tpl) ->
    tpl.sendMessage(e)
    return

  "click .attach-files, click .files-count": (e, tpl) ->
    e.preventDefault()
    tpl.getFileInputElement().click()
    return

  "change .message-editor-file-input": (e, tpl) ->
    tpl.attachFiles(e.target.files)

    tpl.showOrHideSendButtonBasedOnUserInput()
    return
  
  "dragleave .drop-pane": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    tpl.is_dragging_files_into_drop_pane.set false
    return false

  "dragover .drop-pane": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    e.originalEvent.dataTransfer.dropEffect = "copy"
    return false
  
  "drop .drop-pane": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    tpl.is_dragging_files_into_drop_pane.set false

    tpl.attachFiles(e.originalEvent.dataTransfer.files)
    tpl.showOrHideSendButtonBasedOnUserInput()

    return false

  "mouseenter .files-wrapper": (e, tpl) ->
    # Only show dropdown if there are files attached
    if not tpl.is_files_dropdown_open and tpl.getFilesCount() > 0
      tpl.showFilesDropdown(e)
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

Template.common_chat_message_editor.onDestroyed ->
  @$(".message-editor-wrapper").parent().off "dragenter", @dragEnterHandler
  @files_dropdown.destroy()

  return

Template.common_chat_message_editor_files_dropdown.helpers
  attachedFiles: ->
    tpl = Template.instance()
    return tpl.data.parent_tpl.getFilesArray()

  bytesToHumanReadable: (bytes) ->
    tpl = Template.instance()
    return JustdoHelpers.bytesToHumanReadable bytes
  
Template.common_chat_message_editor_files_dropdown.events
  "mousedown .remove-file": (e, tpl) ->
    # To prevent multiple clicks to trigger text selection
    e.preventDefault()
    e.stopPropagation()
    return false
  
  "click .remove-file": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()
    
    file_key = $(e.target).closest(".dropdown-item").data("file-key")
    tpl.data.parent_tpl.removeFilesByKey file_key
    
    return false