converter = null

initConverter = _.once -> converter = new showdown.Converter()

default_first_message =
  role: "bot"
  msg_i18n: "ai_wizard_task_summary_default_msg"

Template.tasks_summary.onCreated ->
  initConverter()
  
  tpl = @
  @stream_handler_rv = new ReactiveVar {}
  @messages_rv = new ReactiveVar [default_first_message]
  @is_loading_rv = new ReactiveVar false

  if not @data.gc?
    return

  if _.isEmpty(@task_paths = @data.gc.getFilterPassingMultiSelectedPathsArray())
    @task_paths = [@data.gc.activePath()]
  
  if _.isEmpty @task_paths
    return

  @isResponseExists = ->
    if _.isEmpty(stream_handler = @stream_handler_rv.get())
      return false

    return stream_handler.findOne({"data.parent": -1}, {fields: {_id: 1}})?

  @pushMessage = (msg_obj) ->
    messages = Tracker.nonreactive -> tpl.messages_rv.get()
    messages.push msg_obj
    tpl.messages_rv.set messages

    return

  @scrollToBottom = ->
    $(".ai-wizard-body").animate(scrollTop: $('.ai-wizard-body').prop("scrollHeight"), 100)
    return

  @getSubtreeTaskIdsUntilLimit = (task_id, limit) ->
    task_ids = [task_id]
    parent_task_id_idx = 0

    grid_data = tpl.data.gc._grid_data
    tree_structure = grid_data.tree_structure

    while task_ids.length < limit
      if not (parent_task_id = task_ids[parent_task_id_idx])?
        break

      if (child_task_ids = tree_structure[parent_task_id])?
        task_ids = task_ids.concat _.values child_task_ids

      parent_task_id_idx += 1

    task_ids = task_ids.slice(0, limit)
    return task_ids

  @generateSummary = (msg) ->
    task_ids = _.map @task_paths, (path) -> GridData.helpers.getPathItemId path
    if _.size(task_ids) is 1
      task_ids = tpl.getSubtreeTaskIdsUntilLimit task_ids[0], JustdoAiKit.tasks_summary_tasks_limit

    augmented_fields_sub_handle = APP.projects.subscribeTasksAugmentedFields task_ids, ["description"], {}, =>
      query =
        _id:
          $in: task_ids
      query_options =
        fields:
          title: 1
          seqId: 1
          status: 1
          state: 1
          start_date: 1
          end_date: 1
          due_date: 1
          priority: 1
      tasks = APP.collections.Tasks.find(query, query_options).map (task_doc) ->
        if (description = APP.collections.TasksAugmentedFields.findOne({_id: task_doc._id}, {fields: {description: 1}})?.description)?
          task_doc.description = description
        return task_doc

      tpl.is_loading_rv.set true
      tpl.pushMessage
        role: "user"
        msg: msg
      tpl.$(".ai-wizard-input").val ""

      if not _.isEmpty(old_stream_handler = tpl.stream_handler_rv.get())
        old_stream_handler.stopSubscription()

      options =
        template_id: "stream_tasks_summary"
        template_data:
          msg: msg
          tasks: tasks
        subOnReady: -> tpl.is_loading_rv.set false
        subOnStop: (err) ->
          if err?
            JustdoSnackbar.show
              text: TAPi18n.__ "stream_response_generic_err"
            tpl.is_loading_rv.set false
          return
      stream_handler = APP.justdo_ai_kit.createStreamRequestAndSubscribeToResponse options
      
      tpl.pushMessage
        role: "bot"
        stream_handler: stream_handler
      tpl.stream_handler_rv.set stream_handler
      
      augmented_fields_sub_handle.stop()

      return

    return

  return

Template.tasks_summary.onRendered ->
  # Disable input if loading, vice-versa.
  @autorun =>
    if @is_loading_rv.get()
      @$(".ai-wizard-input").prop "disabled", true
    else
      @$(".ai-wizard-input").prop "disabled", false
      @$(".ai-wizard-input").focus()
    return

  return

Template.tasks_summary.helpers
  messages: ->
    tpl = Template.instance()
    tpl.scrollToBottom()

    return tpl.messages_rv.get()

  isLoading: ->
    tpl = Template.instance()
    return tpl.is_loading_rv.get()
  
  ucFirst: (str) -> JustdoHelpers.ucFirst str

Template.tasks_summary.events
  "click .ai-wizard-send": (e, tpl) ->
    if _.isEmpty(msg = tpl.$(".ai-wizard-input").val())
      return

    tpl.generateSummary msg

    return

  "click .ai-wizard-stop": (e, tpl) ->
    if not (stream_handler = tpl.stream_handler_rv.get())?
      return

    stream_handler.stopStream()
    return

  "keydown .ai-wizard-input": (e, tpl) ->
    if e.keyCode is 13
      tpl.$(".ai-wizard-send").click()

    return

  "click .ai-wizard-close": (e, tpl) ->
    bootbox.hideAll()

    return

Template.bot_message_card.onCreated ->
  tpl = @

  @msg_obj = @data
  @msg_dep = new Tracker.Dependency()

  @scrollToBottom = Blaze.getView("Template.tasks_summary").templateInstance().scrollToBottom

  @joinAndFormatMessages = ->
    msg = tpl.msg_obj.stream_handler.find({}, {sort: {seqId: 1}})
      .map (res) -> res.data
      .join("")
    msg = converter.makeHtml msg
    msg = APP.justdo_chat.linkTaskId msg
    return JustdoHelpers.xssGuard msg, {allow_html_parsing: true, enclosing_char: ""}

  @autorun (computation) =>
    if not @msg_obj.stream_handler?.isSubscriptionReady()
      return

    msg = tpl.joinAndFormatMessages()
    tpl.msg_obj.msg = msg

    tpl.msg_dep.changed()
    tpl.scrollToBottom()
    computation.stop()

    return

  return

Template.bot_message_card.helpers
  isLoading: ->
    tpl = Template.instance()
    tpl.msg_dep.depend()
    msg_obj = tpl.msg_obj
    if not (stream_handler = msg_obj?.stream_handler)?
      return false
    return (not msg_obj.msg?) and (not stream_handler.findOne({}, {_id: 1})?)

  msg: ->
    tpl = Template.instance()
    tpl.msg_dep.depend()
    return tpl.msg_obj.msg

  streamMsg: ->
    tpl = Template.instance()
    if not (stream_handler = tpl.msg_obj?.stream_handler)?
      return

    return tpl.joinAndFormatMessages()

Template.bot_message_card.events
  "click .copy": (e, tpl) ->
    target_element = tpl.$(".ai-wizard-text-content").get(0)

    clipboard.copy
      "text/plain": target_element.innerText.trim()
      "text/html": target_element.innerHTML.trim()

    JustdoSnackbar.show
      text: TAPi18n.__ "ai_kit_chatbox_dropdown_copied_msg"

    return

  "click .task-link": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    seq_id = parseInt($(e.target).closest(".task-link").text().trim().substr(1), 10)
    project_id = JD.activeJustdo({_id: 1})?._id
    task_id = APP.collections.Tasks.findOne({project_id: project_id, seqId: seq_id}, {fields: {_id: 1}})?._id

    APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)

    return
