getChannelProject = (project_id) ->
  return APP.collections.Projects.findOne(project_id, {fields: {title: 1}})

getChannelTask = (task_id) ->
  return APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne(task_id)

Template.recent_activity_item_task.onCreated ->
  @getDropdownInstance = => share.current_recent_activity_dropdown

Template.recent_activity_item_task.helpers
  channelProject: -> getChannelProject(@project_id)

  channel_task: -> getChannelTask(@task_id)

  channel_last_message: -> APP.collections.JDChatRecentActivityMessages.findOne({channel_id: @_id})

  body: ->
    if @data?
      body = APP.justdo_chat.renderDataMessage(@data, @author)
    else
      body = @body

    return body

  last_message_author: ->
    last_message = APP.collections.JDChatRecentActivityMessages.findOne({channel_id: @_id})

    if not (author_id = last_message?.author)?
      return null

    if APP.justdo_chat.isBotUserId author_id
      return APP.collections.JDChatBotsInfo.findOne(author_id)

    return APP.collections.JDChatRecentActivityAuthorsDetails.findOne(author_id)

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
        window_arrangement_def.window_def.channel_object.enterFocusMode()

        # This is a workaround
        # we want the window to appear as active immediately as the user see it.
        $(".open-chat-window", window_arrangement_def.template_obj.node).addClass("window-active")

        Meteor.defer ->
          # Reason to use Meteor.defer:
          #
          # If we call .focus() on the same tick, $.focus() procedures defined on its
          # onRendered() aren't called already (not sure why onRendered isn't called
          # in a point where we can already .focus() it. Daniel C.).
          $(".message-editor", window_arrangement_def.template_obj.node).focus()

          # Now, we should have to window-active, one from the hack above,
          # and one from the .enterFocusMode called by the focus handler of
          # the message-editor. The 2nd one is in the blaze level.

          # To avoid messing things up, we remove both of them, and bring back
          # only one. Now the DOM is inline with Blaze's expectation of it.
          $(".open-chat-window", window_arrangement_def.template_obj.node).removeClass("window-active")
          $(".open-chat-window", window_arrangement_def.template_obj.node).addClass("window-active")

          return

        return

        Meteor.defer ->
          $(".message-editor", window_arrangement_def.template_obj.node).focus()

          return

        return

      channel_obj.setChannelUnreadState(false)

      dropdown_instance.closeDropdown()

      return


    APP.modules.project_page.activateTaskInProject @project_id, @task_id, =>
      channel_obj = getTaskChannelObjectForTaskId(@task_id)
      channel_obj.setChannelUnreadState(false)

      dropdown_instance.closeDropdown()

      APP.modules.project_page.setCurrentTaskPaneSectionId("details")

      Meteor.defer =>
        $(".task-pane-chat .message-editor").focus()

      return

    return

  "click .read-indicator-block": (e, tpl) ->
    channel_obj = getTaskChannelObjectForTaskId(@task_id)

    channel_obj.toggleChannelUnreadState()

    e.stopPropagation()

    $(e.target).closest(".read-indicator-block").find(".tooltip-content").remove()

    return

