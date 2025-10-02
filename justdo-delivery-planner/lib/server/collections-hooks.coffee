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

    # Changelog tracking for project and projects collection changes
    self.tasks_collection.after.update (userId, doc, fieldNames, modifier, options) ->
      if not modifier.$set?
        return
      
      # Get the performing user from the modifier
      performed_by = modifier.$set.updated_by
      if not performed_by?
        # Skip logging if we can't determine who made the change
        return
      
      task_id = doc._id
      previous_doc = @previous
      
      # Track task marked/unmarked as project
      if self._isProjectStatusUpdatedInModifier(modifier)
        is_now_project = modifier.$set[JustdoDeliveryPlanner.task_is_project_field_name]
        old_value = previous_doc[JustdoDeliveryPlanner.task_is_project_field_name]
        
        if self._hasProjectStatusChanged(old_value, is_now_project)
          self._logProjectStatusChange(task_id, performed_by, is_now_project)
      
      # Track project closed/reopened
      if self._isProjectBeingClosedOrReopenedInModifier(modifier)
        is_now_closed = modifier.$set[JustdoDeliveryPlanner.task_is_archived_project_field_name]
        was_closed = previous_doc[JustdoDeliveryPlanner.task_is_archived_project_field_name]
        
        if self._hasProjectStatusChanged(was_closed, is_now_closed)
          self._logProjectClosedOrReopenedChange(task_id, performed_by, is_now_closed)
      
      # Track projects collection type set
      if self._isProjectsCollectionTypeBeingSetInModifier(modifier)
        new_type = modifier.$set["projects_collection.projects_collection_type"]
        old_type = previous_doc.projects_collection?.projects_collection_type
        
        if self._hasProjectStatusChanged(old_type, new_type)
          self._logProjectsCollectionTypeToggleChange(task_id, performed_by, true, new_type)
      
      # Track projects collection type unset
      if self._isProjectsCollectionBeingUnsetInModifier(modifier, previous_doc)
        old_type = previous_doc.projects_collection.projects_collection_type
        self._logProjectsCollectionTypeToggleChange(task_id, performed_by, false, old_type)
      
      # Track projects collection closed/reopened
      if self._isProjectsCollectionBeingClosedOrReopenedInModifier(modifier)
        is_now_closed = modifier.$set["projects_collection.is_closed"]
        was_closed = previous_doc.projects_collection?.is_closed
        
        if self._hasProjectStatusChanged(was_closed, is_now_closed)
          collection_type = doc.projects_collection?.projects_collection_type or previous_doc.projects_collection?.projects_collection_type
          self._logProjectsCollectionClosedOrReopenedChange(task_id, performed_by, is_now_closed, collection_type)
      
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

  # Changelog tracking helper methods
  _hasProjectStatusChanged: (old_value, new_value) ->
    # Returns true if the project status actually changed
    return old_value isnt new_value
  
  _isProjectStatusUpdatedInModifier: (modifier) ->
    # Returns true if the modifier is changing the is_project field
    return modifier.$set?[JustdoDeliveryPlanner.task_is_project_field_name]?
  
  _isProjectsCollectionTypeBeingSetInModifier: (modifier) ->
    # Returns true if the modifier is setting a projects collection type
    return modifier.$set?["projects_collection.projects_collection_type"]?
  
  _isProjectsCollectionBeingUnsetInModifier: (modifier, previous_doc) ->
    # Returns true if the modifier is unsetting the projects collection (setting to empty object)
    is_being_emptied = modifier.$set?.projects_collection? and _.isEmpty(modifier.$set.projects_collection)
    had_type_previously = previous_doc?.projects_collection?.projects_collection_type?
    
    return is_being_emptied and had_type_previously
  
  _isProjectsCollectionBeingClosedOrReopenedInModifier: (modifier) ->
    # Returns true if the modifier is changing the is_closed field of projects collection
    return modifier.$set?["projects_collection.is_closed"]?
  
  _isProjectBeingClosedOrReopenedInModifier: (modifier) ->
    # Returns true if the modifier is changing the archived project status
    
    task_is_project_field_name = JustdoDeliveryPlanner.task_is_project_field_name
    task_is_project_modifier_val = modifier.$set?[task_is_project_field_name]
    task_is_archived_project_field_name = JustdoDeliveryPlanner.task_is_archived_project_field_name
    task_is_archived_project_modifier_val = modifier.$set?[task_is_archived_project_field_name]
    # When unsetting a task as project, `task_is_archived_project_field_name` will also be set to false regardless of the previous value
    # As such, if both `task_is_project_field_name` and `task_is_archived_project_field_name` is set to false,
    # we don't consider it as being closed or reopened.
    is_unsetting_as_project = (task_is_project_modifier_val is false) and (task_is_archived_project_modifier_val is false)
    if is_unsetting_as_project
      return false

    return task_is_archived_project_modifier_val?
  
  _logProjectStatusChange: (task_id, performed_by, is_now_project) ->
    APP.tasks_changelog_manager.logChange
      field: JustdoDeliveryPlanner.task_is_project_field_name
      label: "Project"
      change_type: "custom"
      task_id: task_id
      by: performed_by
      new_value: "#{if is_now_project then "set" else "unset"} this Task as Project"
    
    return
  
  _getProjectsCollectionTypeLabelInDefaultLang: (type_id) ->
    type_def = @getProjectsCollectionTypeById(type_id)
    type_label = type_def?.type_label_i18n or type_id
    type_label = TAPi18n.__ type_label, {}, JustdoI18n.default_lang
    return type_label
  
  _logProjectsCollectionTypeToggleChange: (task_id, performed_by, is_now_set, type_id) ->
    type_label = @_getProjectsCollectionTypeLabelInDefaultLang(type_id)
    
    APP.tasks_changelog_manager.logChange
      field: "projects_collection.projects_collection_type"
      label: "Projects Collection"
      change_type: "custom"
      task_id: task_id
      by: performed_by
      new_value: "#{if is_now_set then "set" else "unset"} this Task as #{type_label}"
    
    return
  
  _logProjectsCollectionClosedOrReopenedChange: (task_id, performed_by, is_now_closed, collection_type) ->
    type_label = @_getProjectsCollectionTypeLabelInDefaultLang(collection_type)
    
    APP.tasks_changelog_manager.logChange
      field: "projects_collection.is_closed"
      label: "Projects Collection"
      change_type: "custom"
      task_id: task_id
      by: performed_by
      new_value: "#{if is_now_closed then "closed" else "reopened"} this #{type_label}"
    
    return
  
  _logProjectClosedOrReopenedChange: (task_id, performed_by, is_now_closed) ->
    APP.tasks_changelog_manager.logChange
      field: JustdoDeliveryPlanner.task_is_archived_project_field_name
      label: "Project"
      change_type: "custom"
      task_id: task_id
      by: performed_by
      new_value: "#{if is_now_closed then "closed" else "reopened"} this Project"
    
    return

