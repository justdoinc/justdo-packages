APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  #
  # project_grid container
  #
  Template.project_grid_container.helpers
    tasksSubscriptionReady: ->
      project = module.curProj()

      if not project?.tasks_subscription.ready()
        module.logger.debug "Waiting for tasks subscription to become ready"

        return false

      return true

  #
  # project_grid
  #
  path_change_tracker = null
  hashchange_cb = null
  active_grid_control_change_tracker = null
  Template.project_grid.rendered = ->
    @autorun ->
      project = module.curProj()

      if not project?
        APP.logger.debug "No project loaded"

        return

      container = $("#grid-control-mux")

      if not project.tasks_subscription.ready()
        module.logger.debug "Waiting for tasks subscription to become ready"

        # The following shouldn't really show, in practice 
        # the tasksSubscriptionReady helper takes care of
        # indicating loading state
        container.html("Loading...")

        return

      # I am using _project_id here and not project_id since under the
      # ```grid_control_mux.on "grid-control-created"``` later on in this file
      # we use the project_id name.
      #
      # Not sure if sharing the same name, ie setting project_id once in this stage
      # might lead to bugs, so decided not to mix the two. (Daniel C.)
      _project_id = APP.modules.project_page?.project?.get()?.id

      project_custom_fields_definitions_rv = new ReactiveVar {}
      project_custom_fields_definitions_rv_update_comp = null
      Tracker.nonreactive ->
        project_custom_fields_definitions_rv_update_comp = Tracker.autorun ->
          custom_fields =
            GridControlCustomFields.getProjectCustomFieldsDefinitions(APP.projects, _project_id)

          _.extend custom_fields, module.getPseudoCustomFields()

          project_custom_fields_definitions_rv.set(custom_fields)

          return

      project_removed_custom_fields_definitions_rv = new ReactiveVar {}
      project_removed_custom_fields_definitions_rv_update_comp = null
      Tracker.nonreactive ->
        project_removed_custom_fields_definitions_rv_update_comp = Tracker.autorun ->
          removed_custom_fields =
            GridControlCustomFields.getProjectRemovedCustomFieldsDefinitions(APP.projects, _project_id)

          project_removed_custom_fields_definitions_rv.set(removed_custom_fields)

          return

      Tracker.onInvalidate ->
        project_custom_fields_definitions_rv_update_comp.stop()

      #
      # hard-code the custom fields for the permitted domains below, for POC purposes
      #
      grid_control_mux = new GridControlMux
        container: container
        items_subscription: project.tasks_subscription
        use_shared_grid_data_core: true
        shared_grid_data_core_options:
          collection: APP.collections.Tasks
          tasks_query: {project_id: _project_id}
        shared_grid_control_options:
          expand_all_error_snackbar_text: "Too many tasks to expand the entire tree.<br />Refine your filter and try again"
          expand_all_error_snackbar_action_text: "Learn More"
          expand_all_error_snackbar_on_action_click: -> window.open("https://support.justdo.today/hc/en-us/articles/115003548313-What-to-do-if-I-can-t-can-t-expend-all-tasks-")
          usersDiffConfirmationCb:
            ProjectPageDialogs.JustdoTaskMembersDiffDialog.usersDiffConfirmationCb
        use_shared_grid_control_custom_fields_manager: true
        shared_grid_control_custom_fields_manager_options:
          custom_fields_definitions: project_custom_fields_definitions_rv
        use_shared_grid_control_removed_custom_fields_manager: true
        shared_grid_control_removed_custom_fields_manager_options:
          custom_fields_definitions: project_removed_custom_fields_definitions_rv
      module.grid_control_mux.set grid_control_mux

      APP.modules.project_page.emit "grid-control-mux-created", grid_control_mux

      grid_control_mux.on "grid-control-created", (tab) ->
        if not (project_id = APP.modules.project_page?.project?.get()?.id)
          module.logger.debug "Couldn't find project id"

          return

        tab_id = tab.tab_id
        gc = tab.grid_control

        # now, you'd expect that since we are running in the on callback of
        # the grid_control_mux it is safe to assume we are not running in a
        # computation.
        #
        # In fact, the grid_control_mux grid control creation is triggered
        # later in this code, and since the .on() is sync, it is technically
        # happen as part of this computation!
        preferences = Tracker.nonreactive ->
          module.preferences.get()

        if (saved_view = preferences.saved_grid_views?[project_id]?[tab_id])?
          module.logger.debug "Stored view found for project: #{project_id}, tab_id: #{tab_id}", saved_view

          gc.once "init", ->
            gc.setView(saved_view)

        do (gc, project_id, tab_id) ->
          gc.on "grid-view-change", (new_view) ->
            existing_preferences = module.preferences.get()

            Meteor._ensure existing_preferences, "saved_grid_views", project_id, tab_id
            preferences.saved_grid_views[project_id][tab_id] = new_view
            preferences = _.pick preferences, "saved_grid_views" # Update only 'saved_grid_views' preference
            module.updatePreferences(preferences)

            module.logger.debug "Update stored view for project: #{project_id}, tab_id: #{tab_id}"

            return

        return

      grid_control_mux.on "tab-ready", (tab) ->
        tab.owner_setter_manager = new module.OwnerSetterManager(tab.grid_control)

        APP.logger.debug "OwnersSetterManager initiated for tab: #{tab.tab_id}"

      grid_control_mux.on "tab-unload", (tab) ->
        if (osm = tab.owner_setter_manager)?
          osm.destroy()

          delete tab.owner_setter_manager

          APP.logger.debug "OwnersSetterManager destroyed for tab: #{tab.tab_id}"

      for tab in module.default_tabs_definitions
        grid_control_mux.addTab tab.id, tab.options

      module.search_comp =
        new GridControlSearch "#project-search-comp-container"

      # Update search_comp grid on tab change
      Tracker.nonreactive =>
        # Non reactive since we don't want changes
        # to active grid control to invalidate the enclosing
        # computation.
        active_grid_control = null
        active_grid_control_change_tracker = Tracker.autorun =>
          previous_active_grid_control = active_grid_control

          active_grid_control =
            grid_control_mux.getActiveGridControl(true) # true means that null will be returned as long as the grid isn't ready

          if active_grid_control is previous_active_grid_control
            # To understand more about when this might happen,
            # read about JustDo helpers computed-reactive-var
            APP.logger.debug "active_grid_control_change_tracker fired twice for same grid - skipping grid control change procedures"
            return

          if active_grid_control?
            module.search_comp.setGridControl(active_grid_control)
          else
            module.search_comp.unsetGridControl()

      last_hash_change_triggered_by_us = null
      # We don't want hash changes triggered by us, only
      # to reflect to the user the current location on the
      # address bar to trigger hashchange procedures
      hashchange_cb = ->
        current_hash = window.location.hash

        if current_hash.charAt(0) == "#"
          current_hash = current_hash.substr(1)

        if current_hash == last_hash_change_triggered_by_us
          # Ignore hashchange triggered by us
          last_hash_change_triggered_by_us = null # if later on, the user will trigger the same change, we should let him

          return

        if (request_path = module.getPathFromQueryString(current_hash))?
          if not request_path[0]?
            # If tab id didn't provided, use "main" - backward compatibility
            request_path[0] = "main"

          if request_path[0] == "my-due-list"
            # XXX Backward compatibility, can be removed as soon as
            # external email updates system updated
            request_path[0] = "due-list"

          grid_control_mux.setPath(request_path)

        if (sections_state = module.getSectionsStateFromQueryString(current_hash))?
          grid_control_mux.setActiveGridControlSectionsState(sections_state) 

        return

      $(window).on("hashchange", hashchange_cb)
      # Update search_comp grid on tab change
      Tracker.nonreactive =>
        $(window).trigger("hashchange") # trigger first change ourself

      Tracker.nonreactive =>
        Meteor.defer =>
          path_change_tracker = Tracker.autorun =>
            if not (current_mux_path = grid_control_mux.getPath())?
              # If the mux is in a state where no path is defined, do nothing

              return
            
            [tab_id, path] = current_mux_path

            new_hash = ""
            if tab_id?
              new_hash += "&t=#{tab_id}" # We don't begin with ?t... since we found ? triggers route rerender (!)

              if path?
                new_hash += "&p=#{path}"

            sections_state =
              grid_control_mux.getActiveGridControlSectionsState()

            if sections_state?
              for section_id, section_state of sections_state
                for var_name, var_value of section_state
                  new_hash += "&s_#{section_id}_#{var_name}=#{encodeURIComponent(var_value)}"

            if not _.isEmpty(new_hash)
              last_hash_change_triggered_by_us = new_hash
              window.location.hash = new_hash

      module.logger.debug "project_grid template rendered"

  Template.project_grid.destroyed = ->
    if hashchange_cb?
      $(window).off("hashchange", hashchange_cb)
      hashchange_cb = null

    if path_change_tracker?
      path_change_tracker.stop()
      path_change_tracker = null

    if active_grid_control_change_tracker?
      active_grid_control_change_tracker.stop()
      active_grid_control_change_tracker = null

    module.search_comp.destroy()

    module.logger.debug "grid control destroyed"
