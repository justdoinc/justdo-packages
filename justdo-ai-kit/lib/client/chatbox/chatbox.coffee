chatbox_dropdown = null

Template.ai_kit_chatbox_dropdown_btn.onCreated ->
  AiKitChatboxDropdownConstructor = JustdoHelpers.generateNewTemplateDropdown "ai-kit-chatbox", "ai_kit_dropdown_chatbox",
    custom_bound_element_options:
      close_button_html: null

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "right top"
          at: "right bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg"
            element.element.css
              top: new_position.top - 11
              left: new_position.left
            return
        $(".dropdown-menu.show").removeClass("show")
  
  chatbox_dropdown = new AiKitChatboxDropdownConstructor()
  return

Template.ai_kit_chatbox_dropdown_btn.events
  "click #ai-kit-chatbox-dropdown-button": (e, tpl) ->
    e.stopPropagation()
    chatbox_dropdown.$connected_element = $(e.currentTarget)
    chatbox_dropdown.openDropdown()
    return

show_bot_response_thinking = new ReactiveVar false
is_input_locked_rv = new ReactiveVar false
# TODO: Message type registerar; Support sendMessageCb passed as template data.
Template.ai_kit_dropdown_chatbox.onCreated ->
  tpl = @
  @messages_rv = APP.justdo_ai_kit.chatbox_dropdown_messages_rv

  @sendMessage = ->
    message = $(".ai-wizard-input").val().trim()
    existing_messages = tpl.messages_rv.get()

    if not _.isEmpty message
      is_input_locked_rv.set true

      existing_messages.push 
        role: "user"
        msg: message
      tpl.messages_rv.set existing_messages

      setTimeout ->
        show_bot_response_thinking.set true
      , 500

      APP.justdo_ai_kit.callChatAssistant message, (err, res) ->
        existing_messages = tpl.messages_rv.get()
        is_input_locked_rv.set false
        show_bot_response_thinking.set false
        
        if err?
          console.error err
          # existing_messages.push 
          #   role: "bot"
          #   msg_i18n: "ai_kit_chatbox_dropdown_error_msg"
          existing_messages.push 
            role: "bot"
            msg: "Oops, an error occurred. Please try again."

          tpl.messages_rv.set existing_messages
          return
        
        res = EJSON.parse res
        msg = res.msg
        query = res.q
        if not _.isEmpty query
          if _.isString query
            query = EJSON.parse query
          query_options = res.o
          if _.isString query_options
            query_options = query_options.trim()
            if query_options[0] isnt "{"
              query_options = "{#{query_options}}"
            query_options = EJSON.parse query_options

          if not query.project_id?
            query.project_id = JD.activeJustdoId()
          task_strings = APP.collections.Tasks.find(query, query_options).map (task) -> 
            ret = "<span>##{task.seqId}"
            if not _.isEmpty task.title
              ret += " - #{task.title}"
            ret += "</span>"
            return ret

          task_strings = task_strings.join ""
          
          if msg.includes "__tasks__"
            msg = msg.replace "__tasks__", task_strings
          else
            msg += "\n\n#{task_strings}"
          
          msg = JustdoHelpers.nl2br msg
          msg = APP.justdo_chat.linkTaskId msg

        existing_messages.push 
          role: "bot"
          msg: msg
        tpl.messages_rv.set existing_messages

        return

      # setTimeout ->
      #   existing_messages.push 
      #     role: "bot"
      #     msg_i18n: "ai_kit_chatbox_dropdown_loading_msg"
      #   tpl.messages_rv.set existing_messages
      # , 2000

    $(".ai-wizard-input").val ""

    return
  return

Template.ai_kit_dropdown_chatbox.onRendered ->
  $(".ai-wizard-input").focus()
  $(".ai-wizard-body").scrollTop $(".ai-wizard-body")[0].scrollHeight

  return

Template.ai_kit_dropdown_chatbox.helpers
  dropdownChatboxMessages: ->
    tpl = Template.instance()
    return tpl.messages_rv.get()

  showBotThinking: ->
    return show_bot_response_thinking.get()
  
  isInputLocked: ->
    return is_input_locked_rv.get()

Template.ai_kit_dropdown_chatbox.events
  "click .ai-wizard-close": (e, tpl) ->
    chatbox_dropdown.closeDropdown()

    return

  "click .ai-wizard-send": (e, tpl) ->
    tpl.sendMessage()

    return

  "keypress .ai-wizard-input": (e, tpl) ->
    if e.keyCode == 13
      tpl.sendMessage()

    return

  "click .task-link": (e, tmpl) ->
    e.preventDefault()

    seq_id = parseInt($(e.target).closest(".task-link").text().trim().substr(1), 10)

    project_id = JD.activeJustdo({_id: 1})?._id

    task_id = APP.collections.Tasks.findOne({project_id: project_id, seqId: seq_id}, {fields: {_id: 1}})?._id

    if task_id?
      APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)
    else
      APP.modules.project_page.activateTaskInProject(project_id, task_id)
