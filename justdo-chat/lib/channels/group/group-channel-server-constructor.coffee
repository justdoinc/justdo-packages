# Note the constructor below extends the ChannelBaseServer constructor
ChannelBaseServer = share.ChannelBaseServer

channel_conf = JustdoChat.getChannelTypeConf("group")

{channel_type, channel_identifier_fields_simple_schema} = channel_conf

# Name should follow task-channel-both-registrar.coffee : channel_type_camel_case + "ChannelServer"
GroupChannelServer = (options) ->
  ChannelBaseServer.call this, options

  return @

Util.inherits GroupChannelServer, ChannelBaseServer

_.extend GroupChannelServer.prototype,
  _errors_types: _.extend {}, ChannelBaseServer.prototype._errors_types, 
    "project-not-found": "Channel associated JustDo not exist"

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-server" # for logging purposes

  channel_identifier_schema: channel_identifier_fields_simple_schema

  _superVerifyChannelIdentifierObjectAgainstSchema: GroupChannelServer.prototype._verifyChannelIdentifierObjectAgainstSchema
  _verifyChannelIdentifierObjectAgainstSchema: ->
    # Ensure that if a channel exists in the db and has project_id, the project_id is set in the channel_identifier object
    # Most group channels have project_id, therefore we don't optimize for the extra hit to the db in the case
    # of group channel without project_id
    
    received_project_id = @channel_identifier.project_id
    delete @channel_identifier.project_id
    # Ensure the project_id in channel_identifier, if exists in the db, is the same as the one in the db.
    if (project_id = @getChannelDocCursor({fields: {project_id: 1}}).fetch()?[0]?.project_id)?
      @channel_identifier.project_id = project_id
    else
      @channel_identifier.project_id = received_project_id
  
    return @_superVerifyChannelIdentifierObjectAgainstSchema()

  # Because sendMessage will call manageSubscribers to ensure the sender is a subscriber,
  # and in group channels manageSubscribers is only allowed for admins, we need to skip
  # the call in sendMessage by setting skip_add_sender_as_subscribers to true
  superSendMessage: GroupChannelServer.prototype.sendMessage
  sendMessage: (message_obj, message_type, options={}) ->
    options.skip_add_sender_as_subscribers = true
    return @superSendMessage message_obj, message_type, options

  # In tasks channel we use removeNonPermittedUsers to filter out users that are not permitted to access the channel in manageSubscribers.
  # removeNonPermittedUsers internally calls _getUsersAccessPermission, which we use to check whether a user is already a member(subscriber) of the channel.
  # That would essentially prevent any new subscribers from being added. So we create our own checking for manageSubscribers.
  # Note that this method edits the update in-place.
  _removeNonPermittedNewSubscribers: (update) ->
    if not (new_subscribers = update?.add)?
      return
    if not (project_doc = @getIdentifierProjectDoc())
      return
    
    project_members = _.map project_doc.members, (member) -> member.user_id
    update.add = _.intersection new_subscribers, project_members

    return
  # Wrap the manageSubscribers method to ensure only admins can manage subscribers
  _manageSubscribersOptionsSchema: new SimpleSchema
    skip_remove_non_permitted_users:
      type: Boolean
      defaultValue: false
      optional: true
    send_notification:
      type: Boolean
      defaultValue: true
      optional: true
  superManageSubscribers: GroupChannelServer.prototype.manageSubscribers
  manageSubscribers: (update, options={}) ->
    @requirePerformingUserIsAdmin()

    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @_manageSubscribersOptionsSchema,
      options or {},
      {self: @, throw_on_error: true}
    )
    options = cleaned_val

    if not _.isEmpty(removed_admins = _.intersection update.remove, @getAdminIds())
      @manageAdmins {remove: removed_admins}, {send_notification: false}
    
    if not options.skip_remove_non_permitted_users
      @_removeNonPermittedNewSubscribers update
    
    # We perform our own access checking here, so we can pass the skip_remove_non_permitted_users
    res = @superManageSubscribers update, {skip_remove_non_permitted_users: true}

    if options.send_notification
      if not _.isEmpty(added_user_ids = res?.added)
        @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-subscriber-added", performed_by: @performing_user, subscribers: added_user_ids}

      if not _.isEmpty(removed_user_ids = res?.removed)
        @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-subscriber-removed", performed_by: @performing_user, subscribers: removed_user_ids}

    return res

  superRequirePerformingUserPermittedToAccessChannel: GroupChannelServer.prototype.requirePerformingUserPermittedToAccessChannel
  requirePerformingUserPermittedToAccessChannel: ->
    # If performing_user is not set, assume the channel is created by server
    if @justdo_chat.isBotUserId @performing_user
      return 
    return @superRequirePerformingUserPermittedToAccessChannel()

  isChannelDocExistsInDB: -> @getChannelDocCursor().count() > 0

  getIdentifierProjectId: ->
    return @channel_identifier.project_id

  _channel_project_doc_cache: null
  getIdentifierProjectDoc: (allow_cache=true) ->
    if not (project_id = @getIdentifierProjectId())?
      return

    if allow_cache and @_channel_project_doc_cache?
      return @_channel_project_doc_cache
      
    project_doc = @justdo_chat.projects_collection.findOne(project_id)

    @_channel_project_doc_cache = project_doc

    return project_doc

  requireChannelProjectDocExists: ->
    if not @getIdentifierProjectDoc()
      throw @_error "project-not-found"
    return true

  loadChannel: ->
    if not @justdo_chat.isBotUserId @performing_user
      if not @isChannelDocExistsInDB()
        # User-created group channel must have a project associated to it
        @requireChannelProjectDocExists()
        @manageAdmins {add: [@performing_user]}, {send_notification: false}
        @manageSubscribers {add: [@performing_user]}, {send_notification: false}
          
    return

  getAdminIds: ->
    return _.map(@getChannelDocCursor({fields: {admins: 1}})?.fetch()?[0]?.admins, (admin) -> admin.user_id)

  isPerformingUserAdmin: ->
    # Anyone can be an admin of a new channel
    if not @isChannelDocExistsInDB()
      return true
    
    # If performing_user is not set, assume the channel is created by server
    if @justdo_chat.isBotUserId @performing_user
      return true
      
    return _.find(@getAdminIds(), (user_id) => user_id is @performing_user)?
    
  requirePerformingUserIsAdmin: ->
    if not @isPerformingUserAdmin()
      throw @_error("permission-denied", "You are not an admin of this channel")
    return true

  _manageAdminsSchema: new SimpleSchema
    add:
      type: [String]
      defaultValue: []
      optional: true
    remove:
      type: [String]
      defaultValue: []
      optional: true
  _manageAdminsOptionsSchema: new SimpleSchema
    send_notification:
      type: Boolean
      defaultValue: true
      optional: true
  manageAdmins: (update, options) ->
    # update should be of the following structure
    #
    # {
    #   add: [] # users to add
    #   remove: [] # users to remove
    # }
    #
    # IMPORTANT:
    # Added admins that are already an admin are completely ignored.
    # Removed admins that aren't an admin are completely ignored.
    # If added admins aren't subscribers of the channel, they will be ignored.
    #
    # If same user id is in both add and in remove, invalid-argument will be thrown
    #
    # The add array is filtered through the @removeNonPermittedUsers(), we don't worry about the remove array.
    #

    @requirePerformingUserIsAdmin()

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_manageAdminsSchema,
        update,
        {self: @, throw_on_error: true}
      )
    update = cleaned_val

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_manageAdminsOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if not _.isEmpty _.intersection(update.add, update.remove)
      throw @_error "invalid-argument", "Can't add and remove the same admin at the same time"
    
    existing_admins = @getAdminIds()

    # Add only users that are not already admins and has access to channel
    admins_to_add = @removeNonPermittedUsers(_.difference update.add, existing_admins)
    if not _.isEmpty admins_to_add
      # getChannelDocNonReactive will generate the channel doc in the db
      if not @isChannelDocExistsInDB()
        @getChannelDocNonReactive()

      appointed_by = @performing_user
      if (not appointed_by) or (@justdo_chat.isBotUserId appointed_by)
        appointed_by = "system"

      admins_to_add = _.map admins_to_add, (user_id) -> {user_id, appointed_by, appointed_at: new Date()}
      op =
        $addToSet: 
          admins: 
            $each: admins_to_add
      @findAndModifyChannelDoc {update: op}

      if options?.send_notification
        added_admin_ids = _.map admins_to_add, (admin) -> admin.user_id
        @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-admin-appointed", admins: added_admin_ids, performed_by: @performing_user}

    # _.intersection guarentees uniqness of the returned array
    admins_to_remove = _.intersection update.remove, existing_admins
    if not _.isEmpty admins_to_remove
      # getChannelDocNonReactive will generate the channel doc in the db
      if not @isChannelDocExistsInDB()
        @getChannelDocNonReactive()

      op = 
        $pull:
          admins:
            user_id:
              $in: update.remove 
      @findAndModifyChannelDoc {update: op}

      if options?.send_notification
        @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-admin-removed", admins: admins_to_remove, performed_by: @performing_user}

    return

  isValidChannelIdentifier: ->
    # Proper checking and schema validation is done in _verifyChannelIdentifierObjectAgainstSchema
    return true

  _getUsersAccessPermission: (users_ids) ->
    result_array = {
      permitted: []
      not_permitted: []
    }

    project_doc = @getIdentifierProjectDoc()

    # Allow anyone to create a new channel
    if not @isChannelDocExistsInDB()
      if project_doc?
        project_members = _.map project_doc.members, (member) -> member.user_id
        result_array.permitted = _.intersection users_ids, project_members
        result_array.not_permitted = _.difference users_ids, project_members
      else
        result_array.permitted = _.uniq users_ids
      return result_array

    channel_doc = @getChannelDocNonReactive()

    for user_id in users_ids
      if @justdo_chat.isBotUserId user_id
        result_array.permitted.push user_id
      else if project_doc? and not (_.find project_doc.members, (member) -> member.user_id is user_id)?
        result_array.not_permitted.push user_id
      else if _.find channel_doc?.subscribers, (subscriber) -> subscriber.user_id is user_id
        result_array.permitted.push user_id
      else
        result_array.not_permitted.push user_id

    # Ensure results are unique
    result_array.permitted = _.uniq result_array.permitted
    result_array.not_permitted = _.uniq result_array.not_permitted
    return result_array

  _setChannelTitleOptionsSchema: new SimpleSchema
    send_notification:
      type: Boolean
      optional: true
      defaultValue: true
  setChannelTitle: (title, options) ->
    @requirePerformingUserIsAdmin()

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_setChannelTitleOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    res = @findAndModifyChannelDoc {update: {$set: {title}}}
    
    if options.send_notification
      @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-title-changed", new_title: title, performed_by: @performing_user}
    return res
  
  getChannelTitle: ->
    return @getChannelDocNonReactive()?.title or ""
  
  _setChannelDescriptionOptionsSchema: new SimpleSchema
    send_notification:
      type: Boolean
      optional: true
      defaultValue: true
  setChannelDescription: (description, options) ->
    check description, String

    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_setChannelDescriptionOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    res = @findAndModifyChannelDoc {update: {$set: {description}}}
    
    if options?.send_notification
      @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-description-changed", performed_by: @performing_user}
    return res
  
  getChannelDescription: ->
    return @getChannelDocNonReactive()?.description or ""
  
  _setChannelIconOptionsSchema: new SimpleSchema
    send_notification:
      type: Boolean
      optional: true
      defaultValue: true
  setChannelIcon: (group_icon, options) ->
    check group_icon, String
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_setChannelIconOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    res = @findAndModifyChannelDoc {update: {$set: {group_icon}}}
    
    if options?.send_notification
      @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-icon-changed", performed_by: @performing_user}
    return res
  
  getChannelIcon: ->
    return @getChannelDocNonReactive()?.group_icon
  
  sendChannelCreatedNotification: ->
    # Don't send if there're already messages in the channel
    if (message_count = @getChannelDocCursor({fields: {messages_count: 1}})?.fetch()?[0]?.messages_count)?
      if message_count > 0
        return
    
    @justdo_chat.insertLogMessageToChannel @channel_type, @channel_identifier, {type: "group-created", performed_by: @performing_user}
    return

