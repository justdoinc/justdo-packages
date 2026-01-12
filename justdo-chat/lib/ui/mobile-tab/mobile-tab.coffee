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

Template.mobile_tab_chats.helpers
  initialMessagesToRequest: ->
    tpl = Template.instance()
    return tpl.data.initial_messages_to_request

  activeChatChannel: ->
    return APP.justdo_chat.getActiveMobileChatChannel()

Template.mobile_tab_chats_active_chat_channel.onCreated ->
  channel_type = @data?.channel_type
  channel_identifier = @data?.channel_identifier

  @getDefaultChatWindowTemplateData = ->
    default_chat_window_template_data = 
      channel_type: channel_type
      channel_identifier: channel_identifier

    return default_chat_window_template_data

  if channel_type is "task"
    task_id = channel_identifier.task_id
    project_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id
    if not project_id?
      project_id = APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks.findOne({_id: task_id}, {fields: {project_id: 1}})?.project_id

    @channelObjectGenerator = ->
      channel_conf = 
        tasks_collection: APP.justdo_chat.recent_activity_supplementary_pseudo_collections.tasks
        task_id: channel_identifier.task_id
      return APP.justdo_chat.generateClientChannelObject("task", channel_conf)

    @getTemplateDataForChatWindow = ->
      data = _.extend @getDefaultChatWindowTemplateData(),
        task_id: task_id
        project_id: project_id
        header_template: "task_channel_chat_bottom_windows_header"
        channelObjectGenerator: @channelObjectGenerator

      return data

  if channel_type is "user"
    receiving_user_id = _.find channel_identifier.user_ids, (user_id) -> user_id isnt Meteor.userId()

    @channelObjectGenerator = ->
      return APP.justdo_chat.generateClientUserChatChannel receiving_user_id, {open_bottom_window: false}

    @getTemplateDataForChatWindow = ->
      data = _.extend @getDefaultChatWindowTemplateData(),
        header_template: "user_channel_chat_bottom_windows_header"
        receiving_user_id: receiving_user_id
        channelObjectGenerator: @channelObjectGenerator

      return data
  
  return

Template.mobile_tab_chats_active_chat_channel.onRendered ->
  Meteor.defer =>
    channel_obj = @channelObjectGenerator()
    channel_obj.enterFocusMode()

    @$(".open-chat-window").addClass("window-active")
    @$(".message-editor").focus()
    return

  return
  
Template.mobile_tab_chats_active_chat_channel.helpers
  templateData: ->
    tpl = Template.instance()
    return tpl.getTemplateDataForChatWindow()