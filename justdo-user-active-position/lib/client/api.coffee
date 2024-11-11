_.extend JustdoUserActivePosition.prototype,
  _immediateInit: ->
    APP.justdo_analytics.getClientStateValues (state) =>
      @jd_analytics_client_state = state

      @setupPosTracker()
      @setupTabCloseTracker()
      @setupGridHooksMaintainer()

      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return

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