share.GroupChannelServer = GroupChannelServer

# Setup group channel specific APIs and methods
_.extend JustdoChat.prototype,
  _generateServerGroupChatChannelObjectSchema: new SimpleSchema
    _id:
      type: String
      optional: true
    project_id:
      type: String
      optional: true
    new_channel_options:
      type: Object
      optional: true
    "new_channel_options.title":
      type: String
      optional: true
    "new_channel_options.member_ids":
      type: [String]
      optional: true
    "new_channel_options.admin_ids":
      type: [String]
      optional: true
    "new_channel_options.open_bottom_window":
      type: Boolean
      optional: true
      defaultValue: true
    "new_channel_options.send_channel_created_notification":
      type: Boolean
      optional: true
      defaultValue: true
  generateServerGroupChatChannelObject: (options, user_id) ->
    check user_id, Match.Maybe String
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_generateServerGroupChatChannelObjectSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    # If _id is provided, it means the user assumes the channel exists and has access to the channel
    # In this case we simply return the channel object.
    # (Access checking is performed on channel obj when methods like sendMessage or manageSubscribers is called,
    #  note that if the user doesn't acutally has access, the method calls throw an error.)
    # We use _.isEmpty to prevent user creating a channel with an empty string as _id.
    if not _.isEmpty(channel_id = options._id) 
      return @generateServerChannelObject("group", {_id: channel_id, project_id: options.project_id}, user_id)

    channel_identifier = {_id: Random.id(), project_id: options.project_id}
    channel_obj = @generateServerChannelObject("group", channel_identifier, user_id)

    new_channel_options = options.new_channel_options or {}
    
    if new_channel_options.send_channel_created_notification
      channel_obj.sendChannelCreatedNotification()

    if (admin_ids = new_channel_options.admin_ids)?
      channel_obj.manageSubscribers {add: admin_ids}, {send_notification: false}
      channel_obj.manageAdmins {add: admin_ids}, {send_notification: false}
    
    if (member_ids = new_channel_options.member_ids)?
      channel_obj.manageSubscribers {add: member_ids}, {send_notification: false}

    title = new_channel_options.title or APP.justdo_i18n.tr "default_group_chat_title", {}, user_id
    channel_obj.setChannelTitle title, {send_notification: false}
    
    if new_channel_options.open_bottom_window
      channel_obj.setBottomWindow 
        order: 0
        state: "open"

    return channel_obj
