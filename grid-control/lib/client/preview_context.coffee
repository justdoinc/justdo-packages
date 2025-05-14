_.extend PACK.Plugins,
  preview_context:
    init: ->
      # Defined below
      @_installGcRowsMetadataGenerator()
      @_setupPreviewContextNullaryOperations()

      return
    
    destroy: ->
      @preview_context?.destroy()
      @preview_context = null
      
      @_uninstallGcRowsMetadataGenerator()
      return

PreviewContext = (options) ->
  @constructor_name_dash_seperated = "grid-control-preview-context"

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get(@constructor_name_dash_seperated)
  @JA = JustdoAnalytics.setupConstructorJA(@, @constructor_name_dash_seperated)

  @options = _.extend {}, @default_options, options
  if not _.isEmpty(@options_schema)
    # If @options_schema is set, use it to apply strict structure on
    # @options.
    #
    # Clean and validate @options according to @options_schema.
    # invalid-options error will be thrown for invalid options.
    # Takes care of binding options with bind_to_instance to
    # the instance.
    @options =
      JustdoHelpers.loadOptionsWithSchema(
        @options_schema, @options, {
          self: @
          additional_schema: # Adds the `events' option to the permitted fields
            events:
              type: Object
              blackbox: true
              optional: true
        }
      )

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  @_on_destroy_procedures = []

  # React to invalidations
  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @logger.debug "Enclosing computation invalidated, destroying"
      @destroy() # defined in client/api.coffee

  # on the client, call @_immediateInit() in an isolated
  # computation to avoid our init procedures from affecting
  # the encapsulating computation (if any)
  Tracker.nonreactive =>
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  return @

Util.inherits PreviewContext, EventEmitter

