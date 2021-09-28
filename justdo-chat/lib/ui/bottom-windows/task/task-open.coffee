chat_window_required_fields =
  title: 1
  seqId: 1

Template.chat_bottom_windows_task_open.onCreated ->
  @getTaskDoc = (options) =>
    # Try first to get the document from the tasks collection, in case we got it loaded there.
    #
    # Unlikee bottom_windows_supplementary_pseudo_collections.tasks , the tasks collection will
    # get updated while the tasks subscription is running, so it worth while to attempt to obtain
    # first the doc from there.
    #
    # (If the task's JustDo isn't/wasn't loaded before, the task won't be there).
    if (tasks_collection_doc = APP.collections.Tasks.findOne({_id: @data.task_id}, {fields: chat_window_required_fields}))?
      return tasks_collection_doc

    return APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks.findOne({_id: @data.task_id}, {fields: chat_window_required_fields})

  @getProjectDoc = (options) =>
    return APP.collections.Projects.findOne({_id: @data.project_id})

  @task_channel_object = 
    share.generateClientChannelObjectForTaskBottomWindowTemplates(@data.task_id)

  return

Template.chat_bottom_windows_task_open.onRendered ->
  $window_container = $(this.firstNode).closest(".window-container")

  $(this.firstNode).mousedown =>
    @task_channel_object.enterFocusMode()

    return

  @blurCb = (e) =>
    if $(e.target).closest(".window-container").get(0) != $window_container.get(0)
      @task_channel_object.exitFocusMode()

    return

  # We don't want mouseup/down on chat to trigger window activation
  @$(".close-chat")
    .mouseup (e) ->
      e.stopPropagation()

      return

    .mousedown (e) ->
      e.stopPropagation()

      return

  # The best user experience is with mousedown, but we can't trust mousedown to always
  # bubble up, hence, we have to bind to mouseup as well.
  $(document).mousedown @blurCb
  $(document).mouseup @blurCb

  return

Template.chat_bottom_windows_task_open.onDestroyed ->
  $(document).off("mousedown", @blurCb)
  $(document).off("mouseup", @blurCb)

  @task_channel_object.destroy()

  return

Template.chat_bottom_windows_task_open.helpers
  getTaskChatObject: ->
    tpl = Template.instance()

    return => tpl.task_channel_object # Note! We return a function that returns the object, as required by the common components templates

  getMessagesAuthorsCollection: ->
    return APP.collections.JDChatChannelMessagesAuthorsDetails

  getTask: ->
    tpl = Template.instance()

    return tpl.getTaskDoc()

  isFocused: ->
    tpl = Template.instance()

    return tpl.task_channel_object.isFocused()

  hasUnreadMessages: ->
    tpl = Template.instance()

    return tpl.task_channel_object.getChannelSubscriberDoc(Meteor.userId())?.unread

  taskURL: ->
    return JustdoHelpers.getTaskUrl(@project_id, @task_id)

Template.chat_bottom_windows_task_open.events
  "click .close-chat": ->
    APP.justdo_chat._justdo_chat_bottom_windows_manager.removeWindow "task", {task_id: @task_id}

    return
    
  "click .minimize-chat": ->
    APP.justdo_chat._justdo_chat_bottom_windows_manager.minimizeWindow "task", {task_id: @task_id}

    return

  "click .header-title": (e) ->
    e.preventDefault()

    activateTask = =>
      gcm = APP.modules.project_page.getCurrentGcm()

      gcm.setPath(["main", @task_id], {collection_item_id_mode: true})

      APP.modules.project_page.setCurrentTaskPaneSectionId("details")

      Meteor.defer =>
        $(".task-pane-chat .message-editor").focus()

      return

    if JustdoHelpers.currentPageName() == "project" and Router.current().project_id == @project_id
      activateTask()
    else
      Router.go "project", {_id: @project_id}

      Tracker.flush()

      tracker = Tracker.autorun (c) ->
        module = APP.modules.project_page

        project = module.curProj()

        gcm = APP.modules.project_page.getCurrentGcm()

        if gcm?.getAllTabs()?.main?.state == "ready"
          # Wait for main tab to become ready and activate the task
          activateTask()

          c.stop()

          return

        return

    return

  "click": (e, tpl) ->
    tpl.task_channel_object?.setChannelUnreadState(false)

    return