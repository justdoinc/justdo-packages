Template.mobile_navbar.helpers
  tabs: -> 
    return APP.justdo_pwa.getMobileTabs()

  isActiveTab: (tab_id) -> 
    return APP.justdo_pwa.getActiveMobileTabId() is tab_id

  shouldRenderTab: ->
    if @listingCondition?
      return @listingCondition()

    return true

Template.mobile_navbar.events
  "click .mobile-navbar-btn": (e, tpl) ->
    APP.justdo_pwa.setActiveMobileTab($(e.currentTarget).data("tab"))

    return

Template.mobile_tabs.helpers
  activeMobileTab: ->
    return APP.justdo_pwa.getActiveMobileTab()

Template.mobile_tab_notifications.helpers
  requiredActions: -> APP.projects.modules.required_actions.getCursor({allow_undefined_fields: true, sort: {date: -1}}).fetch()

  requiredActionsCount: -> APP.projects.modules.required_actions.getCursor({fields: {_id: 1}}).count()

Template.mobile_tab_chats.helpers
  initialMessagesToRequest: ->
    tpl = Template.instance()
    return tpl.data.initial_messages_to_request

  activeChatChannel: ->
    return APP.justdo_pwa.getActiveChatChannel()

Template.mobile_tab_chats_active_chat_channel.onRendered ->
  Meteor.defer =>
    @$(".open-chat-window").addClass("window-active")
    @$(".message-editor").focus()
    return

  return
  
Template.mobile_tab_chats_active_chat_channel.helpers
  templateData: ->
    channel_type = @channel_type
    channel_identifier = @channel_identifier

    data = 
      channel_type: channel_type
      channel_identifier: channel_identifier

    if channel_type is "task"
      task_id = channel_identifier.task_id
      project_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id
      if not project_id?
        project_id = APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne({_id: task_id}, {fields: {project_id: 1}})?.project_id

      _.extend data,
        task_id: task_id
        project_id: project_id
        header_template: "task_channel_chat_bottom_windows_header"
        channelObjectGenerator: ->
          channel_conf = 
            tasks_collection: APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks
            task_id: channel_identifier.task_id
          return APP.justdo_chat.generateClientChannelObject("task", channel_conf)

    if channel_type is "user"
      receiving_user_id = _.find channel_identifier.user_ids, (user_id) -> user_id isnt Meteor.userId()
      _.extend data,
        header_template: "user_channel_chat_bottom_windows_header"
        receiving_user_id: receiving_user_id
        channelObjectGenerator: ->
          return APP.justdo_chat.generateClientUserChatChannel receiving_user_id, {open_bottom_window: false}

    return data