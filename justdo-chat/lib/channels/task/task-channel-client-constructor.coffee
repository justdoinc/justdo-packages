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

  findMembersMentionedInMessageThatArentSubscribers: (message) ->
    existing_subscribers_ids = _.map @getSubscribersArray(), (subscriber) -> subscriber.user_id

    if not (task_doc = @tasks_collection.findOne(@task_id))?
      return []

    non_subscribed_members_ids = _.difference task_doc.users, existing_subscribers_ids

    if _.isEmpty non_subscribed_members_ids
      return []

    task_members_docs = Meteor.users.find({_id: {$in: non_subscribed_members_ids}}).fetch()

    regex = /(?:^|\s)@([\w\d]{2,})(?:[?:.,])?/ig

    potential_names_found = []
    while (result = regex.exec(message))?
      potential_names_found.push result[1].toLowerCase()

    non_subscribers_members_ids_mentioned = []
    for task_members_doc in task_members_docs
      for potential_name_found in potential_names_found
        if potential_name_found in [task_members_doc.profile?.first_name.toLowerCase(), task_members_doc.profile?.last_name.toLowerCase()]
          non_subscribers_members_ids_mentioned.push task_members_doc._id

    return non_subscribers_members_ids_mentioned

  loadChannel: ->
    # Bind all channel_conf props to @
    {@tasks_collection, @task_id} = @channel_conf

    @on "message-sent", (payload) =>
      if not _.isEmpty(mentioned_members_ids_to_add = @findMembersMentionedInMessageThatArentSubscribers(payload.body))
        @manageSubscribers {add: mentioned_members_ids_to_add}

      return

    return

  getChannelIdentifier: ->
    # Read docs in channel-base-client.coffee

    return {task_id: @task_id}

  proposedSubscribersForNewChannel: ->
    if not (task_doc = @tasks_collection.findOne(@task_id))?
      return []

    ownership_related_suggestions =
      _.compact(_.union([Meteor.userId(), task_doc.owner_id, task_doc.pending_owner_id]))

    if task_doc.users.length == 2
      only_two_users_related_suggestions = _.compact(task_doc.users)

    all_suggestions = 
      _.union(ownership_related_suggestions, only_two_users_related_suggestions)

    return all_suggestions

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