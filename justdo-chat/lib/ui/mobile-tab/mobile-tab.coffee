_.extend JustdoChat.prototype,
  _setupMobileTab: ->
    APP.justdo_pwa.registerMobileTab "chats",
      label: "chat_label"
      order: 300
      icon_template: "justdo_chat_recent_activity_button"
      icon_template_data:
        skip_dropdown_creation: true
      tab_template: "mobile_tab_chats"
      tab_template_data:
        initial_messages_to_request: 20
    return

  active_mobile_chat_channel_rv: new ReactiveVar null
  setActiveMobileChatChannel: (channel_type, channel_identifier) ->
    @active_mobile_chat_channel_rv.set({channel_type, channel_identifier})
    return

  getActiveMobileChatChannel: ->
    return @active_mobile_chat_channel_rv.get()

  clearActiveMobileChatChannel: ->
    @active_mobile_chat_channel_rv.set null
    return

  _setupPushNotificationsHandlers: ->
    self = @

    JustdoHelpers.hooks_barriers.runCbAfterBarriers "post-justdo-pwa-init", ->
      APP.justdo_pwa?.registerPushNotificationTapHandler JustdoChat.chat_message_push_notification_message_type, (notification) =>
        channel_type = notification.data.channel_type
        channel_id = notification.data.channel_id
        channel_identifier = {}

        is_task_channel = channel_type is "task"
        is_user_channel = channel_type is "user"
        if is_task_channel
          channel_identifier.task_id = notification.data.task_id
          channel_identifier.project_id = notification.data.project_id
        if is_user_channel
          channel_identifier.user_ids = [Meteor.userId(), notification.data.sender]

        # First clear all active chat screens and set the chats tab as active
        self.clearActiveMobileChatChannel()
        APP.justdo_pwa.setActiveMobileTab "chats"

        # Before opening the chat screen related to the notification, 
        # wait for the channel to be ready and other related resources to be ready.
        JustdoHelpers.awaitValueFromReactiveResource
          reactiveResource: ->
            reactive_res = 
              channel_exists_in_recent_activity: APP.collections.JDChatRecentActivityChannels.findOne({_id: channel_id})?
            if is_task_channel
              _.extend reactive_res, 
                task_exists: APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne({_id: channel_identifier.task_id})?
                project_exists: APP.collections.Projects.findOne({_id: channel_identifier.project_id})?
            return reactive_res
          evaluator: (reactive_res) ->
            ready = reactive_res.channel_exists_in_recent_activity
            if is_task_channel
              ready = ready and reactive_res.task_exists and reactive_res.project_exists
            return ready
          cb: ->
            self.setActiveMobileChatChannel channel_type, channel_identifier
            return
          timeout: 5000

        return

      return
    return

Template.mobile_tab_chats.helpers
  initialMessagesToRequest: ->
    tpl = Template.instance()
    return tpl.data.initial_messages_to_request

  activeChatChannel: ->
    return APP.justdo_chat.getActiveMobileChatChannel()

Template.mobile_tab_chats_active_chat_channel.onCreated ->
  @channelObjectGenerator = ->
    {channel_type, channel_identifier} = APP.justdo_chat.getActiveMobileChatChannel()

    if channel_type is "task"
      channel_conf =
        tasks_collection: APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks
        task_id: channel_identifier.task_id
      return APP.justdo_chat.generateClientChannelObject(channel_type, channel_conf)

    if channel_type is "user"
      receiving_user_id = _.find channel_identifier.user_ids, (user_id) -> user_id isnt Meteor.userId()
      return APP.justdo_chat.generateClientUserChatChannel receiving_user_id, {open_bottom_window: false}

  return

Template.mobile_tab_chats_active_chat_channel.onRendered ->
  @autorun =>
    if @channel_obj?
      @channel_obj.destroy()

    @channel_obj = @channelObjectGenerator()
    @channel_obj.enterFocusMode()
    Meteor.defer =>
      @$(".open-chat-window").addClass("window-active")
      @$(".message-editor").focus()
      return
    return

  return

Template.mobile_tab_chats_active_chat_channel.helpers
  templateData: ->
    tpl = Template.instance()

    {channel_type, channel_identifier} = APP.justdo_chat.getActiveMobileChatChannel()

    default_chat_window_template_data = 
      channel_type: channel_type
      channel_identifier: channel_identifier

    if channel_type is "task"
      task_id = channel_identifier.task_id
      project_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id
      if not project_id?
        project_id = APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne({_id: task_id}, {fields: {project_id: 1}})?.project_id

      data = _.extend default_chat_window_template_data,
        task_id: task_id
        project_id: project_id
        header_template: "task_channel_chat_bottom_windows_header"
        channelObjectGenerator: tpl.channelObjectGenerator

      return data

    if channel_type is "user"
      receiving_user_id = _.find channel_identifier.user_ids, (user_id) -> user_id isnt Meteor.userId()

      data = _.extend default_chat_window_template_data,
        header_template: "user_channel_chat_bottom_windows_header"
        receiving_user_id: receiving_user_id
        channelObjectGenerator: tpl.channelObjectGenerator

      return data
