Template.project_toolbar_chat_section_subscribers_management.onCreated ->
  @getMainTemplate = =>
    return Template.closestInstance("project_toolbar_chat_section")

  @subscribers_hash = null
  @getSubscribersHash = (use_cache=true) =>
    # We calculate @subscribers_hash only once, in a non-reactive fashion.
    if @subscribers_hash? and use_cache
      return @subscribers_hash
    
    return Tracker.nonreactive =>
      main_tpl = @getMainTemplate()

      channel = main_tpl.getTaskChatObject()

      if not (channel_subscribers_doc_on_creation = channel.getSubscribersArray())?
        channel_subscribers_doc_on_creation = []

      subscribers_hash = {}

      for subscriber in channel_subscribers_doc_on_creation
        subscribers_hash[subscriber.user_id] = true

      @subscribers_hash = subscribers_hash

      return @subscribers_hash

  return

Template.project_toolbar_chat_section_subscribers_management.helpers
  taskMembers: ->
    main_tpl = Template.instance().getMainTemplate()

    task_members = APP.modules.project_page.activeItemObj({"users": true}).users

    task_members_doc = Meteor.users.find({_id: {$in: task_members}}).fetch()

    task_members_doc = JustdoHelpers.sortUsersDocsArrayByDisplayName(task_members_doc)

    return task_members_doc

  isSubscriber: ->
    tpl = Template.instance()

    if @_id of tpl.getSubscribersHash()
      return true

    return false

Template.project_toolbar_chat_section_subscribers_management.events
  "click .sm-cancel": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    main_tpl.mode.set("chat")

    return

  "click .sm-save": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    selected_subscribed_users_ids = []
    tpl.$(".subscribed").each ->
      selected_subscribed_users_ids.push $(@).attr("user-id")

    channel = main_tpl.getTaskChatObject()

    if not channel.isProposedSubscribersEmulationMode()
      existing_subscribers_hash = tpl.getSubscribersHash(false) # false is to avoid using cache
    else
      existing_subscribers_hash = {}

    existing_subscribers_ids = _.keys existing_subscribers_hash

    subscribers_to_remove = _.difference existing_subscribers_ids, selected_subscribed_users_ids
    subscribers_to_add = _.difference selected_subscribed_users_ids, existing_subscribers_ids

    if not _.isEmpty subscribers_to_remove.concat(subscribers_to_add)
      channel.manageSubscribers {remove: subscribers_to_remove, add: subscribers_to_add}, ->
        main_tpl.mode.set("chat")
    else
      # Nothing to do, just go back to chat
      main_tpl.mode.set("chat")

    return

  "click .user-card": (e, tpl) ->
    $(e.target).closest(".user-card").find(".subscribe-state").toggleClass("subscribed unsubscribed")

    return