_.extend PreviewContext.prototype,
  _error: JustdoHelpers.constructor_error
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "destroyed": "This PreviewContext is destroyed"

  options_schema:
    both:
      grid_control:
        type: "skip-type-check"
      project_id:
        type: String
      auto_expand_ancestors: 
        type: Boolean
        optional: true
        defaultValue: true
  
  default_new_task_doc:
    title: ""
    seqId: "#"
    priority: 0
    owner_id: Meteor.userId()
  
  _immediateInit: ->
    @grid_control = @options.grid_control
    @grid_data = @grid_control._grid_data

    @tasks_collection = APP.collections.Tasks
    @projects_collection = APP.collections.Projects
    @project_id = @options.project_id

    @pc_id = Random.id()
    @order_inc_step = 1

    @commit_in_progress = false

    # For creating tasks level by level: We create the tasks using bulkAddChild for pc tasks with a real parent first,
    # then create their pc childrens.
    @real_parents_with_pc_child_set = new Set()

    @items_to_expand = []

    @paths_for_undoing_commit = []
    @is_commit_finished_called = false

    return
  
  _deferredInit: ->
    return
  
  _activateItemOnceTreeChanged: (task_id) ->
    @grid_control.once "tree_change", =>
      Meteor.defer => @grid_control.activateCollectionItemId task_id
      return
    return

  _ensurePcIdInDoc: (doc) ->
    doc.pc_id = @pc_id
    return doc

  _createTaskInLocalMinimongo: (path, task_doc, options) ->
    @_requireNotDestroyed()

    default_options = 
      auto_expand_ancestors: @options.auto_expand_ancestors
    options = _.extend {}, default_options, options

    # Apply default task values
    task_doc = _.extend {}, @default_new_task_doc, task_doc

    if task_doc.parents["0"]?
      APP.justdo_permissions?.requireJustdoPermissions "grid-structure.add-remove-sort-root-tasks", @project_id, Meteor.userId()
    else
      parent_id = _.keys(task_doc.parents)[0]
      APP.justdo_permissions?.requireTaskPermissions "grid-structure.add-remove-sort-children", parent_id, Meteor.userId()

    task_doc.project_id = @project_id
    if not task_doc._id?
      task_doc._id = Random.id()
    task_doc.pc_task_id = task_doc._id
    @_ensurePcIdInDoc task_doc

    created_task_id = @tasks_collection._collection.insert task_doc
    
    @_markRealParentsWithPcChild path
      
    if options.auto_expand_ancestors
      @_activateItemOnceTreeChanged created_task_id

    return created_task_id

  _getNewChildOrder: (parent_id) ->
    query = 
      project_id: @project_id
      "parents.#{parent_id}":
        $ne: null
    query_options = 
      sort: 
        "parents.#{parent_id}.order": -1
        
    last_child = @tasks_collection.findOne query, query_options

    new_order = (last_child?.parents?[parent_id]?.order + @order_inc_step) or 0

    return new_order
  
  _getNewSiblingOrder: (parent_id, task_id) ->
    query = 
      project_id: @project_id
      "parents.#{parent_id}":
        $ne: null
    if task_id?
      query._id = task_id
    query_options = 
      fields:
        "parents.#{parent_id}.order": 1
        
    return @tasks_collection.findOne(query, query_options)?.parents?[parent_id]?.order + @order_inc_step
  
  _isTaskCreatedFromThisPc: (task_doc) ->
    return task_doc.pc_id is @pc_id
  
  _isTaskUncommittedPcTask: (task_doc) ->
    return task_doc._id is task_doc.pc_task_id
  
  _markRealParentsWithPcChild: (path) ->
    is_root_path = (not path?) or (GridData.helpers.isRootPath path)

    if is_root_path
      parent_id = "0"
    else
      parent_id = GridData.helpers.getPathItemId path

      parent_task_doc = @tasks_collection.findOne parent_id, {fields: {pc_task_id: 1}}
      is_parent_real_task = not @_isTaskUncommittedPcTask parent_task_doc

    if is_root_path or is_parent_real_task 
      @real_parents_with_pc_child_set.add parent_id
    
    return

  addChild: (path, fields) ->
    @_requireNotDestroyed()

    if not path?
      throw @_error "not-supported", "Cannot add child without an active path"

    if GridData.helpers.isRootPath(path)
      parent_id = "0"
    else
      parent_id = GridData.helpers.getPathItemId(path)

    fields = _.extend {}, fields
    fields.parents = 
      [parent_id]:
        order: @_getNewChildOrder parent_id
    
    return @_createTaskInLocalMinimongo path, fields

  bulkAddChild: (path, childs_fields) ->    
    if (_.isObject(childs_fields)) and (not _.isArray(childs_fields))
      childs_fields = [childs_fields]
    
    if _.isEmpty childs_fields
      return
    
    created_task_ids = []
    
    for child_fields in childs_fields
      created_task_ids.push @addChild path, child_fields
    
    return created_task_ids

  addSibling: (path, fields) ->
    @_requireNotDestroyed()

    parent_id = GridData.helpers.getPathParentId path

    fields = _.extend {}, fields
    fields.parents = 
      [parent_id]:
        order: @_getNewSiblingOrder(parent_id, JD.activeItemId())
    
    # Increment the order of all siblings with order >= the new sibling's order
    @_incrementChildsOrderGte parent_id, fields.parents[parent_id].order

    if not GridData.helpers.isRootPath path
      path = GridData.helpers.getParentPath path

    return @_createTaskInLocalMinimongo path, fields
  
  bulkAddSibling: (path, siblings_fields) ->    
    if (_.isObject(siblings_fields)) and (not _.isArray(siblings_fields))
      siblings_fields = [siblings_fields]
    
    if _.isEmpty siblings_fields
      return
    
    created_task_ids = []
    
    for sibling_fields in siblings_fields
      created_task_ids.push @addSibling path, sibling_fields
    
    return created_task_ids

  removeTasks: (pc_task_ids) ->
    @_requireNotDestroyed()

    if _.isString pc_task_ids
      pc_task_ids = [pc_task_ids]
    
    if _.isEmpty pc_task_ids
      return
    
    pc_task_ids_to_remove = []
    
    for pc_task_id in pc_task_ids
      pc_task_ids_to_remove.push pc_task_id
      # Remove entire subtree if task has subtasks
      @grid_data.each "/#{pc_task_id}/", {}, (section, item_type, item_obj, path) -> pc_task_ids_to_remove.push item_obj._id

    pc_task_ids_to_remove = _.uniq pc_task_ids_to_remove
    query = 
      _id:
        $in: pc_task_ids_to_remove

    @_ensurePcIdInDoc query
    # Remove pc tasks from minimongo
    @tasks_collection._collection.remove query

    # Remove parent_id from @real_parents_with_pc_child_set, if exists.
    @tasks_collection.find(query, {fields: {parents: 1}}).forEach (task_doc) => 
      @real_parents_with_pc_child_set.delete _.keys(task_doc.parents)[0]
      return

    return

  _removeClientOnlyFields: (task_doc) ->
    fields = _.keys task_doc
    {regular, client_only} = JustdoHelpers.getFieldsByUpdateType @tasks_collection, fields
    return _.pick task_doc, ...regular

  _removePreviewOnlyFields: (task_doc) ->
    @_requireNotDestroyed()

    delete task_doc._id
    return @_removeClientOnlyFields task_doc

  _setCommitInProgress: ->
    @commit_in_progress = true

  _unsetCommitInProgress: ->
    @commit_in_progress = false
  
  isCommitInProgress: ->
    return @commit_in_progress

  commit: ->
    @_requireNotDestroyed()

    if @isCommitInProgress()
      return

    @_setCommitInProgress()

    error_occured = false

    removePreviewTasks = (created_task_ids) =>
      query = 
        _id:
          $in: created_task_ids
      @_ensurePcIdInDoc query
      query_options = 
        fields:
          pc_task_id: 1
      pc_task_ids_to_remove = @tasks_collection.find(query, query_options).map (task_doc) -> task_doc.pc_task_id

      remove_query = 
        pc_task_id:
          $in: pc_task_ids_to_remove
        _id:
          $nin: created_task_ids
      @tasks_collection._collection.remove remove_query

      return

    all_created_task_id_and_pc_task_id_pairs = []
    recursiveBulkCreateTasks = (parent_id, tasks) =>
      if parent_id is "0"
        path = "/"
      else
        path = "/#{parent_id}/"
      
      # Seperate real tasks from uncommitted pc tasks.
      # For tasks that are real, we simply have to add their parents.
      tasks_to_add_parent = _.filter tasks, (task) => not @_isTaskUncommittedPcTask task
      # For tasks that are uncommitted pc tasks, we have to create them.
      tasks_to_create = _.filter tasks, (task) => @_isTaskUncommittedPcTask task

      for task_to_add_parent in tasks_to_add_parent
        order = task_to_add_parent.parents[parent_id].order
        @grid_data.addParent task_to_add_parent._id, {parent: parent_id, order}, (err, res) => console.log {err, res}

      tasks_to_create = tasks_to_create.map (task) => @_removePreviewOnlyFields task
      @grid_data.bulkAddChild path, tasks_to_create, (err, res) =>
        if err?
          @logger.error "Create tasks from preview failed",  err
          error_occured = true
          # If error occured, we'll remove all the created tasks
          @_commitFailed()
          return
        
        # This is for subsequent bulkAddChild calls, to make sure all the tasks created are removed and to prevent further calls.
        if error_occured
          @_commitFailed()
          return

        created_task_ids = []
        created_task_paths_by_id = {}

        for [created_task_id, created_task_path] in res
          created_task_ids.push created_task_id
          created_task_paths_by_id[created_task_id] = created_task_path

        removePreviewTasks created_task_ids
        @items_to_expand = @items_to_expand.concat created_task_ids

        query = 
          _id:
            $in: created_task_ids
        @_ensurePcIdInDoc query
        created_tasks_cursor = @tasks_collection.find(query, {fields: {pc_task_id: 1, parents: 1}})

        created_task_id_and_pc_task_id_pairs = created_tasks_cursor.map (task_doc) -> {created_task_id: task_doc._id, pc_task_id: task_doc.pc_task_id}
        all_created_task_id_and_pc_task_id_pairs = all_created_task_id_and_pc_task_id_pairs.concat created_task_id_and_pc_task_id_pairs

        # Handle order discrepency and multi-parent
        created_tasks_cursor.forEach (created_task) =>
          corresponding_pc_task = _.find tasks, (pc_task) -> pc_task.pc_task_id is created_task.pc_task_id
          created_task_order = created_task.parents[parent_id].order
          pc_task_order = corresponding_pc_task.parents[parent_id].order
          is_order_the_same = created_task_order is pc_task_order
          remaining_parents_to_add = _.omit corresponding_pc_task.parents, parent_id

          if not is_order_the_same
            created_task_path = created_task_paths_by_id[created_task._id]
            @grid_data.movePath created_task_path, {parent: parent_id, order: pc_task_order}, (err, res) -> console.log {err, res}
          
          for parent_id, {order} of remaining_parents_to_add
            parent_id = _.find(all_created_task_id_and_pc_task_id_pairs, (pair) -> pair.pc_task_id is parent_id)?.created_task_id
            @grid_data.addParent created_task._id, {parent: parent_id, order}, (err, res) -> console.log {err, res}

        for created_tasks_id_pair in created_task_id_and_pc_task_id_pairs
          subtasks_query = 
            "parents.#{created_tasks_id_pair.pc_task_id}":
              $ne: null
          @_ensurePcIdInDoc subtasks_query

          subtasks_cursor = @tasks_collection.find(subtasks_query)
          if subtasks_cursor.count() > 0
            subtasks = subtasks_cursor.map (task_doc) => 
              # Update the parent id to the created task id
              task_doc.parents[created_tasks_id_pair.created_task_id] = task_doc.parents[created_tasks_id_pair.pc_task_id]
              delete task_doc.parents[created_tasks_id_pair.pc_task_id]

              return task_doc

            recursiveBulkCreateTasks created_tasks_id_pair.created_task_id, subtasks
          else
            # If there're no tasks' _id equals to pc_task_id, consider all the tasks are created.
            is_all_tasks_created = true
            query = {}
            @_ensurePcIdInDoc query
            @tasks_collection.find(query, {fields: {pc_task_id: 1}}).forEach (task_doc) =>
              if not is_all_tasks_created
                return

              if @_isTaskUncommittedPcTask task_doc
                is_all_tasks_created = false

              return

            if is_all_tasks_created
              @_commitFinished()

        return

      return

    @grid_data._lock()
    @real_parents_with_pc_child_set.forEach (parent_id) =>
      tasks_with_real_parents_query = 
        "parents.#{parent_id}":
          $ne: null
      @_ensurePcIdInDoc tasks_with_real_parents_query

      if not _.isEmpty(tasks_to_add = @tasks_collection.find(tasks_with_real_parents_query, {sort: {"parents.#{parent_id}.order": 1}}).fetch())
        recursiveBulkCreateTasks parent_id, tasks_to_add

      return

  _storePathsForUndoing: ->
    for parent_id in Array.from @real_parents_with_pc_child_set
      query = 
        "parents.#{parent_id}":
          $ne: null
      @_ensurePcIdInDoc query
      
      @tasks_collection.find(query, {fields: {_id: 1}}).forEach (task) => 
        if parent_id is "0"
          path = "/#{task._id}/"
        else
          path = "/#{parent_id}/#{task._id}/"
        @paths_for_undoing_commit.push path
        return

    return

  undoCommit: ->
    paths_to_remove = []
    for path in @paths_for_undoing_commit
      paths_to_remove.push path
      @grid_data.each path, {}, (section, item_type, item_obj, path, expand_state) -> paths_to_remove.push path
    
    @grid_data.removeParent paths_to_remove, (err) =>
      if err?
        JustdoSnackbar.show
          text: "Undo failed."
          duration: 5000
        return

      return
    
    return

  _commitFailed: ->
    @_unsetCommitInProgress()

    @destroyed = true
    query = {}
    @_ensurePcIdInDoc query
    @tasks_collection._collection.remove query

    @_storePathsForUndoing()
    @undoCommit()
    
    @grid_data._release()
    @is_commit_finished_called = true
    @grid_control.preview_context = null
    return

  _commitFinished: ->
    @_unsetCommitInProgress()

    if @is_commit_finished_called
      return
    
    @is_commit_finished_called = true

    # Save all created_task_ids for unsetting pc_id and pc_task_id
    query = {}
    @_ensurePcIdInDoc query
    created_task_ids = @tasks_collection.find(query, {fields: {_id: 1}}).map (task_doc) -> task_doc._id

    @_storePathsForUndoing()

    Tracker.flush()
    @grid_data._flushAndRebuild()
    for task_id in @items_to_expand
      @grid_control.activateCollectionItemId task_id
    @grid_data._flushAndRebuild()

    @grid_data._release()

    # Unset pc_id and pc_task_id, so the users can start editing their fields.
    for created_task_id in created_task_ids
      @tasks_collection.update created_task_id, {$set: {pc_id: null, pc_task_id: null}}

    JustdoSnackbar.show
      text: "Created #{_.size created_task_ids} tasks."
      duration: 1000 * 60 * 2 # 2 mins
      actionText: "Undo"
      showDismissButton: true
      onActionClick: =>
        @undoCommit()
        JustdoSnackbar.close()
        return
    
    # Note that even if we call @destroy() here, @undoCommit will still work.
    @destroy()

    return

  reject: ->
    @destroy()
    return
  
  destroy: ->
    if @destroyed
      return
      
    @destroyed = true

    query = {}
    @_ensurePcIdInDoc query
    @tasks_collection._collection.remove query
    @grid_data._release()

    @real_parents_with_pc_child_set.clear()
    @is_commit_finished_called = true
    @grid_control.preview_context = null

    return
  
  _requireNotDestroyed: ->
    if @destroyed
      throw @_error "destroyed"
    return

  removeParent: (paths) ->
    @_requireNotDestroyed()

    if _.isString(paths)
      paths = [paths]
    
    for path in paths
      path = GridData.helpers.normalizePath(path)
      task_id = GridData.helpers.getPathItemId(path)
      parent_id = GridData.helpers.getPathParentId(path)
      
      # Check permissions
      if parent_id is "0"
        APP.justdo_permissions?.requireJustdoPermissions "grid-structure.add-remove-sort-root-tasks", @project_id, Meteor.userId()
      else
        APP.justdo_permissions?.requireTaskPermissions "grid-structure.add-remove-sort-children", parent_id, Meteor.userId()
      
      # For preview context, we just remove the pc task
      query = 
        _id: task_id
      @_ensurePcIdInDoc query
      if task_doc = @tasks_collection.findOne(query)
        # Simulate removal of parent
        simulated_parents = _.clone(task_doc.parents)
        delete simulated_parents[parent_id]
        
        # Check if this would remove the last parent
        if _.isEmpty(simulated_parents)
          # If no parents left, remove the task completely
          @removeTasks([task_id])
        else
          # Otherwise, just update the parents field to remove the reference to this parent
          update_op = {$unset: {}}
          update_op.$unset["parents.#{parent_id}"] = ""
          
          # Update in minimongo
          @tasks_collection._collection.update(task_id, update_op)

    return true

  bulkRemoveParents: (paths) ->
    @_requireNotDestroyed()
    return @removeParent(paths)

  addParent: (item_id, new_parent) ->
    @_requireNotDestroyed()
    
    # Find the task
    task_doc = @tasks_collection.findOne(item_id)
    if not task_doc or not @_isTaskCreatedFromThisPc(task_doc)
      throw @_error "not-supported", "Cannot add parent to non-preview task"
    
    parent_id = new_parent.parent
    order = new_parent.order or @_getNewChildOrder(parent_id)
    
    # Check permissions
    if parent_id is "0"
      APP.justdo_permissions?.requireJustdoPermissions "grid-structure.add-remove-sort-root-tasks", @project_id, Meteor.userId()
    else
      APP.justdo_permissions?.requireTaskPermissions "grid-structure.add-remove-sort-children", parent_id, Meteor.userId()
    
    # Update parents field
    if not task_doc.parents
      task_doc.parents = {}
      
    task_doc.parents[parent_id] =
      order: order

    # Update the task in minimongo
    @tasks_collection._collection.update(item_id, task_doc)
    
    # Only mark non-root paths
    if parent_id isnt "0"
      @_markRealParentsWithPcChild("/#{parent_id}/")
    else
      @_markRealParentsWithPcChild "/"

    return true

  movePath: (paths, new_location) ->
    @_requireNotDestroyed()
    
    # Convert single path to array
    string_path_provided = false
    if _.isString(paths)
      string_path_provided = true
      paths = [paths]
    
    # Process new_location
    new_location_obj = null
    if not _.isArray(new_location)
      new_location_obj = new_location
    else
      # Convert [position_path, relation] format to object format
      [position_path, relation] = new_location
      position_path = GridData.helpers.normalizePath(position_path)
      
      if GridData.helpers.isRootPath position_path
        # Root path
        new_location_obj = {parent: "0"}
        
        if relation == 0
          new_location_obj.order = 0
      else if relation in [0, 2]
        # Child relation
        new_location_obj = {
          parent: GridData.helpers.getPathItemId(position_path)
        }
        
        if relation == 0
          new_location_obj.order = 0
      else
        # Sibling relation (-1 or 1)
        parent_id = GridData.helpers.getPathParentId(position_path)
        item_id = GridData.helpers.getPathItemId(position_path)
        task_doc = @tasks_collection.findOne(item_id)
        
        if task_doc?.parents?[parent_id]?.order?
          order = task_doc.parents[parent_id].order
          
          if relation is 1
            order += @order_inc_step
          else if relation is -1
            order -= @order_inc_step
          
          new_location_obj = {
            parent: parent_id
            order: order
          }
        else
          throw @_error "not-supported", "Cannot determine order for movePath"
    
    new_location_parent_id = new_location_obj.parent
    
    # Increment the order of items at or after the target position
    if new_location_obj.order? and paths.length > 0
      @_incrementChildsOrderGte new_location_parent_id, new_location_obj.order, null, paths.length
    
    # For each path, perform the move
    results = []
    new_order = new_location_obj.order
    for path in paths
      path = GridData.helpers.normalizePath(path)
      item_id = GridData.helpers.getPathItemId(path)
      parent_id = GridData.helpers.getPathParentId(path)
      
      # Only operate on preview tasks
      task_doc = @tasks_collection.findOne(item_id)
      if not task_doc or not @_isTaskCreatedFromThisPc(task_doc)
        throw @_error "not-supported", "Cannot move non-preview task"
      
      # If the new parent is already in the parents field, update the order
      if _.has task_doc.parents, new_location_parent_id
        
        # # On the grid, if the user drag a task to be after it's next sibling, new_location_obj.order would be the same as the next sibling's order.
        # # So we need to increment the order by 1 to avoid having the same order.
        # if new_order is task_doc.parents[new_location_parent_id].order
        #   new_order 

        @tasks_collection._collection.update(item_id, {$set: {"parents.#{new_location_parent_id}.order": new_order}})
        new_order += 1
      else
        # Add the new parent
        @addParent(item_id, new_location_obj)
        
        # Remove the old parent (unless it's the same as new parent)
        old_parent_id = GridData.helpers.getPathParentId(path)
        if old_parent_id isnt new_location_obj.parent and task_doc.parents?[old_parent_id]?
          @removeParent(path)
      
      # Build the new path for the result
      new_path = if new_location_obj.parent is "0"
        "/#{item_id}/"
      else 
        "/#{new_location_obj.parent}/#{item_id}/"
      
      results.push(new_path)
    
    # Return results based on input format
    if string_path_provided
      return results[0]
    else
      return results

  sortChildren: (path, field, asc_desc) ->
    @_requireNotDestroyed()
    
    path = GridData.helpers.normalizePath(path)
    parent_id = GridData.helpers.getPathItemId(path)
    
    # Find all children of this parent that are preview tasks
    query = {
      project_id: @project_id,
      ["parents.#{parent_id}"]: {$exists: true}
    }
    @_ensurePcIdInDoc query
    
    # Get the child tasks
    children = @tasks_collection.find(query).fetch()
    
    # Sort them by the specified field
    sortMultiplier = if asc_desc == "asc" then 1 else -1
    children = _.sortBy children, (child) -> 
      val = child[field]
      if _.isString(val)
        return val.toLowerCase()
      return val
    
    if asc_desc == "desc"
      children = children.reverse()
    
    # Update their order
    base_order = 0
    order_step = 1
    
    for child, index in children
      order = base_order + (index * order_step)
      
      if child.parents?[parent_id]?
        child.parents[parent_id].order = order
        
        # Update in minimongo
        @tasks_collection._collection.update(child._id, child)
    
    return true

  bulkUpdate: (items_ids, modifier) ->
    @_requireNotDestroyed()
    
    if not _.isArray(items_ids)
      items_ids = [items_ids]
    
    count = 0
    
    for item_id in items_ids
      # Only update preview tasks
      task_doc = @tasks_collection.findOne(item_id)
      if task_doc and @_isTaskCreatedFromThisPc(task_doc)
        # Apply the modifier
        if modifier.$set?
          for field, value of modifier.$set
            task_doc[field] = value
        
        if modifier.$unset?
          for field of modifier.$unset
            delete task_doc[field]
            
        # Update in minimongo
        @tasks_collection._collection.update(item_id, task_doc)
        count++
    
    return count

  edit: (item_id, field, value) ->
    @_requireNotDestroyed()
    
    # Only edit preview tasks
    query =   
      _id: item_id
    @_ensurePcIdInDoc query

    if not (task_doc = @tasks_collection.findOne(query))?
      throw @_error "unknown-task"
    
    # Update the field
    task_doc[field] = value
    
    # Update in minimongo
    @tasks_collection._collection.update(item_id, {$set: {[field]: value}})
    
    return true

  _incrementChildsOrderGte: (parent_id, min_order_to_inc, item_doc=null, inc_count=1) ->
    @_requireNotDestroyed()
    
    check parent_id, String
    check min_order_to_inc, Number
    check inc_count, Number
    
    # For preview context, we only need to update tasks with pc_id
    query = 
      pc_id: @pc_id
      project_id: @project_id
      ["parents.#{parent_id}.order"]: {$gte: min_order_to_inc}
    
    # Find all matching tasks and update them
    @tasks_collection.find(query).forEach (task) =>
      # Update the order in the document
      task.parents[parent_id].order += inc_count
      
      # Update in minimongo
      update_op = {$set: {}}
      update_op.$set["parents.#{parent_id}.order"] = task.parents[parent_id].order
      @tasks_collection._collection.update(task._id, update_op)
      
      return
    
    return

