Template.task_channel_chat_bottom_windows_header.onCreated ->
  @task_id = @data.task_id
  @project_id = @data.project_id

  @getTaskDoc = ->
    chat_window_required_fields =
      title: 1
      seqId: 1
    # Try first to get the document from the tasks collection, in case we got it loaded there.
    #
    # Unlikee bottom_windows_supplementary_pseudo_collections.tasks , the tasks collection will
    # get updated while the tasks subscription is running, so it worth while to attempt to obtain
    # first the doc from there.
    #
    # (If the task's JustDo isn't/wasn't loaded before, the task won't be there).
    if (tasks_collection_doc = APP.collections.Tasks.findOne({_id: @task_id}, {fields: chat_window_required_fields}))?
      return tasks_collection_doc

    return APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks.findOne({_id: @task_id}, {fields: chat_window_required_fields})

  return

Template.task_channel_chat_bottom_windows_header.helpers
  title: ->
    tpl = Template.instance()
    if not (task_doc = tpl.getTaskDoc())?
      return ""
    
    {seqId, title} = task_doc

    window_title = "##{seqId}"
    if title?
      window_title += ": #{title}"
    return window_title
  
  titleUrl: ->
    tpl = Template.instance()

    return JustdoHelpers.getTaskUrl(tpl.project_id, tpl.task_id)
  
  titleTooltip: ->
    tpl = Template.instance()
    if not (task_doc = tpl.getTaskDoc())?
      return ""
    
    {seqId, title} = task_doc

    window_title = "##{seqId}"
    if title?
      window_title += ": #{title}"
    return window_title

Template.task_channel_chat_bottom_windows_header.events
  "click .header-title": (e, tpl) ->
    activateTask = =>
      if not (gcm = APP.modules.project_page.getCurrentGcm())?
        console.info "[justdo-chat] Can't activate task, grid is not ready"
        return
      
      gcm.setPath(["main", tpl.task_id], {collection_item_id_mode: true})

      APP.modules.project_page.setCurrentTaskPaneSectionId("details")

      Meteor.defer =>
        $(".task-pane-chat .message-editor").focus()

      return

    if JustdoHelpers.currentPageName() == "project" and Router.current().project_id == tpl.project_id
      activateTask()
    else
      Router.go "project", {_id: tpl.project_id}

      Tracker.flush()

      tracker = Tracker.autorun (c) ->
        project_page_module = APP.modules.project_page

        project = project_page_module.curProj()

        gcm = APP.modules.project_page.getCurrentGcm()

        if gcm?.getAllTabs()?.main?.state == "ready"
          # Wait for main tab to become ready and activate the task
          activateTask()

          c.stop()

          return

        return

    return
