_.extend JustdoSystemUpdates.prototype,
  _immediateInit: ->
    @login_state_tracker = Tracker.autorun =>
      login_state = APP.login_state.getLoginState()
      login_state_sym = login_state[0]

      if login_state_sym == "logged-in" and @isEnabledForLoggedInUser()
        @_presentPendingMessages()

      return

    return

  messages_presented: false
  _presentPendingMessages: ->
    if @messages_presented
      # Once messages presented - that's it for this session

      return

    # Assumes the user is logged in.
    cur_user = Meteor.user({fields: {createdAt: 1, "profile.read_system_updates": 1}})

    if not cur_user.profile?
      # If profile isn't ready yet (I don't know if this case might really happen, but bug reports from users might suggest it D.C)

      return

    if not (read_system_updates = cur_user.profile.read_system_updates)?
      read_system_updates = []

    read_system_updates_ids = _.map read_system_updates, (read_message_doc) -> read_message_doc.update_id
    all_system_updates_sorted_time_desc = _.sortBy(APP.justdo_news.getAllNewsByCategory("news"), "date").reverse()
    unread_system_update_ids = []

    # Go through the list of sorted updates. Break when we encountered the first read news, or the first news that is registered before the user.
    for system_update_def in all_system_updates_sorted_time_desc
      system_update_id = system_update_def._id

      if system_update_id in read_system_updates_ids
        break

      if (show_to_users_registered_before = system_update_def.date)?
        show_to_users_registered_before = moment(show_to_users_registered_before, "YYYY-MM-DD").toDate()
        if cur_user.createdAt >= show_to_users_registered_before
          # User registered after the time the message is relevant.
          break

      unread_system_update_ids.push system_update_id

    if not _.isEmpty unread_system_update_ids
      @_displayUpdate unread_system_update_ids

    @messages_presented = true

    return

  _displayUpdate: (system_update_ids, options) ->
    if _.isString system_update_ids
      system_update_ids = [system_update_ids]
    if not _.isArray system_update_ids
      options = system_update_ids
      system_update_ids = [APP.justdo_news.getMostRecentNewsIdUnderCategory "news"]

    page_number = 0 # Default is the most recent system update
    most_recent_system_update_id = system_update_ids[page_number]

    controller = new JustdoNews.NewsController()
    system_update_template =
      JustdoHelpers.renderTemplateInNewNode("news", {controller, router_navigation: false, category: "news", news_id: most_recent_system_update_id})

    showLater = ->
      return

    markAsRead = ->
      if not options?.ignore_mark_as_read
        Meteor.users.update(Meteor.userId(), {$push: {"profile.read_system_updates": {update_id: most_recent_system_update_id, read_at: new Date(TimeSync.getServerTime())}}})

      return

    all_dialog_buttons =
      read_later:
        label: "Read Later"
        className: "btn-light"
        callback: =>
          showLater()
          return true

      prev:
        label: "Prev"
        className: "btn-light prev-news disabled"
        callback: =>
          $self = $(".modal-footer>.prev-news")
          if $self.hasClass "disabled"
            return false

          page_number -= 1
          $(".modal-footer>.next-news").removeClass "disabled"

          if page_number <= 0
            page_number = 0
            $self.addClass "disabled"

          controller.setActiveNewsId system_update_ids[page_number]
          return false

      next:
        label: "Next"
        className: "btn-light next-news"
        callback: =>
          $self = $(".modal-footer>.next-news")
          if $self.hasClass "disabled"
            return false

          page_number += 1
          $(".modal-footer>.prev-news").removeClass "disabled"

          if page_number >= (unread_updates_length = system_update_ids.length - 1)
            page_number = unread_updates_length
            $self.addClass "disabled"

          controller.setActiveNewsId system_update_ids[page_number]
          return false

      ok:
        label: "OK"
        className: "btn-primary"
        callback: ->
          markAsRead()
          return true

    dialog_buttons = {}
    if options?.ignore_mark_as_read
      dialog_buttons.ok = all_dialog_buttons.ok

    else
      dialog_buttons.read_later = all_dialog_buttons.read_later
      if system_update_ids.length > 1
        dialog_buttons.prev = all_dialog_buttons.prev
        dialog_buttons.next = all_dialog_buttons.next
      dialog_buttons.ok = all_dialog_buttons.ok

    bootbox.dialog
      title: "We Have Great New Things for You"
      message: system_update_template.node
      className: "members-update-dialog bootbox-new-design"
      focused_element: ""

      onEscape: ->
        markAsRead()

        return true

      buttons: dialog_buttons


    return

  _deferredInit: ->
    if @destroyed
      return

    @_setupUserConfigUi()

    return

  _setupUserConfigUi: ->
    APP.executeAfterAppLibCode ->
      module = APP.modules.main

      module.user_config_ui.registerConfigSection "show-system-updates",
        title: "Display system updates"
        priority: 1000

      module.user_config_ui.registerConfigTemplate "show-system-updates-setter",
        section: "show-system-updates"
        template: "justdo_system_updates_config"
        priority: 100

      return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @login_state_tracker.stop()

    @logger.debug "Destroyed"

    return

  isEnabledForLoggedInUser: ->
    # Only disable showing system updates when show_system_updates is explicitly set to disabled
    user_profile = Meteor.user({fields: {"profile.show_system_updates": 1}}).profile

    if user_profile.show_system_updates? and not user_profile.show_system_updates
      return false

    return true

  toggleDisplayOption: ->
    if not (show_system_updates = Meteor.user({fields: {"profile.show_system_updates": 1}}).profile.show_system_updates)?
      show_system_updates = true

    Meteor.users.update(Meteor.userId(), {$set: {"profile.show_system_updates": not show_system_updates}})

    return
