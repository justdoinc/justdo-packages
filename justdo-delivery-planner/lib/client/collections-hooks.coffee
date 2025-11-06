_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.after.update (user_id, doc, field_names, modifier, options) ->
      # When tasks are set to terminal states, check whether
      #   1. it's under a project
      #   2. the project is not in a terminal state
      #   3. after the update, all tasks under the project are set to terminal states
      # If so, set the project to done

      if not (current_state = modifier.$set?.state)?
        # State field not involved in the update
        return

      if not JustdoHelpers.isTerminalState(current_state)
        # Task is not set to a terminal state
        return
      
      if not (grid_data = APP.modules.project_page?.mainGridData())?
        # Grid data not available. We need it to traverse the ancestor paths.
        return
      
      if _.isEmpty(task_anceestor_projects = self.getAncestorProjectsOfTask doc._id)
        # Task is not under any projects
        # Note that this check is more expensive since it traverses all the paths of the current task,
        # so other less-expensive checks should be performed first.
        return

      ancestor_projects_to_set_to_done = []
      for path, path_projects_obj of task_anceestor_projects
        # filter out projects that are already in terminal states
        path_projects_obj.projects = _.filter path_projects_obj.projects, (project) ->
          return not JustdoHelpers.isTerminalState(project.state)
        
        if _.isEmpty(path_projects_obj.projects)
          # No projects left after filtering out projects that are already in terminal states
          continue
        
        # Here we start traversing the project subtree to see of all other tasks under the project are set to terminal states.
        # 
        # In `task_anceestor_projects`, all the projects within the same path is grouped into `path_projects_obj.projects`,
        # where the first project is the closest project to the current task.
        # Thus, after filtering out projects that are already in terminal states,
        # we only need to traverse the first project, since 
        # 1. `projects[0]` is a child of `projects[1]`, and
        # 2. we already know `projects[0]` is not in a terminal state.
        # 3. after setting `projects[0]` to done, this hook will be triggered again for `projects[1]`

        # Prepare the path to traverse using `grid_data.each()`
        path_arr = GridData.helpers.getPathArray path
        project_to_traverse = path_projects_obj.projects[0]
        project_id_to_traverse = project_to_traverse._id
        index_of_project_id_in_path_arr = _.indexOf path_arr, project_id_to_traverse
        if index_of_project_id_in_path_arr is -1
          # Project ID not found in path array. This should not happen.
          continue
        
        path_arr = path_arr.slice(0, index_of_project_id_in_path_arr + 1)
        path_to_traverse = GridData.helpers.joinPathArray path_arr

        # Traverse the project subtree to see of all other tasks under the project are set to terminal states.
        is_all_tasks_in_terminal_states = true
        grid_data.each path_to_traverse, (section, item_type, item_obj, path, expand_state) ->
          if item_obj._id is doc._id
            # We know for sure that the current task is in Terminal state since we check it in a statement
            # earlier. Yet, since the hook might (always?) happens before the processing of the grid-data flushing mechansim
            # hence it might be not synced with the current data.
            return
          
          if not JustdoHelpers.isTerminalState(item_obj.state)
            is_all_tasks_in_terminal_states = false
            return -2 # stop traversing immediately
        
        if is_all_tasks_in_terminal_states
          # All tasks under the project are set to terminal states
          ancestor_projects_to_set_to_done.push project_to_traverse
      
      if _.isEmpty ancestor_projects_to_set_to_done
        return
      
      ancestor_projects_to_set_to_done = _.uniq ancestor_projects_to_set_to_done, (project) ->
        return project._id

      # If `ancestor_projects_to_set_to_done` is not empty, show a snackbar to ask whether to set the ancestor projects to done
      count = _.size ancestor_projects_to_set_to_done
      i18n_options = 
        count: count

      if count is 1
        # If there is only one project to set to done, use the project title
        project_doc = ancestor_projects_to_set_to_done[0]
        project_seq_id = project_doc.seqId
        project_title = project_doc.title
        title_for_display = "##{project_seq_id}"
        if not _.isEmpty project_title
          title_for_display += ": #{project_title}"
        i18n_options.title = title_for_display
        i18n_options.task_url = JustdoHelpers.getTaskUrl(project_doc.project_id, project_doc._id)
      
      snackbar = JustdoSnackbar.show
        text: TAPi18n.__ "set_ancestor_project_to_done_snackbar_text", i18n_options
        actionText: TAPi18n.__ "yes"
        showDismissButton: true
        onActionClick: =>
          for project in ancestor_projects_to_set_to_done
            self.tasks_collection.update project._id, {$set: {state: "done"}}

          snackbar.close()
          return
          
      if count is 1
        snackbar.querySelector(".task-link").addEventListener "click", (e) =>
          e.preventDefault()
          e.stopPropagation()

          if (gcm = APP.modules.project_page.getCurrentGcm())?
            gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(project_doc._id)

          return

      return

    return