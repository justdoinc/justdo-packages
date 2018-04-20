Template.chat_bottom_windows_task_open.onCreated ->
  @getTaskDoc = (options) =>
    return APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks.findOne({_id: @data.task_id})

  @getProjectDoc = (options) =>
    return APP.collections.Projects.findOne({_id: @data.project_id})

  @task_channel_object = 
    share.generateClientChannelObjectForTaskBottomWindowTemplates(@data.task_id)

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

Template.chat_bottom_windows_task_open.events
  "click .close-chat": ->
    APP.justdo_chat._justdo_chat_bottom_windows_manager.removeWindow "task", {task_id: @task_id}

    return

  "click .header-title": ->
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

        if gcm.getAllTabs()?.main?.state == "ready"
          # Wait for main tab to become ready and activate the task
          activateTask()

          c.stop()

          return

        return

    return

  "click": (e, tpl) ->
    tpl.task_channel_object?.setChannelUnreadState(false)

    return