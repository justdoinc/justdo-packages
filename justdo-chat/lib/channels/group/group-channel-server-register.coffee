# YOU *AREN'T* OBLIGATED TO CALL JustdoChat.registerChannelTypeServerSpecific for
# types you got no server specific confs for.

GROUP_MESSAGE_TYPES =
  "group-created": 
    data_schema:
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} created this channel."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} created this channel."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} created this channel."
  "group-subscriber-added":
    data_schema:
      subscribers:
        type: [String]
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} invited {{subscribers}} to this channel."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} invited {{subscribers}} to this channel."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} invited {{subscribers}} to this channel."
  "group-subscriber-removed":
    data_schema:
      subscribers:
        type: [String]
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} removed {{subscribers}} from this channel."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} removed {{subscribers}} from this channel."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} removed {{subscribers}} from this channel."
  "group-admin-appointed":
    data_schema:
      admins:
        type: [String]
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} promoted {{admins}} as admin of this channel."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} promoted {{admins}} as admin of this channel."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} promoted {{admins}} as admin of this channel."
  "group-admin-removed":
    data_schema:
      admins:
        type: [String]
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} demoted {{admins}} as admin of this channel."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} demoted {{admins}} as admin of this channel."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} demoted {{admins}} as admin of this channel."
  "group-title-changed":
    data_schema:
      new_title:
        type: String
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} changed the title of this channel to {{new_title}}."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} changed the title of this channel to {{new_title}}."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} changed the title of this channel to {{new_title}}."
  "group-description-changed":
    data_schema:
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} updated the group description."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} updated the group description."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} updated the group description."
  "group-icon-changed":
    data_schema:
      performed_by:
        type: String
    rec_msgs_templates: # rec stands for recommanded
      en:
        "{{performed_by}} updated the group picture."
    rec_andr_msgs_templates_pre: # andr stands for android; pre stands for pre-support
      en:
        "{{performed_by}} updated the group picture."
    rec_andr_msgs_templates_post:
      en:
        "{{performed_by}} updated the group picture."

JustdoChat.registerChannelTypeServerSpecific
  channel_type: "group" # Must be the same as group-channel-both-register.coffee

  _immediateInit: ->
    # Register the group channel specific notifications
    for message_id, message_obj of GROUP_MESSAGE_TYPES
      @registerBotMessagesTypes "bot:log", {[message_id]: message_obj}

    # Register group channel specific methods
    Meteor.methods
      jdcManageChannelAdmins: (channel_type, channel_identifier, update, options={}) ->
        # Security note:
        #
        # channel_identifier is checked thoroughly by generateServerGroupChatChannelObject.
        # update is checked thoroughly by manageAdmins. 

        check channel_type, String
        check channel_identifier, Object
        check update, Object
        check options, Match.Maybe Object
        check @userId, String

        APP.justdo_chat.requireAllowedChannelType(channel_type)
        if channel_type isnt "group"
          throw APP.justdo_chat._error "invalid-argument", "Only group channel is supported"

        channel_obj = APP.justdo_chat.generateServerGroupChatChannelObject channel_identifier, @userId
        return channel_obj.manageAdmins update, options

      jdcSetChannelTitle: (channel_type, channel_identifier, title, options={}) ->
        # Security note:
        #
        # channel_identifier is checked thoroughly by generateServerGroupChatChannelObject.
        # options is checked thoroughly by setChannelTitle.
        
        check channel_type, String
        check channel_identifier, Object
        check title, String
        check @userId, String
        check options, Object

        APP.justdo_chat.requireAllowedChannelType(channel_type)
        if channel_type isnt "group"
          throw APP.justdo_chat._error "invalid-argument", "Only group channel is supported"

        channel_obj = APP.justdo_chat.generateServerGroupChatChannelObject channel_identifier, @userId
        return channel_obj.setChannelTitle(title, options)
      
      jdcSetChannelDescription: (channel_type, channel_identifier, description, options={}) ->
        # Security note:
        #
        # channel_identifier is checked thoroughly by generateServerGroupChatChannelObject.
        # options is checked thoroughly by setChannelDescription.
        
        check channel_type, String
        check channel_identifier, Object
        check description, String
        check @userId, String
        check options, Object

        APP.justdo_chat.requireAllowedChannelType(channel_type)
        if channel_type isnt "group"
          throw APP.justdo_chat._error "invalid-argument", "Only group channel is supported"

        channel_obj = APP.justdo_chat.generateServerGroupChatChannelObject channel_identifier, @userId
        return channel_obj.setChannelDescription(description, options)
      
      jdcSetChannelIcon: (channel_type, channel_identifier, icon, options={}) ->
        # Security note:
        #
        # channel_identifier is checked thoroughly by generateServerGroupChatChannelObject.
        # options is checked thoroughly by setChannelIcon.
        
        check channel_type, String
        check channel_identifier, Object
        check icon, String
        check @userId, String
        check options, Object

        APP.justdo_chat.requireAllowedChannelType(channel_type)
        if channel_type isnt "group"
          throw APP.justdo_chat._error "invalid-argument", "Only group channel is supported"

        channel_obj = APP.justdo_chat.generateServerGroupChatChannelObject channel_identifier, @userId
        return channel_obj.setChannelIcon(icon, options)
      
      jdcSendChannelCreatedNotification: (channel_type, channel_identifier) ->
        # Security note:
        #
        # channel_identifier is checked thoroughly by generateServerGroupChatChannelObject.
        
        check channel_type, String
        check channel_identifier, Object
        check @userId, String

        APP.justdo_chat.requireAllowedChannelType(channel_type)
        if channel_type isnt "group"
          throw APP.justdo_chat._error "invalid-argument", "Only group channel is supported"

        channel_obj = APP.justdo_chat.generateServerGroupChatChannelObject channel_identifier, @userId
        return channel_obj.sendChannelCreatedNotification()
    
    # Setup collection hook for managing channel subscriber based on project members
    @projects_collection.after.update (user_id, doc, field_names, modifier, options) =>
      if not (users_to_remove = modifier?.$pull?.members?.user_id)?
        return

      project_id = doc._id

      query = 
        project_id: project_id
        channel_type: "group"
      update = 
        $pull:
          subscribers:
            user_id: users_to_remove
          admins:
            user_id: users_to_remove
          bottom_windows:
            user_id: users_to_remove
      options = 
        multi: true

      # We use rawCollection() since the request is too heavy for collection2/simple-schema
      APP.justdo_analytics.logMongoRawConnectionOp(@channels_collection._name, "update", query, update, options)
      @channels_collection.rawCollection().update(query, update, options)

      return

    APP.projects.on "project-removed", (project_id) =>
      query = 
        project_id: project_id
        channel_type: "group"
      update = 
        $rename:
          subscribers: "archived_subscribers"
          admins: "archived_admins"
        $unset:
          bottom_windows: ""

      options = 
        multi: true

      # We use rawCollection() since the request is too heavy for collection2/simple-schema
      APP.justdo_analytics.logMongoRawConnectionOp(@channels_collection._name, "update", query, update, options)
      @channels_collection.rawCollection().update(query, update, options)

      return

    return

  _deferredInit: ->
    # @ is the JustdoChat object's

    return