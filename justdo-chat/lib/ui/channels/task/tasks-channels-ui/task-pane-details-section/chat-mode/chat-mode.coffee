Template.project_toolbar_chat_section_chat.onCreated ->
  @getMainTemplate = =>
    return Template.closestInstance("project_toolbar_chat_section")

getChannelSubscribersIdsIntersectionWithTaskMembersIds = (channel) ->
  # Due to the non-transactional nature of mongo, we are running a potential
  # risk of an edge case where removed task members remains in the task's
  # channel subscribers list, we therefore, count the intersection
  # between the subscribers list and the existing task members.

  if not (channel_doc = channel.getMessagesSubscriptionChannelDoc())?
    return []

  subscribers_ids = _.map channel_doc.subscribers, (sub) -> sub.user_id

  task_members = APP.modules.project_page.activeItemObj({"users": true}).users

  return _.intersection(subscribers_ids, task_members)

Template.project_toolbar_chat_section_chat.helpers
  getTaskChatObject: ->
    main_tpl = Template.instance().getMainTemplate()

    return main_tpl.getTaskChatObject

  isChannelExistAndReady: ->
    main_tpl = Template.instance().getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    return channel.isChannelExistAndReady()

  isSubscribedToChannel: ->
    main_tpl = Template.instance().getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    return channel.isUserSubscribedToChannel(Meteor.userId())

  subscribersCount: ->
    main_tpl = Template.instance().getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    return getChannelSubscribersIdsIntersectionWithTaskMembersIds(channel).length

  subscribersDisplayNames: (limit=10) ->
    main_tpl = Template.instance().getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    subscribers_ids = getChannelSubscribersIdsIntersectionWithTaskMembersIds(channel)

    truncated = false
    if subscribers_ids.length > limit
      truncated = true
      subscribers_ids = subscribers_ids.slice(0, limit) # take up to 10

    task_members_doc = Meteor.users.find({_id: {$in: subscribers_ids}}).fetch()

    subscribers_names = _.map(task_members_doc, (user_obj) -> JustdoHelpers.displayName(user_obj)).join(", ")

    if truncated
      subscribers_names = "#{subscribers_names}, ..."

    return subscribers_names

Template.project_toolbar_chat_section_chat.events
  "click .user-subscription-toggle": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    return channel.toggleUserSubscriptionToChannel(Meteor.userId())

  "click .subscribers-management-button-block": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    main_tpl.mode.set("subscribers-management")

    return

  "click": (e, tpl) ->
    # Click anywhere will mark the channel as read
    main_tpl = tpl.getMainTemplate()

    channel = main_tpl.getTaskChatObject()

    channel.setChannelUnreadState(false)

    return
