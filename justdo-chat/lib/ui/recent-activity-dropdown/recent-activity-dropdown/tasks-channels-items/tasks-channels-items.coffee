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

    return Meteor.users.findOne(last_message.author)

  friendlyDateFormat: (date) ->
    return APP.justdo_chat.friendlyDateFormat(date)

getTaskChannelObjectForTaskId = (task_id) ->
  channel_obj = APP.justdo_chat.generateClientChannelObject "task", { # channel conf
    grid_control: {} # Required options, but we might not have it in all cases, and for our needs from the channel_obj, it is redundant.
    project_object: {} # Required options, but we might not have it in all cases, and for our needs from the channel_obj, it is redundant.
    task_id: task_id
  }, { # other options
    custom_channels_collection: APP.collections.JDChatRecentActivityChannels
    custom_messages_collection: APP.collections.JDChatRecentActivityMessages
  }

  return channel_obj

Template.recent_activity_item_task.events
  "click .recent-activity-items-task": ->
    channel_project = getChannelProject(@project_id)
    channel_task = getChannelTask(@task_id)

    window.location = "/p/#{channel_project._id}#&t=main&p=/#{channel_task._id}/"

    if not (dropdown_instance = Template.instance().getDropdownInstance())?
      # We shouldn't get here

      logger.warn "Can't find dropdown instance"

      return

    channel_obj = getTaskChannelObjectForTaskId(@task_id)
    channel_obj.setChannelUnreadState(false)

    dropdown_instance.closeDropdown()

    Meteor.defer =>
      $(".task-pane-chat .message-editor").focus()

    return

  "click .read-indicator": (e, tpl) ->
    channel_obj = getTaskChannelObjectForTaskId(@task_id)

    channel_obj.toggleChannelUnreadState()

    e.stopPropagation()

    return

