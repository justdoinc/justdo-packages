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

    for system_update_id, system_update_def of JustdoSystemUpdates.system_updates
      if system_update_id in read_system_updates_ids
        # Already read

        continue

      if (show_to_users_registered_before = system_update_def.show_to_users_registered_before)?
        if cur_user.createdAt >= show_to_users_registered_before
          # User registered after the time the message is relevant.
      
          continue

      # XXX For now we assume up to 1 message will be relevant at a time
      @_displayUpdate(system_update_id)

    @messages_presented = true

    return

  _displayUpdate: (system_update_id) ->
    data = {}

    system_update_def = JustdoSystemUpdates.system_updates[system_update_id]

    system_update_template =
      JustdoHelpers.renderTemplateInNewNode(Template[system_update_def.template], data)

    showLater = ->
      return

    markAsRead = ->
      Meteor.users.update(Meteor.userId(), {$push: {"profile.read_system_updates": {update_id: system_update_id, read_at: new Date(TimeSync.getServerTime())}}})

      return

    bootbox.dialog
      title: system_update_def.title
      message: system_update_template.node
      className: "members-update-dialog bootbox-new-design"
      focused_element: ""

      onEscape: ->
        markAsRead()

        return true

      buttons:
        read_later:
          label: "Read Later"

          className: "btn-light"

          callback: =>
            showLater()

            return true

        ok:
          label: "OK"

          callback: ->
            markAsRead()

            return true

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
