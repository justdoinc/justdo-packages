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
      if @justdo_chat.tasks_collection.isUserBelongToItem(task_doc, user_id)
        result_array.permitted.push user_id
      else
        result_array.not_permitted.push user_id

    return result_array

  loadChannel: -> return

  getChannelAugmentedFields: ->
    task_doc = @getIdentifierTaskDoc()

    return {project_id: task_doc.project_id}

  getChannelRecentActivitySupplementaryDocs: ->
    sup_cols =
      JustdoChat.getChannelTypeConf(@channel_type).recent_activity_supplementary_pseudo_collections

    # We assume all user projects are published, and doesn't need to be published 
    channel_task_doc = _.pick @getIdentifierTaskDoc(), ["_id", "seqId", "project_id", "title"]

    supplementary_docs = [
      [sup_cols.tasks, channel_task_doc._id, channel_task_doc]
    ]

    return supplementary_docs

share.TaskChannelServer = TaskChannelServer