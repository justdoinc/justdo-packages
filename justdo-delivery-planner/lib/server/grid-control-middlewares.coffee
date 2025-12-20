_.extend JustdoDeliveryPlanner.prototype,
  _setupGridControlMiddlewares: ->
    self = @

    # Helper to get the projects_collection field for a task
    # Some middlewares receive limited fields in etc.item (beforeMovePath, beforeRemoveParent)
    # while others receive the full document (addParent).
    # This helper fetches only when needed.
    getProjectsCollectionField = (item_id) ->
      return self.tasks_collection.findOne({_id: item_id}, {fields: {projects_collection: 1}})

    # Validate Project Collection type constraints when moving a task to a new parent
    # Note: beforeMovePath's etc.item has LIMITED fields (_id, parents, parents2, project_id only)
    APP.projects._grid_data_com.setGridMethodMiddleware "beforeMovePath", (path, perform_as, etc) ->
      console.log "beforeMovePath", path, perform_as, etc
      # etc.item has limited fields, need to fetch projects_collection separately
      pc_doc = getProjectsCollectionField(etc.item._id)
      if not pc_doc?
        return true
      
      # Only validate if the item is a Project Collection
      pc_type_id = self.getTaskObjProjectsCollectionTypeId(pc_doc)
      if not pc_type_id?
        return true
      
      # Get the new parent ID
      new_parent_id = etc.new_location?.parent
      
      # Build a mock task object with the new parent structure to validate
      # We need to simulate what the task would look like after the move
      new_parents = {}
      if new_parent_id? and new_parent_id isnt "0"
        new_parents[new_parent_id] = {}
      
      mock_task = 
        _id: etc.item._id
        parents: new_parents
      
      validation_result = self.validateProjectsCollectionTypeForTask(mock_task, pc_type_id)
      
      if not validation_result.valid
        error_message = TAPi18n.__ validation_result.error_i18n, validation_result.error_options or {}
        throw self._error "invalid-move", error_message
      
      return true

    # Validate Project Collection type constraints when adding a new parent
    # Note: addParent's etc.item is fetched via getItemByIdIfUserBelong which returns FULL document
    APP.projects._grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) ->
      # etc.item already has full document including projects_collection - no extra query needed!
      item = etc.item
      if not item?
        return true
      
      # Only validate if the item is a Project Collection  
      pc_type_id = self.getTaskObjProjectsCollectionTypeId(item)
      if not pc_type_id?
        return true
      
      # Get the new parent ID being added
      new_parent_id = etc.new_parent?.parent
      
      # Build a mock task with both existing parents AND the new parent
      new_parents = _.clone(item.parents) or {}
      if new_parent_id? and new_parent_id isnt "0"
        new_parents[new_parent_id] = {}
      
      mock_task = 
        _id: item._id
        parents: new_parents
      
      validation_result = self.validateProjectsCollectionTypeForTask(mock_task, pc_type_id)
      
      if not validation_result.valid
        error_message = TAPi18n.__ validation_result.error_i18n, validation_result.error_options or {}
        throw self._error "invalid-parent", error_message
      
      return true

    # Validate Project Collection type constraints when removing a parent
    # This prevents removing a parent that would leave the PC in an invalid state
    # Note: beforeRemoveParent's etc.item has LIMITED fields (_id, parents, parents2, project_id only)
    APP.projects._grid_data_com.setGridMethodMiddleware "beforeRemoveParent", (path, perform_as, etc) ->
      # etc.item has limited fields, need to fetch projects_collection separately
      pc_doc = getProjectsCollectionField(etc.item._id)
      if not pc_doc?
        return true
      
      # Only validate if the item is a Project Collection
      pc_type_id = self.getTaskObjProjectsCollectionTypeId(pc_doc)
      if not pc_type_id?
        return true
      
      # Get the parent being removed from the path
      # Path format is like "/parent_id/task_id/"
      path_parts = path.split("/").filter((p) -> p.length > 0)
      if path_parts.length < 2
        return true
      
      parent_being_removed = path_parts[0]
      
      # Build a mock task without the parent being removed
      # Note: etc.item.parents IS available (it's one of the limited fields fetched)
      new_parents = {}
      for parent_id, parent_def of (etc.item.parents or {})
        if parent_id isnt parent_being_removed and parent_id isnt "0"
          new_parents[parent_id] = parent_def
      
      mock_task = 
        _id: etc.item._id
        parents: new_parents
      
      validation_result = self.validateProjectsCollectionTypeForTask(mock_task, pc_type_id)
      
      if not validation_result.valid
        error_message = TAPi18n.__ validation_result.error_i18n, validation_result.error_options or {}
        throw self._error "invalid-parent-removal", error_message
      
      return true

    # Validate when creating a new task with Project Collection type set
    APP.projects._grid_data_com.setGridMethodMiddleware "addChild", (path, new_item, perform_as, etc) ->
      # Check if new item is being created as a Project Collection
      pc_type_id = new_item?.projects_collection?.projects_collection_type
      if not pc_type_id?
        return true
      
      # Get the parent ID from the path
      # Path format is like "/parent_id/" or "/"
      path_parts = path.split("/").filter((p) -> p.length > 0)
      parent_id = if path_parts.length > 0 then path_parts[path_parts.length - 1] else null
      
      # Build a mock task to validate
      mock_parents = {}
      if parent_id? and parent_id isnt "0"
        mock_parents[parent_id] = {}
      
      mock_task = 
        _id: "new_task"
        parents: mock_parents
      
      validation_result = self.validateProjectsCollectionTypeForTask(mock_task, pc_type_id)
      
      if not validation_result.valid
        error_message = TAPi18n.__ validation_result.error_i18n, validation_result.error_options or {}
        throw self._error "invalid-parent-type", error_message
      
      return true

    return
