_.extend JustdoUserActivePosition.prototype,
  _immediateInit: ->
    APP.justdo_analytics.getClientStateValues (state) =>
      @jd_analytics_client_state = state

      @setupPosTracker()
      @setupTabCloseTracker()
      @setupGridHooksMaintainer()
      @registerConfigTemplate()
      @setupUserConfigUi()
      @setupCustomFeatureMaintainer()
      @on_grid_positions_tracker_enabled_dep = new Tracker.Dependency()

      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  isModuleEnabled: ->
    return APP.modules.project_page.curProj()?.isCustomFeatureEnabled(JustdoUserActivePosition.project_custom_feature_id)

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoUserActivePosition.project_custom_feature_id,
        installer: =>
          if @onGridUserActivePositionEnabled()
            @setupProjectMembersCurrentPositionsSubscriptionTracker()
            @setupActiveProjectMembersIndicator()
            # Whether to show the project members' on grid positions or not determines on local storage (isProjectMembersCurrentOnGridPositionsTrackerEnabled)
            if @isProjectMembersCurrentOnGridPositionsTrackerEnabled()
              @setupProjectMembersCurrentOnGridPositionsTracker()

          return

        destroyer: =>
          if @onGridUserActivePositionEnabled()
            @removeProjectMembersCurrentPositionsSubscriptionTracker()
            @removeProjectMembersCurrentOnGridPositionsTracker()
            @removeActiveProjectMembersIndicator()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  setupUserConfigUi: ->
    APP.executeAfterAppLibCode ->
      main_module = APP.modules.main

      main_module.user_config_ui.registerConfigSection "show-user-active-position",
        title: "show_user_active_position_config_title"
        priority: 1100

      main_module.user_config_ui.registerConfigTemplate "show-user-active-position-setter",
        section: "show-user-active-position"
        template: "toggle_private_mode_user_conf"
        priority: 100


  setupPosTracker: ->
    @last_pos_logged = null
    @pending_pos = null
    @current_active_editor_field = null

    @pos_flush_manager = new JustdoHelpers.FlushManager
      min_flush_delay: 150

    @pos_flush_manager.on "flush", =>
      # Shouldn't happen, but if it does, just return
      if not @pending_pos?
        return

      # If exact same @pending_pos, don't log
      if not EJSON.equals(@pending_pos, @last_pos_logged)
        @emit "log-pos", @last_pos_logged, @pending_pos
        @logPos(@pending_pos)

        @last_pos_logged = @pending_pos

      @pending_pos = null

      return

    Tracker.autorun =>
      @setPendingPos(@getPos())

      return

    return

  setPendingPos: (pos) ->
    @pending_pos = pos
    @pos_flush_manager.setNeedFlush()

    return

  getPos: ->
    pos =
      # This client side "time" is for justdo_promoters_campaigns only.
      # It won't be stored to the db; Schema autovalue will handle the actual "time" stored.
      time: new Date()

    if not (justdo_id = JD.activeJustdoId() or null)?
      _.extend pos, {justdo_id: null}
      return pos
    else
      if (gcm = APP.modules.project_page.grid_control_mux.get())?
        if (tab_def = gcm.getActiveTab())?
          active_gc = tab_def.grid_control
          Tracker.nonreactive => @ensureHooksInstalledOnGridControl(active_gc)

          path = JD.activePath()

          _.extend pos, {justdo_id, tab: tab_def.getTabURI(), path}

          if @current_active_editor_field?
            pos.field = @current_active_editor_field

          return pos

    _.extend pos, {justdo_id: justdo_id, tab: "LOADING"}
    return pos

  ensureHooksInstalledOnGridControl: (grid_control) ->
    # Install hooks if weren't installed yet on this gc
    if not grid_control._user_active_position_hooks_installed?
      grid_control.on "edit-cell", (args) =>
        @current_active_editor_field = args.field

        @setPendingPos(@getPos())

        return

      grid_control.on "cell-editor-destroyed", (args) =>
        @current_active_editor_field = null

        @setPendingPos(@getPos())

        return

      grid_control._user_active_position_hooks_installed = true

      return

    return

  setupTabCloseTracker: ->
    $(window).on "beforeunload", =>
      @logPos({page: "EXIT"})

      return

    return

  setupGridHooksMaintainer: ->
    Tracker.autorun =>
      return
    return

  getProjectMembersCurrentPositionsCursor: ->
    if not (project_id = JD.activeJustdoId())?
      return

    return @users_active_positions_current_collection.find({justdo_id: project_id})

  # Not to be confused with setupProjectMembersCurrentOnGridPositionsTracker:
  # This is a Tracker that manages the subscription to the project members current positions
  # and the cursor to the collection.
  #
  # The other one is a Tracker that maintains the current positions of the project members
  # and updates the UI accordingly.
  setupProjectMembersCurrentPositionsSubscriptionTracker: ->
    @_project_member_current_positions_subscription_tracker = Tracker.autorun =>
      if (not (project_id = JD.activeJustdoId())?)
        return

      # Note that subscriptions inside a reactive context will be cancelled when the context is invalidated, so we don't need to unsubscribe.
      APP.justdo_user_active_position.subscribeToProjectMembersCurrentPositions project_id

      return

    return
  removeProjectMembersCurrentPositionsSubscriptionTracker: ->
    @_project_member_current_positions_subscription_tracker?.stop?()
    @_project_member_current_positions_subscription_tracker = null

    return

  # See the comment above for setupProjectMembersCurrentPositionsSubscriptionTracker.
  setupProjectMembersCurrentOnGridPositionsTracker: ->
    @setProjectMembersCurrentOnGridPositionsTrackerEnabled(true)
    @_project_members_current_positions_tracker = Tracker.autorun =>
      if (not (project_id = JD.activeJustdoId())?) or not (grid_control = APP.modules.project_page.gridControl())?
        return

      # Remove all search-result class from all rows
      $(".search-result", grid_control.container).removeClass("search-result")

      # Add search-result class to the rows that are currently active
      @getProjectMembersCurrentPositionsCursor().forEach (ledger_doc) =>
        if (item_index = grid_control._grid_data.getPathGridTreeIndex(ledger_doc.path))?
          $(".slick-row:nth-child(#{item_index + 1})", grid_control.container).addClass("search-result")

        return

    return
  removeProjectMembersCurrentOnGridPositionsTracker: ->
    @setProjectMembersCurrentOnGridPositionsTrackerEnabled(false)
    $(".slick-row.search-result").removeClass("search-result")
    @_project_members_current_positions_tracker?.stop?()
    @_project_members_current_positions_tracker = null

    return

  setProjectMembersCurrentOnGridPositionsTrackerEnabled: (enabled) ->
    amplify.store "justdo_user_active_position_show_user_on_grid_positions", enabled
    @on_grid_positions_tracker_enabled_dep.changed()

    return
  isProjectMembersCurrentOnGridPositionsTrackerEnabled: ->
    @on_grid_positions_tracker_enabled_dep.depend()
    return amplify.store "justdo_user_active_position_show_user_on_grid_positions"

  setupActiveProjectMembersIndicator: ->
    @_active_project_members_indicator_tracker = Tracker.autorun =>
      if (not (project_id = JD.activeJustdoId())?) or (@getProjectMembersCurrentPositionsCursor().count() is 0)
        JD.unregisterPlaceholderItem("active-project-members-indicator")
        return

      JD.registerPlaceholderItem "active-project-members-indicator",
        data:
          template: "active_project_members_indicator"
          template_data: {}

        domain: "project-left-navbar"
        position: 101

      return

    return
  removeActiveProjectMembersIndicator: ->
    @_active_project_members_indicator_tracker?.stop?()
    @_active_project_members_indicator_tracker = null

    return

  isUserLedgerDocInactive: (user_id) ->
    ledger_doc = @users_active_positions_current_collection.findOne({UID: user_id}, {fields: {time: 1}})
    if not ledger_doc?
      return false

    return ledger_doc.time < (Date.now() - JustdoUserActivePosition.idle_time_to_consider_session_inactive)

  isCurrentUserShowingActivePosition: ->
    return APP.justdo_user_active_position.isUserShowingActivePosition(Meteor.user())
