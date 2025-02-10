# Note the constructor below extends the ChannelBaseClient constructor
ChannelBaseClient = share.ChannelBaseClient

channel_conf = JustdoChat.getChannelTypeConf("group")

{channel_type, channel_identifier_fields_simple_schema} = channel_conf

# Name should follow task-channel-both-register.coffee : channel_type_camel_case + "ChannelClient"
GroupChannelClient = (options) ->
  ChannelBaseClient.call this, options

  return @

Util.inherits GroupChannelClient, ChannelBaseClient

_.extend GroupChannelClient.prototype,
  _errors_types: _.extend {}, ChannelBaseClient.prototype._errors_types, 
    "project-not-found": "Channel associated JustDo does not exist"

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-client" # for logging purposes

  channel_conf_schema: channel_identifier_fields_simple_schema
  
  superManageSubscribers: GroupChannelClient.prototype.manageSubscribers
  manageSubscribers: (update, options, cb) ->
    @requirePerformingUserIsAdmin()
    return @superManageSubscribers update, options, cb

  getChannelProjectDoc: ->
    if not (project_id = @channel_conf.project_id)
      return null
    
    return @justdo_chat.projects_collection.findOne(project_id)
  
  loadChannel: ->
    # Attempt to get project_id from channel doc if exists in subscription
    if not @channel_conf.project_id?
      query_options = 
        fields: 
          project_id: 1
      # Attempt to get channel doc from JDChatChannels first, then JDChatRecentActivityChannels
      if not (channel_doc = APP.collections.JDChatChannels.findOne(@channel_conf, query_options))?
        channel_doc = APP.collections.JDChatRecentActivityChannels.findOne(@channel_conf, query_options)
      
      if (project_id = channel_doc?.project_id)?
        @channel_conf.project_id = project_id

    if @channel_conf.project_id? and not @getChannelProjectDoc()?
      throw @_error "project-not-found"
      
    return

  getAdminIds: ->
    return _.map @getMessagesSubscriptionChannelDoc({fields: {admins: 1}})?.admins, (admin) -> admin.user_id

  isPerformingUserAdmin: ->
    # Anyone can be an admin of a new channel
    if not @getMessagesSubscriptionChannelDocId()
      return true
    
    return _.find(@getAdminIds(), (user_id) => user_id is Meteor.userId())?
  
  requirePerformingUserIsAdmin: ->
    if not @isPerformingUserAdmin()
      throw @_error("permission-denied", "You are not an admin of this channel")
    return true
  
  manageAdmins: (update, options) ->
    @requirePerformingUserIsAdmin()
    Meteor.call "jdcManageChannelAdmins", @channel_type, @getChannelIdentifier(), update, options
    return

  getChannelIdentifier: ->
    # Read docs in channel-base-client.coffee
    return {_id: @channel_conf._id, project_id: @channel_conf.project_id}
  
  setChannelTitle: (title, options={}) ->
    @requirePerformingUserIsAdmin()
    Meteor.call "jdcSetChannelTitle", @channel_type, @getChannelIdentifier(), title, options
    return
  
  getChannelTitle: ->
    if not (title = @getMessagesSubscriptionChannelDoc({fields: {title: 1}})?.title)?
      title = APP.collections.JDChatBottomWindowsChannels.findOne(@getChannelIdentifier(), {fields: {title: 1}})?.title
    return title
  
  setChannelDescription: (description, options={}) ->
    Meteor.call "jdcSetChannelDescription", @channel_type, @getChannelIdentifier(), description, options
    return

  getChannelDescription: ->
    if not (description = @getMessagesSubscriptionChannelDoc({fields: {description: 1}})?.description)?
      description = APP.collections.JDChatBottomWindowsChannels.findOne(@getChannelIdentifier(), {fields: {description: 1}})?.description
    return description
  
  setChannelIcon: (icon, options={}) ->
    Meteor.call "jdcSetChannelIcon", @channel_type, @getChannelIdentifier(), icon, options
    return
  
  getChannelIcon: ->
    # XXX default_icon is using the fallback user icon from JustdoAvatar. It is meant to be changed in the future.
    default_icon = JustdoHelpers.getCDNUrl("/packages/justdoinc_justdo-chat/lib/ui/channels/group/assets/anonymous-users-profile-image.png")

    if not (icon = @getMessagesSubscriptionChannelDoc({fields: {group_icon: 1}})?.group_icon)?
      icon = APP.collections.JDChatBottomWindowsChannels.findOne(@getChannelIdentifier(), {fields: {group_icon: 1}})?.group_icon
    return icon or default_icon
  
  sendChannelCreatedNotification: ->
    Meteor.call "jdcSendChannelCreatedNotification", @channel_type, @getChannelIdentifier()
    return

