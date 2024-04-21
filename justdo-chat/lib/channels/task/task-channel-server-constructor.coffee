# Note the constructor below extends the ChannelBaseServer constructor
ChannelBaseServer = share.ChannelBaseServer

channel_conf = JustdoChat.getChannelTypeConf("task")

{channel_type, channel_identifier_fields_simple_schema} = channel_conf

# Name should follow task-channel-both-registrar.coffee : channel_type_camel_case + "ChannelServer"
TaskChannelServer = (options) ->
  ChannelBaseServer.call this, options

  return @

Util.inherits TaskChannelServer, ChannelBaseServer

_.extend TaskChannelServer.prototype,
  _errors_types: _.extend {}, ChannelBaseServer.prototype._errors_types, {}

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-server" # for logging purposes

  channel_identifier_schema: channel_identifier_fields_simple_schema

  _channel_task_doc_cache: null
  getIdentifierTaskDoc: (allow_cache=true) ->
    if allow_cache and @_channel_task_doc_cache?

      return @_channel_task_doc_cache

    {task_id} = @channel_identifier
    task_doc = @justdo_chat.tasks_collection.findOne(@channel_identifier.task_id)

    @_channel_task_doc_cache = task_doc

    return task_doc

  getIdentifierProjectId: ->
    # Note, we rely here on the @getIdentifierTaskDoc() and not on @getChannelDocNonReactive()
    # to retreive the project id, since the @getIdentifierTaskDoc(), will always be called in
    # order to init the channel obj to verify the user's permission to access the doc, hence
    # we will have it cached and we won't do further calls to the db.
    #
    # @getChannelDocNonReactive(), is more likely to cause a hit to the db.

    return @getIdentifierTaskDoc().project_id

  _channel_project_doc_cache: null
  getIdentifierProjectDoc: (allow_cache=true) ->
    project_id = @getIdentifierProjectId()

    if allow_cache and @_channel_project_doc_cache?
      return @_channel_project_doc_cache

    project_doc = @justdo_chat.projects_collection.findOne(project_id, {fields: {_id: 1, title: 1}})

    @_channel_project_doc_cache = project_doc

    return project_doc

  isValidChannelIdentifier: ->
    if not @getIdentifierTaskDoc()?
      return false

    return true

  _getUsersAccessPermission: (users_ids) ->
    if not (task_doc = @getIdentifierTaskDoc())?
      return false

    result_array = {
      permitted: []
      not_permitted: []
    }
    for user_id in users_ids
      if @justdo_chat.isBotUserId user_id
        result_array.permitted.push user_id
      else if @justdo_chat.tasks_collection.isUserBelongToItem(task_doc, user_id)
        result_array.permitted.push user_id
      else
        result_array.not_permitted.push user_id

    return result_array

  loadChannel: ->
    @on "message-sent", =>
      task_doc = @getIdentifierTaskDoc()

      query =
        _id: task_doc._id

      update =
        $set: 
          "#{JustdoChat.tasks_chat_channel_last_message_from_field_id}": @performing_user
        $currentDate:
          "#{JustdoChat.tasks_chat_channel_last_message_date_field_id}": true

      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update)

      @justdo_chat.tasks_collection.rawCollection().update query, update, Meteor.bindEnvironment (err) ->    
        if err?
          @logger.error("Failed to log a message sent, error:")
          console.error err

          return

        return

      return

    @on "channel-unread-state-changed", (unread) =>
      task_doc = @getIdentifierTaskDoc()

      private_fields_mutator =
        $currentDate:
          "#{JustdoChat.tasks_chat_channel_last_read_field_id}": true

      APP.projects._grid_data_com._upsertItemPrivateData(task_doc.project_id, task_doc._id, private_fields_mutator, @performing_user)

      return

    return

  getChannelAugmentedFields: ->
    task_doc = @getIdentifierTaskDoc()

    return {project_id: task_doc.project_id}

  getChannelRecentActivitySupplementaryDocs: ->
    sup_cols =
      JustdoChat.getChannelTypeConf(@channel_type).recent_activity_supplementary_pseudo_collections

    # We assume all user projects are published, and doesn't need to be published 
    channel_task_doc = _.pick @getIdentifierTaskDoc(), ["_id", "seqId", "project_id", "title", "users"]

    supplementary_docs = [
      [sup_cols.tasks, channel_task_doc._id, channel_task_doc]
    ]

    return supplementary_docs

  getBottomWindowsChannelsSupplementaryDocs: ->
    sup_cols =
      JustdoChat.getChannelTypeConf(@channel_type).bottom_windows_supplementary_pseudo_collections

    # We assume all user projects are published, and doesn't need to be published 
    channel_task_doc = _.pick @getIdentifierTaskDoc(), ["_id", "seqId", "project_id", "title", "users"]

    supplementary_docs = [
      [sup_cols.tasks, channel_task_doc._id, channel_task_doc]
    ]

    return supplementary_docs

share.TaskChannelServer = TaskChannelServer