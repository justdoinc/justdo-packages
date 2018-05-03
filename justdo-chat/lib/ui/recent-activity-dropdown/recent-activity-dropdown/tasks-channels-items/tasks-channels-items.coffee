getChannelProject = (project_id) ->
  return APP.collections.Projects.findOne(project_id)

getChannelTask = (task_id) ->
  return APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne(task_id)

Template.recent_activity_item_task.onCreated ->
  @getDropdownInstance = => share.current_recent_activity_dropdown

Template.recent_activity_item_task.helpers
  channel_project: -> getChannelProject(@project_id)

  channel_task: -> getChannelTask(@task_id)

  channel_last_message: -> APP.collections.JDChatRecentActivityMessages.findOne({channel_id: @_id})

  last_message_author: ->
    last_message = APP.collections.JDChatRecentActivityMessages.findOne({channel_id: @_id})

    return APP.collections.JDChatRecentActivityAuthorsDetails.findOne(last_message.author)

  friendlyDateFormat: (date) ->
    return APP.justdo_chat.friendlyDateFormat(date)

getTaskChannelObjectForTaskId = (task_id) ->
  channel_obj = APP.justdo_chat.generateClientChannelObject "task", { # channel conf
    tasks_collection: APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks
    task_id: task_id
  }, { # other options
    custom_channels_collection: APP.collections.JDChatRecentActivityChannels
    custom_messages_collection: APP.collections.JDChatRecentActivityMessages
  }

  return channel_obj

Template.recent_activity_item_task.events
  "click .recent-activity-item-task": (e) ->
    # If the user didn't click on the text under the task-details div, we just open a window
    # for the channel, otherwise, we switch to the channel's task project to activate the
    # channel task on the project grid.

    # We do this outside of activateTask() since it might be called when we don't
    # have template instance set any longer (Meteor.defer)
    if not (dropdown_instance = Template.instance().getDropdownInstance())?
      # We shouldn't get here

      logger.warn "Can't find dropdown instance"

      return

    if $(e.target).closest(".task-details").length == 0
      # Open/highlight the window for the channel.
      channel_obj = getTaskChannelObjectForTaskId(@task_id)

      channel_obj.makeWindowVisible (window_arrangement_def) ->
        $(".message-editor", window_arrangement_def.template_obj.node).focus()

        return

      channel_obj.setChannelUnreadState(false)

      dropdown_instance.closeDropdown()

      return

    activateTask = =>
      gcm = APP.modules.project_page.getCurrentGcm()

      gcm.setPath(["main", @task_id], {collection_item_id_mode: true})

      channel_obj = getTaskChannelObjectForTaskId(@task_id)
      channel_obj.setChannelUnreadState(false)

      dropdown_instance.closeDropdown()

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

      setTimeout ->
        tracker.stop() # after 10 seconds stop the tracker regardless, to avoid lingering trackers in case didn't work well
      , 10000

    return

  "click .read-indicator-block": (e, tpl) ->
    channel_obj = getTaskChannelObjectForTaskId(@task_id)

    channel_obj.toggleChannelUnreadState()

    e.stopPropagation()

    $(e.target).closest(".read-indicator-block").find(".tooltip-content").remove()

    return

