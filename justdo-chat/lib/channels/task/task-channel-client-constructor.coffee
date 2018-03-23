# Note the constructor below extends the ChannelBaseClient constructor
ChannelBaseClient = share.ChannelBaseClient

channel_conf = JustdoChat.getChannelTypeConf("task")

{channel_type} = channel_conf

# Name should follow task-channel-both-register.coffee : channel_type_camel_case + "ChannelClient"
TaskChannelClient = (options) ->
  ChannelBaseClient.call this, options

  return @

Util.inherits TaskChannelClient, ChannelBaseClient

_.extend TaskChannelClient.prototype,
  _errors_types: _.extend {}, ChannelBaseClient.prototype._errors_types, {}

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-client" # for logging purposes

  channel_conf_schema: new SimpleSchema
    tasks_collection:
      type: "skip-type-check"
      optional: false

    task_id:
      type: String
      optional: false

  loadChannel: ->
    # Bind all channel_conf props to @
    {@tasks_collection, @task_id} = @channel_conf

    return

  getChannelIdentifier: ->
    # Read docs in channel-base-client.coffee

    return {task_id: @task_id}

  proposedSubscribersForNewChannel: ->
    if not (task_doc = @tasks_collection.findOne(@task_id))?
      return []

    return _.union([Meteor.userId(), task_doc.owner_id])

  #
  # Manage Chat Records Subscription
  #
  # _task_chat_records_subscription: null
  # _setupTaskChatRecordsSubscription: ->
  #   unsubscribe = =>
  #     if @_task_chat_records_subscription?
  #       @_task_chat_records_subscription.stop()
  #   subscribe = =>
  #     unsubscribe()

  #     @_task_chat_records_subscription = Meteor.subscribe "rpTasksResources", subtree_tasks

  #     return
  #   @onDestroy =>
  #     unsubscribe()

  #   return

  # isTaskChatRecordsSubscriptionReady: -> @_task_chat_records_subscription.ready()



share.TaskChannelClient = TaskChannelClient