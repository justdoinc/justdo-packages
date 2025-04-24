_.extend PACK.Plugins,
  preview_context:
    init: ->      
      # Prevent editing of tasks created by preview context
      @register "BeforeEditCell", (e, args) =>
        if not (task_id = args.doc?._id)?
          # This case shouldn't happen
          return true
        
        query = 
          _id: task_id
          pc_id:
            $ne: null
        is_task_pc_task = @collection.findOne(query, {fields: {_id: 1}})?

        return not is_task_pc_task

      # Defined below
      @_installGcRowsMetadataGenerator()

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
    @order_inc_step = 0.0001

    # For creating tasks level by level: We create the tasks using bulkAddChild for pc tasks with a real parent first,
    # then create their pc childrens.
    @real_parents_with_pc_child_set = new Set()

    @items_to_expand = []

    @paths_for_undoing_commit = []
    @is_commit_finished_called = false

    return
  
  _deferredInit: ->
    return
  
  _getAndIncOrder: ->
    order = @order
    @order += @order_inc_step
    return order
  
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
    
    @_markRealParentsWithPcChild path, task_doc
    if options.auto_expand_ancestors
      @_activateItemOnceTreeChanged created_task_id

    return created_task_id
  
  _getActivePath: -> 
    return JD.activePath()
  
  _getNewChildOrder: (parent_id) ->
    query = 
      project_id: @project_id
      "parents.#{parent_id}":
        $ne: null
    query_options = 
      sort: 
        "parents.#{parent_id}.order": -1
        
    last_child = @tasks_collection.findOne query, query_options

    new_order = (last_child?.parents?[parent_id]?.order + 1) or 0

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
  
  _markRealParentsWithPcChild: (path) ->
    is_root_path = (not path?) or (GridData.helpers.isRootPath path)

    if is_root_path
      parent_id = 0
    else
      parent_id = GridData.helpers.getPathItemId path

      parent_task_doc = @tasks_collection.findOne parent_id, {fields: {pc_task_id: 1}}
      is_parent_real_task = parent_task_doc._id isnt parent_task_doc.pc_task_id

    if is_root_path or is_parent_real_task 
      @real_parents_with_pc_child_set.add parent_id
    
    return

  addChild: (path, fields) ->
    if not path?
      throw @_error "not-supported", "Cannot add child without an active path"
    parent_id = GridData.helpers.getPathItemId(path)

    parent_members = JD.activeItemUsers()
    parent_members.push Meteor.userId()
    parent_members = _.uniq parent_members

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
    if path?
      parent_id = GridData.helpers.getPathParentId path
    else
      parent_id = 0

    fields = _.extend {}, fields
    fields.parents = 
      [parent_id]:
        order: @_getNewSiblingOrder(parent_id, JD.activeItemId())
    
    if (not path?) or (GridData.helpers.isRootPath path)
      parent_path = path
    else
      parent_path = GridData.helpers.getParentPath path
      
    return @_createTaskInLocalMinimongo parent_path, fields
  
  bulkAddSibling: (path, siblings_fields) ->    
    if (_.isObject(siblings_fields)) and (not _.isArray(siblings_fields))
      siblings_fields = [siblings_fields]
    
    if _.isEmpty siblings_fields
      return
    
    created_task_ids = []
    
    for sibling_fields in siblings_fields
      created_task_ids.push @addSibling path, sibling_fields
    
    return created_task_ids

  # addTasks will only create temporory preview in the client side
  # by inserting documents to minimongo.
  # It will not commit the changes to the server and changes will be lost when refreshing the page
  # unless commit() is called.
  addTasks: (path, task_docs) ->
    if (_.isObject(task_docs)) and (not _.isArray(task_docs))
      task_docs = [task_docs]
    
    if _.isEmpty task_docs
      return
    
    created_task_ids = []
    for task_doc in task_docs
      created_task_ids.push @_createTaskInLocalMinimongo path, task_doc

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
    delete task_doc.parents
    return @_removeClientOnlyFields task_doc

  commit: ->
    @_requireNotDestroyed()

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

    recursiveBulkCreateTasks = (parent_id, tasks) =>
      if parseInt(parent_id, 10) is 0
        path = "/"
      else
        path = "/#{parent_id}/"
        
      @grid_data.bulkAddChild path, tasks, (err, res) =>
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

        created_task_ids = _.map res, (created_task_id_and_path) -> created_task_id_and_path[0]
        removePreviewTasks created_task_ids
        @items_to_expand = @items_to_expand.concat created_task_ids

        query = 
          _id:
            $in: created_task_ids
        @_ensurePcIdInDoc query
        created_task_id_and_pc_task_id_pairs = @tasks_collection.find(query, {fields: {pc_task_id: 1}}).map (task_doc) -> {created_task_id: task_doc._id, pc_task_id: task_doc.pc_task_id}
        for created_tasks_id_pair in created_task_id_and_pc_task_id_pairs
          subtasks_query = 
            "parents.#{created_tasks_id_pair.pc_task_id}":
              $ne: null
          @_ensurePcIdInDoc subtasks_query

          if not _.isEmpty(subtasks = @tasks_collection.find(subtasks_query).map (task) => @_removePreviewOnlyFields task)
            recursiveBulkCreateTasks created_tasks_id_pair.created_task_id, subtasks
          else
            # If there're no tasks' _id equals to pc_task_id, consider all the tasks are created.
            is_all_tasks_created = true
            query = {}
            @_ensurePcIdInDoc query
            @tasks_collection.find(query, {fields: {pc_task_id: 1}}).forEach (task_doc) ->
              if not is_all_tasks_created
                return

              if task_doc._id is task_doc.pc_task_id
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

      if not _.isEmpty(tasks_to_add = @tasks_collection.find(tasks_with_real_parents_query).map (task_to_add) => @_removePreviewOnlyFields task_to_add)
        recursiveBulkCreateTasks parent_id, tasks_to_add

      return

  _storePathsForUndoing: ->
    for parent_id in Array.from @real_parents_with_pc_child_set
      query = 
        "parents.#{parent_id}":
          $ne: null
      @_ensurePcIdInDoc query
      
      @tasks_collection.find(query, {fields: {_id: 1}}).forEach (task) => 
        if (parseInt parent_id, 10) is 0
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

_.extend GridControl.prototype,
  createPreviewContext: (options={}) ->
    if not (project_id = JD.activeJustdoId())?
      throw @_error "not-supported", "Cannot create preview context without a project_id"
    
    if @preview_context?
      throw @_error "not-supported", "Preview context already exists."

    options.project_id = project_id
    options.grid_control = @
    @preview_context = new PreviewContext(options)

    return @preview_context
  
  getCurrentPreviewContext: ->
    return @preview_context

  _gcMetadataGenerator: (item, item_meta_details, index) ->
    styles = {}
    if item.pc_task_id is item._id
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