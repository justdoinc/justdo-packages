_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # 1. Auto close/open Projects when a task is being archived
      # 2. Unarchive when open Projects
      if not modifier.$set?
        return

      if (not _.has(modifier.$set, "archived") and not _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name)) or
          (_.has(modifier.$set, "archived") and _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name))
        return
      
      if  _.has(modifier.$set, "archived")
        if (modifier.$set.archived? and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] != true) or
            (modifier.$set.archived == null and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] == true)
          modifier.$set[JustdoDeliveryPlanner.task_is_archived_project_field_name] = not doc[JustdoDeliveryPlanner.task_is_archived_project_field_name]
      else if _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name)
        if modifier.$set[JustdoDeliveryPlanner.task_is_archived_project_field_name] == false and doc.archived?
          modifier.$set.archived = null

      return

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # 1. Auto close/open Projects Collections when a task is being archived
      # 2. Unarchive when open Projects Collections
      if not modifier.$set?
        return

      is_task_projects_collection = self.getTaskObjProjectsCollectionTypeId(doc)?
      if not is_task_projects_collection
        return
      
      is_task_being_archived_or_unarchived = _.has modifier.$set, "archived"
      is_task_being_closed_or_reopened_as_projects_collection = _.has modifier.$set, "projects_collection.is_closed"

      if ((not is_task_being_archived_or_unarchived) and not (is_task_being_closed_or_reopened_as_projects_collection)) or
          (is_task_being_archived_or_unarchived and is_task_being_closed_or_reopened_as_projects_collection)
        return
      
      is_task_archived = doc.archived?
      is_task_being_archived = modifier.$set.archived?
      is_task_being_closed_as_projects_collection = modifier.$set["projects_collection.is_closed"]
      is_task_closed_projects_collection = doc.projects_collection.is_closed
      
      if is_task_being_archived_or_unarchived
        if (is_task_being_archived and not is_task_closed_projects_collection) or
            (not is_task_being_archived and is_task_closed_projects_collection)
          modifier.$set["projects_collection.is_closed"] = not is_task_closed_projects_collection 
      else if is_task_being_closed_or_reopened_as_projects_collection
        if not is_task_being_closed_as_projects_collection and is_task_archived
          modifier.$set.archived = null      

      return
    
    setTaskAsProjectIfNewParentIsProjectsCollection = (doc, modifier) ->
      is_task_project = self.isTaskObjProject doc
      is_task_projects_collection = self.getTaskObjProjectsCollectionTypeId(doc)?
      if is_task_project or is_task_projects_collection
        return

      parents2 = modifier.$addToSet?.parents2 or modifier.$set?.parents2
      parents2_modified = parents2?
      if not parents2_modified
        return

      if not self.isProjectsCollectionEnabled(doc.project_id)
        return

      parent_task_ids = if _.isArray(parents2) then _.map(parents2, (parent) -> parent.parent) else [parents2.parent]

      any_of_parents_is_projects_collection_query = 
        _id: 
          $in: parent_task_ids
        "projects_collection.projects_collection_type": 
          $ne: null
      any_of_parents_is_projects_collection_query_options = 
        limit: 1

      # If any of the parents is a projects collection, then set the task as project
      if self.tasks_collection.find(any_of_parents_is_projects_collection_query, any_of_parents_is_projects_collection_query_options).count() > 0
        modifier.$set[JustdoDeliveryPlanner.task_is_project_field_name] = true

      return
    
    self.tasks_collection.before.upsert (user_id, selector, modifier, options) ->
      # Auto set new child task of projects collection as project
      setTaskAsProjectIfNewParentIsProjectsCollection modifier.$set, modifier

      return

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # Auto set child task of projects collection as project
      setTaskAsProjectIfNewParentIsProjectsCollection doc, modifier
        
      return

    self.tasks_collection.after.update (user_id, doc, field_names, modifier, options) ->
      # Auto close projects that are set from non-terminal to terminal states,
      # and reopen projects that are set from terminal to non-terminal states
      if not self.isTaskObjProject doc
        # Task is not a project
        return
      
      previous_state = @previous.state
      if not (current_state = modifier.$set?.state)?
        # State field not involved in the update
        return

      is_previous_state_terminal = JustdoHelpers.isTerminalState(previous_state)
      is_current_state_terminal = JustdoHelpers.isTerminalState(current_state)
      if is_previous_state_terminal is is_current_state_terminal
        # State not changed, no need to update
        return

      if (is_previous_state_terminal and (not is_current_state_terminal)) and self.isTaskObjArchivedProject(doc)
        # Task is being set to a non-terminal state, so we need to unarchive the project
        self.tasks_collection.update doc._id, {$set: [JustdoDeliveryPlanner.task_is_archived_project_field_name]: false}
      else if ((not is_previous_state_terminal) and is_current_state_terminal) and not self.isTaskObjArchivedProject(doc)
        # Task is being set to a terminal state, so we need to archive the project
        self.tasks_collection.update doc._id, {$set: [JustdoDeliveryPlanner.task_is_archived_project_field_name]: true}

      return

    JustdoHelpers.hooks_barriers.markBarrierAsResolved "post-jdp-collections-hooks-setup"

    return