_.extend GridControl.prototype,
  preview_context_dep: new Tracker.Dependency()

  createPreviewContext: (options={}) ->
    if not (project_id = JD.activeJustdoId())?
      throw @_error "not-supported", "Cannot create preview context without a project_id"
    
    if @preview_context?
      throw @_error "not-supported", "Preview context already exists."

    options.project_id = project_id
    options.grid_control = @
    @preview_context = new PreviewContext(options)
    @preview_context_dep.changed()
    return @preview_context
  
  getCurrentPreviewContext: ->
    @preview_context_dep.depend()

    # If commit is in progress, return null to allow passing grid-data operations to server
    if @preview_context?.isCommitInProgress()
      return null
    
    return @preview_context

  _gcMetadataGenerator: (item, item_meta_details, index) ->
    styles = {}
    gc = APP.modules.project_page.gridControl()

    if gc.getCurrentPreviewContext()?._isTaskUncommittedPcTask(item)
      styles["border-style"] = "groove"
    return {style: styles}
  
  _installGcRowsMetadataGenerator: ->
    if @_gc_rows_metadata_generator_installer_computation?
      # Already installed.
      return
    
    @_gc_rows_metadata_generator_installer_computation = Tracker.autorun =>
      if (gc = APP.modules.project_page.gridControl())?
        if not gc._preview_context_rows_styling_installed?
          gc.registerMetadataGenerator @_gcMetadataGenerator
          gc._preview_context_rows_styling_installed = true
      return
    return
  
  _uninstallGcRowsMetadataGenerator: ->
    @_gc_rows_metadata_generator_installer_computation?.stop()
    
    if (gcm = APP.modules.project_page.getGridControlMux())?
      _.each gcm.getAllTabsNonReactive(), (tab) =>
        if (gc = tab.grid_control)?
          gc.unregisterMetadataGenerator @_gcMetadataGenerator
          delete gc._preview_context_rows_styling_installed
    @_gc_rows_metadata_generator_installer_computation = null
    
    return

  _setupPreviewContextNullaryOperations: ->
    project_page_module = APP.modules.project_page

    preview_context_ops = 
      createPreviewContext:
        human_description: "Create Preview Context"
        keyboard_shortcut: "shift+p"
        template:
          custom_icon_html: -> """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#edit-2"/></svg>"""
        op: ->
          gc = project_page_module.gridControl()
          gc.createPreviewContext()

          return
        prereq: -> true
      commitPreviewContext:
        human_description: "Commit Preview Context"
        keyboard_shortcut: "shift+c"
        template:
          custom_icon_html: -> """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#check"/></svg>"""
        op: ->
          gc = project_page_module.gridControl()

          if (preview_context = gc.getCurrentPreviewContext())?
            preview_context.commit()

          return
        prereq: -> true
      destroyPreviewContext:
        human_description: "Destroy Preview Context"
        keyboard_shortcut: "shift+d"
        template:
          custom_icon_html: -> """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#x"/></svg>"""
        op: ->
          gc = project_page_module.gridControl()

          if (preview_context = gc.getCurrentPreviewContext())?
            preview_context.destroy()

          return
        prereq: -> true


    for op_name, options of preview_context_ops
      if not project_page_module.getNullaryOperation(op_name)?
        project_page_module.setNullaryOperation op_name, options
    
    return