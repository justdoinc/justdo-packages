first_grid_loaded = false
time_threshold_to_force_regard_as_user_action = 700
time_threshold_to_force_replacement = 300
time_threshold_to_allow_regarding_as_reactive_resource_response_to_back_button = 300

# We maintain the history_stack to be able to tell whether a hash change resulted
# from a press on the back button
history_stack = new JustdoHelpers.PointedLimitedStack({size: 50})

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
      # grid_control_mux.on "grid-control-created"; later on in this file
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

      project_custom_states_definitions_rv = new ReactiveVar {}
      project_removed_custom_states_definitions_rv = new ReactiveVar {}

      project_custom_states_definitions_rv_update_comp = null
      Tracker.nonreactive ->
        project_custom_states_definitions_rv_update_comp = Tracker.autorun ->
          project_id = module.curProj().id
          conf = APP.collections.Projects.findOne(project_id, {fields: {"conf.custom_states": 1, "conf.removed_custom_states": 1}})?.conf
          custom_states = conf?.custom_states or {}
          removed_custom_state = conf?.removed_custom_states or {}
          project_custom_states_definitions_rv.set(custom_states)
          project_removed_custom_states_definitions_rv.set(removed_custom_state)

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
        project_custom_states_definitions_rv_update_comp.stop()
        project_removed_custom_fields_definitions_rv_update_comp.stop()

        return

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
          expand_all_error_snackbar_on_action_click: -> window.open("https://support.justdo.com/hc/en-us/articles/115003548313-What-to-do-if-I-can-t-can-t-expend-all-tasks-")
          usersDiffConfirmationCb:
            ProjectPageDialogs.JustdoTaskMembersDiffDialog.usersDiffConfirmationCb
        use_shared_grid_control_custom_fields_manager: true
        shared_grid_control_custom_fields_manager_options:
          custom_fields_definitions: project_custom_fields_definitions_rv
          custom_states_definitions: project_custom_states_definitions_rv
          removed_custom_states_definitions: project_removed_custom_states_definitions_rv
        use_shared_grid_control_removed_custom_fields_manager: true
        shared_grid_control_removed_custom_fields_manager_options:
          custom_fields_definitions: project_removed_custom_fields_definitions_rv
      module.grid_control_mux.set grid_control_mux

      if not first_grid_loaded
        grid_control_mux.once "tab-ready", (tab) ->
          first_grid_loaded = true
          tab.grid_control._grid_data._grid_data_core.once "data-changes-queue-processed", ->
            time_to_load_first_grid_tab_since_js_parsing_started = (new Date() - window.js_started)
            console.info "[Project Page Module] Time to load first grid tab since js parsing started: #{time_to_load_first_grid_tab_since_js_parsing_started}ms"

          return

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
            existing_preferences.saved_grid_views[project_id][tab_id] = new_view
            existing_preferences = _.pick existing_preferences, "saved_grid_views" # Update only 'saved_grid_views' preference
            module.updatePreferences(existing_preferences)

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

      time_last_hash_updated_by_us = 0
      default_section_var_set_identified = false
      smart_guess_path_update_identified = false
      grid_control_mux.on "section-state-var-set", (tab, section_id, var_name, new_val, regard_as_default_value) ->
        # console.log "HERE SST-0 -- SST stands for Section State Var set as updated by the Grid Mux", {tab, section_id, var_name, new_val, regard_as_default_value}
        if regard_as_default_value
          # console.log "HERE SST-1", {tab, section_id, var_name, new_val, regard_as_default_value}
          default_section_var_set_identified = true
        else
          # console.log "HERE SST-2", {tab, section_id, var_name, new_val, regard_as_default_value}
        return

      grid_control_mux.on "row-activated", (tab, row, cell, scroll_into_view, resulted_from_smart_guess) ->
        # console.log "HERE RA-0 -- RA stands for Row Activate event emitted from the Grid Mux", {tab, row, cell, scroll_into_view, resulted_from_smart_guess}
        if resulted_from_smart_guess
          # console.log "HERE RA-1", {tab, row, cell, scroll_into_view, resulted_from_smart_guess}
          smart_guess_path_update_identified = true
        else
          # console.log "HERE RA-2", {tab, row, cell, scroll_into_view, resulted_from_smart_guess}
        return

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

      last_hashchange_cb_call = new Date()
      last_hash_change_triggered_by_us_value = null
      # We don't want hash changes triggered by us, only
      # to reflect to the user the current location on the
      # address bar to trigger hashchange procedures
      hashchange_cb = ->
        last_hashchange_cb_call = new Date()
        current_hash = window.location.hash

        if current_hash.charAt(0) == "#"
          current_hash = current_hash.substr(1)

        # console.log "HERE HC0 -- HC stands for Hash Change as reported by the browser $(window).on('hashchange')", {current_hash, last_hash_change_triggered_by_us_value}
        if current_hash == last_hash_change_triggered_by_us_value
          # console.log "HERE HC1 - IGNORE", {current_hash, last_hash_change_triggered_by_us_value}
          # Ignore hashchange triggered by us
          last_hash_change_triggered_by_us_value = null # if later on, the user will trigger the same change, we should let him

          return

        last_hash_change_triggered_by_us_value = null
        # console.log "HERE HC2 - PROCESS", {current_hash, last_hash_change_triggered_by_us_value}

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

            # We want to be able to indentify clicks on the back button (either simple clicks, or a click that goes many
            # pages back).
            #
            # When the user clicks back - the current_mux_path returned is out of date. We construct the browser_reported_hash
            # and match it against the history_stack to check for matching entries.
            #
            # This autorun, invalidates in two cases:
            # 1. grid_control_mux.getPath()
            # 2. grid_control_mux.getActiveGridControlSectionsState()
            #
            # Number 2 is going to be accurate, therefore we don't rely on the browser for it, and reconstruct it by ourself.
            # Number 1 is going to be in-accurate and therefore we take it from the browser.
            browser_reported_tab_id = /t=(.*?)(&|$)/.exec(window.location.hash)?[1]
            browser_reported_path = /p=(.*?)(&|$)/.exec(window.location.hash)?[1]
            browser_reported_hash = ""
            if browser_reported_tab_id?
              browser_reported_hash += "&t=#{browser_reported_tab_id}" # We don't begin with ?t... since we found ? triggers route rerender (!)

              if browser_reported_path?
                browser_reported_hash += "&p=#{browser_reported_path}"

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
                  browser_reported_hash += "&s_#{section_id}_#{var_name}=#{encodeURIComponent(var_value)}"

            update_type = "new" # options are either: "new", "replace", "ignore"
            time_since_last_hash_updated_by_us = JustdoHelpers.getDateTimestamp() - time_last_hash_updated_by_us
            time_since_last_hashchange_cb_call = JustdoHelpers.datesMsDiff(last_hashchange_cb_call)
            current_hash = window.location.hash.slice(1)
            hashes_are_same = current_hash.split("&").sort().join("&") == new_hash.split("&").sort().join("&")
            if not _.isEmpty(new_hash)
              # console.log "HERE RR0 -- RR stands for Reactive Resource update - here a computation that tracks reactive resources that potentially update the hash begins", {time_since_last_hash_updated_by_us, current_hash: current_hash, new_hash, browser_reported_hash, hashes_are_same: hashes_are_same, default_section_var_set_identified, history_stack: history_stack.getStack(), history_stack_head: history_stack.getStackHead(), time_since_last_hashchange_cb_call}

              if smart_guess_path_update_identified is true
                smart_guess_path_update_identified = false
                default_section_var_set_identified = false # Init default_section_var_set_identified as well, since if it is turned on, we anyway replace the hash here.

                # console.log "HERE RR1 Smart guess path update identified - Replace URL to the smart guessed one"
                update_type = "replace"
              else if default_section_var_set_identified is true
                default_section_var_set_identified = false
                if time_since_last_hash_updated_by_us > time_threshold_to_force_regard_as_user_action
                  # If more than time_threshold_to_force_regard_as_user_action passed, we regard it as a user action even if it seems like default_section_var_set_identified, and adding it to the stack without a replace (e.g changing between params of same tab; like the case of change between recent updates to recent completed)
                  if not hashes_are_same
                    # console.log "HERE RR2-1-0 time_threshold_to_force_regard_as_user_action PASSED - new"
                    update_type = "new"
                  else
                    # console.log "HERE RR2-1-1 time_threshold_to_force_regard_as_user_action PASSED - BUT SAME!!! - ignore"
                    update_type = "ignore"
                else
                  # console.log "HERE RR2-2 Url state replaced from: #{window.location.hash} to #{new_hash} - replace"
                  update_type = "replace"
              else if (not /&p=/.test(current_hash) and /&p=/.test(new_hash)) and new_hash.replace(/&p=[^&]*/, "") == current_hash
                # console.log "HERE RR3 Replace a url without path to a one with - replace"
                update_type = "replace"
              else
                if not hashes_are_same
                  if (time_since_last_hashchange_cb_call * -1) < time_threshold_to_allow_regarding_as_reactive_resource_response_to_back_button and history_stack.matchBackwardAndResetHeadIfFound(browser_reported_hash)
                    # console.log "HERE RR4-0 back button click identified, ignore.", {time_since_last_hashchange_cb_call}
                    update_type = "ignore"
                  else
                    if current_hash.trim() == ""
                      # console.log "HERE RR4-1 Simple new - BUT CHANGING FROM empty hash - REPLACE!"
                      update_type = "replace"
                    else
                      # console.log "HERE RR4-2 Simple new - new"
                      update_type = "new"
                else
                  # console.log "HERE RR4-3 attempt to set 2nd time the exact same hash - ignore"
                  update_type = "ignore"

              if time_since_last_hash_updated_by_us < time_threshold_to_force_replacement and update_type is "new"
                # console.log "HERE RR5 too short time since last hash updated by us, replace existing hash with new"
                update_type = "replace"

              if update_type == "new"
                # console.log "HERE RR6-0 REQUEST ADD NEW HASH: #{new_hash}"

                window.location.hash = new_hash
                history_stack.push(new_hash)
              else if update_type == "replace"
                # console.log "HERE RR6-1 REQUEST REPLACE HASH UPDATE: #{new_hash}"

                history.replaceState(null, "", "##{new_hash}")
                history_stack.replaceHead(new_hash)
              else if update_type == "ignore"
                # console.log "HERE RR6-2 IGNORE STATE UPDATE - DONT UPDATE HASH"
                0 # Just to do nothing but still keep the else/if structure when the console.log is commented out.
              else
                console.error "Uknown update_type: #{update_type}"

              # console.log "HERE RR7 New History Stack", history_stack.getStack().join("\n")
              # console.log "HERE RR7 HEAD IS: #{history_stack.getStackHead()}"

              last_hash_change_triggered_by_us_value = new_hash
              if update_type != "ignore"
                # We don't update the time if update_type is "ignore", since the hash didn't really
                # change, we do update the last_hash_change_triggered_by_us_value since we don't want
                # potential follow-up hashchange_cb call (in case it was triggered by back/forward button)
                # to treat it as a new hash.
                time_last_hash_updated_by_us = JustdoHelpers.getDateTimestamp()

            return

          return

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
