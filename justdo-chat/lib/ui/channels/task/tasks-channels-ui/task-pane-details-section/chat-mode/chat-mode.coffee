Template.project_toolbar_chat_section_chat.onCreated ->
  @getMainTemplate = =>
    return Template.closestInstance("project_toolbar_chat_section")

getTemplateChannelObject = ->
  main_tpl = Template.instance().getMainTemplate()

  return main_tpl.getTaskChatObject()

getTemplateChannelMessagesSubscriptionState = ->
  channel = getTemplateChannelObject()

  return channel.getChannelMessagesSubscriptionState()

getChannelSubscribersIdsIntersectionWithTaskMembersIds = (channel) ->
  # Due to the non-transactional nature of mongo, we are running a potential
  # risk of an edge case where removed task members remains in the task's
  # channel subscribers list, we therefore, count the intersection
  # between the subscribers list and the existing task members.

  if not (subscribers_array = channel.getSubscribersArray())?
    return []

  subscribers_ids = _.map subscribers_array, (sub) -> sub.user_id

  task_members = APP.modules.project_page.activeItemObj({"users": true}).users

  return _.intersection(subscribers_ids, task_members)

Template.project_toolbar_chat_section_chat.helpers
  getTaskChatObject: ->
    main_tpl = Template.instance().getMainTemplate()

    return main_tpl.getTaskChatObject # Note, we don't call main_tpl.getTaskChatObject just pass reference, hence we don't use getTemplateChannelObject

  getChannelMessagesSubscriptionState: ->
    channel = getTemplateChannelObject()

    return channel.getChannelMessagesSubscriptionState()

  isSubscriptionReady: ->
    channel_messages_subscription_state = getTemplateChannelMessagesSubscriptionState()

    return channel_messages_subscription_state not in ["no-sub", "initial-not-ready"]

  isSubscriptionReadyChannelExistsAndNotEmptyOrHasSubscribers: ->
    # We treat existing, empty, channel with no subscribers the same way as non-existing
    # channel.

    channel = getTemplateChannelObject()

    channel_messages_subscription_state = getTemplateChannelMessagesSubscriptionState()
    channel_ready_and_exists =
      channel_messages_subscription_state not in ["no-sub", "initial-not-ready", "no-channel-doc"]

    # The commented condition doesn't look good.
    if not channel_ready_and_exists # and not channel.isProposedSubscribersEmulationMode() # if we are under proposed subscribers emulation mode, non-existing channel might have pseudo users so we treat it like existing
      return false

    channel_doc = channel.getMessagesSubscriptionChannelDoc()

    channel_has_subscribers = not _.isEmpty(channel.getSubscribersArray())

    return channel.isMessagesSubscriptionHasDocs() or channel_has_subscribers

  isSubscribedToChannel: ->
    channel = getTemplateChannelObject()

    return channel.isUserSubscribedToChannel(Meteor.userId())

  subscribersCount: ->
    channel = getTemplateChannelObject()

    return getChannelSubscribersIdsIntersectionWithTaskMembersIds(channel).length

  subscribersDisplayNames: (limit=10) ->
    channel = getTemplateChannelObject()

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
    channel = getTemplateChannelObject()

    return channel.toggleUserSubscriptionToChannel(Meteor.userId())

  "click .subscribers-management-button-block, click .subscribers-names": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    main_tpl.mode.set("subscribers-management")

    return

  "click": (e, tpl) ->
    # Click anywhere will mark the channel as read
    if getTemplateChannelMessagesSubscriptionState() not in ["no-sub", "initial-not-ready", "no-channel-doc"]
      channel = getTemplateChannelObject()

      channel.setChannelUnreadState(false)

      return

    return