share.GroupChannelClient = GroupChannelClient

# Setup group channel specific APIs and methods
_.extend JustdoChat.prototype,
  _generateClientGroupChatChannelObjectOptionsSchema: new SimpleSchema
    _id:
      type: String
      optional: true
    project_id:
      type: String
      optional: true
    member_ids:
      type: [String]
      optional: true
    admin_ids:
      type: [String]
      optional: true
    title:
      type: String
      optional: true
    description:
      type: String
      optional: true
    open_bottom_window: 
      type: Boolean
      optional: true
      defaultValue: true
    send_channel_created_notification:
      type: Boolean
      optional: true
      defaultValue: true
  # generateClientGroupChatChannelObject is a low-level method that programatically generate a client side group channel obj.
  # To bring up the UI for creating new group chat, use upsertGroupChat
  generateClientGroupChatChannelObject: (options={}) ->
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_generateClientGroupChatChannelObjectOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
  
    # If options._id is provided, it means the user assumes the channel exists and has access to the channel
    # In this case we simply return the channel object.
    # (Acess checking is performed on server side channel obj when methods like sendMessage or manageSubscribers is called,
    #  note that if the user doesn't acutally has access, the method calls will do nothing.)
    if not _.isEmpty(channel_id = options._id)
      return @generateClientChannelObject("group", {_id: channel_id, project_id: options.project_id}, options)

    # If options._id is not provided, it means the user wants to create a new channel.
    # We create a new channel object and call manageSubscribers to add the current user as a subscriber.
    channel_obj = @generateClientChannelObject("group", {_id: Random.id(), project_id: options.project_id}, options)

    {member_ids, admin_ids, title, description, open_bottom_window, send_channel_created_notification} = options
    if send_channel_created_notification
      channel_obj.sendChannelCreatedNotification()

    if not _.isEmpty admin_ids
      channel_obj.manageSubscribers {add: admin_ids}, {send_notification: false}
      channel_obj.manageAdmins {add: admin_ids}, {send_notification: false}

    if not _.isEmpty member_ids
      channel_obj.manageSubscribers {add: member_ids}, {send_notification: false}

    title = title or TAPi18n.__ "default_group_chat_title"
    channel_obj.setChannelTitle title, {send_notification: false}

    if description?
      channel_obj.setChannelDescription description, {send_notification: false}
    
    if open_bottom_window
      channel_obj.makeWindowVisible()

    return channel_obj

  _upsertGroupChatOptionsSchema: new SimpleSchema
    group_id:
      type: String
      optional: true
    members_to_add:
      type: [String]
      optional: true
      defaultValue: []
  upsertGroupChat: (options) ->
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_upsertGroupChatOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    action = "create"
    if options.group_id?
      channel = APP.justdo_chat.generateClientGroupChatChannelObject({_id: options.group_id})
      action = "edit"
      # As of writing, channels without project_id are special type of channel
      # that are used from our bot to send welcome message to new users.
      # Therefore they shouldn't be editable by users.
      if not channel.getChannelProjectDoc()?
        return
    
    if (action is "create") and not JD.activeJustdoId()?
      console.info "Cannot create group channel without a JustDo"
      return
    
    modal_template = JustdoHelpers.renderTemplateInNewNode Template.group_channel_settings, {channel, members_to_add: options.members_to_add}

    dialog = bootbox.dialog
      title: TAPi18n.__ "#{action}_group_chat_modal_title"
      message: modal_template.node
      animate: true
      className: "bootbox-new-design"
      onEscape: true
      buttons:
        cancel: 
          label: APP.justdo_i18n.generateI18nModalButtonLabel "cancel"
          className: "btn-secondary"
          callback: ->
            return true
        [action]:
          label: APP.justdo_i18n.generateI18nModalButtonLabel action
          className: "btn-primary"
          callback: ->
            tpl = modal_template.template_instance
            members_to_add = tpl.members_to_add_rv.get()
            title = $("#group-channel-title").val()
            description = $("#group-channel-description").val()

            if action is "create"
              channel = APP.justdo_chat.generateClientGroupChatChannelObject({member_ids: members_to_add, project_id: JD.activeJustdoId(), title, description})
            else
              # Existing channel is already created above
              members_to_remove = tpl.members_to_remove_rv.get()
              if (not _.isEmpty members_to_add) or (not _.isEmpty members_to_remove)
                channel.manageSubscribers {add: members_to_add, remove: members_to_remove}

              if title isnt tpl.channel.getChannelTitle()
                channel.setChannelTitle title
              
              if description isnt tpl.channel.getChannelDescription()
                channel.setChannelDescription description

            return

    return

