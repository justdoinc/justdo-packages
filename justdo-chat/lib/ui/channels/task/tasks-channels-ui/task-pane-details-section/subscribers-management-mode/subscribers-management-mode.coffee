Template.task_pane_chat_section_subscribers_management.onCreated ->
  @members_search_val_rv = new ReactiveVar null
  @selected_subscribed_users_ids_rv = new ReactiveVar null
  @show_search_clear_button_rv = new ReactiveVar false

  @getMainTemplate = =>
    return Template.closestInstance("task_pane_chat_section")

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

  @selected_subscribed_users_ids_rv.set Object.keys(@getSubscribersHash())

  return

Template.task_pane_chat_section_subscribers_management.onRendered ->
  $(".subscribers-search").focus()
  
  return

Template.task_pane_chat_section_subscribers_management.helpers
  taskMembers: ->
    tpl = Template.instance()

    members_search_val_rv = tpl.members_search_val_rv.get()

    main_tpl = tpl.getMainTemplate()

    task_members = JD.activeItemUsers()

    task_members_doc = Meteor.users.find({_id: {$in: task_members}}).fetch()

    task_members_doc = JustdoHelpers.sortUsersDocsArrayByDisplayName(task_members_doc)
    task_members_doc = JustdoHelpers.filterUsersDocsArray(task_members_doc, members_search_val_rv, {sort: true})

    subscribed_members = []

    for member in task_members_doc
      if member._id of tpl.getSubscribersHash()
        subscribed_members.push member

    unsubscribed_members = task_members_doc.filter((member) ->
      subscribed_members.indexOf(member) < 0
    )

    task_members = [].concat(subscribed_members).concat(unsubscribed_members)

    return task_members

  isSubscriber: ->
    tpl = Template.instance()

    if @_id of tpl.getSubscribersHash()
      return true

    return false

  showSearchClearButton: ->
    return Template.instance().show_search_clear_button_rv.get()

Template.task_pane_chat_section_subscribers_management.events
  "click .sm-cancel": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    main_tpl.mode.set("chat")

    return

  "click .sm-save": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()

    selected_subscribed_users_ids = tpl.selected_subscribed_users_ids_rv.get()

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

    selected_subscribed_users_ids_rv = tpl.selected_subscribed_users_ids_rv.get()
    selected_user_id = $(e.currentTarget).find(".subscribe-state").attr("user-id")

    if selected_subscribed_users_ids_rv.includes selected_user_id
      selected_subscribed_users_ids_rv.splice(selected_subscribed_users_ids_rv.indexOf(selected_user_id), 1)
    else
      selected_subscribed_users_ids_rv.push selected_user_id

    tpl.selected_subscribed_users_ids_rv.set selected_subscribed_users_ids_rv

    return

  "keyup .subscribers-search": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.members_search_val_rv.set null
      tpl.show_search_clear_button_rv.set false
    else
      tpl.members_search_val_rv.set value
      tpl.show_search_clear_button_rv.set true

    return

  "click .subscribers-search-x": (e, tpl) ->
    $(".subscribers-search").val ""
    tpl.members_search_val_rv.set null
    tpl.show_search_clear_button_rv.set false

    return
