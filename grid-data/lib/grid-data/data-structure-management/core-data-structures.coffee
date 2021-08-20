helpers = share.helpers

_.extend GridData.prototype,
  _initCoreStructures: ->
    #
    # Grid data core integration (all init in @_initGridDataCoreIntegration())
    #
    @items_by_id = null
    @tree_structure = null
    @detaching_items_ids = null

    #
    # Flush managemnt
    #
    @_flush_orchestrator = null
    @_need_flush_count = 0
    @_need_flush = new ReactiveVar(0)
    @_flushing = false # Will be true during flush process
    # @_flush_counter Counts the amount of performed flushes. Can be used to
    # create reactive resources that gets invalidated upon tree changes.
    # For clearity, use @invalidateOnFlush() instead of directly
    @_flush_counter = new ReactiveVar(0)

    #
    # Flush queues/flags
    #

    # @_structure_changes_queue stores the tree structure changes that will be applied in the
    # next flush (such as expand/collapse path).
    # Items are in the form: ["type", update]
    @_structure_changes_queue = []

    #
    # Rebuild managemnt
    #
    @_rebuild_orchestrator = null
    @_need_rebuild_count = 0
    @_need_rebuild = new ReactiveVar(0)
    @_rebuilding = false # Will be true during rebuild process
    # @_rebuild_counter counts the amount of performed flushes. Can be used to
    # create reactive resources that gets invalidated upon tree changes.
    # For clearity, use @invalidateOnRebuild() instead of directly
    @_rebuild_counter = new ReactiveVar(0)

    #
    # Grid data core related
    #
    @_grid_data_core_structure_changes_dependency = new Tracker.Dependency()

    #
    # Grid representation
    #

    @grid_tree = [] # [[item, tree_level, path, expand_state, item_section], ...]
    @_items_ids_map_to_grid_tree_indices = {} # {item_id: [indices in @grid_tree]}
    @_typed_items_paths_map_to_grid_tree_indices = {} # {path: index in grid_tree}
    @_expanded_paths = {} # if path is a key of @_expanded_paths it is expanded regardless of its value

    # We collect from the "structure-changed" event information about items ids with changed children.
    #
    # We buffer these changes into the @_items_ids_with_changed_children_buffer object.
    #
    # Following a rebuild, we send, the gathered items ids with changed children as an argument
    # of the "rebuild" event and flush the buffer.
    @_items_ids_with_changed_children_buffer = {}

    @once "_perform_deferred_procedures", -> @_initCoreStructuresManagers()

    @_initGridDataCoreIntegration()

    return

  _initCoreStructuresManagers: ->
    @_init_flush_orchestrator()

    @_init_rebuild_orchestrator()

    Meteor.setTimeout =>
      # This setTimeout makes sure the grid is built
      # at least once following the load of the data.
      #
      # Note: We need the tree to build at least once to load sections info
      Tracker.nonreactive =>
        if @_destroyed
          # Nothing to do
          return

        if @_rebuild_counter.get() != 0
          # First build occured already
          return

        if @_flush_counter.get() != 0
          # If first flush occured already but it didn't trigger rebuild
          # (rare situation that the flush pending changes didn't need
          # rebuild)

          # Build tree for the first time immediately
          @_rebuildGridTree()

          return

        if @_get_need_flush() == 0
          # @_get_need_flush() == 0 means that no flush performed yet.
          #
          # That can mean 2 things:
          #
          # 1. No items exist for this grid
          # 2. All data from subscriptions was ready before observer (@_init_items_tracker)
          #    was set, as a result, no flush data related flush was required, and
          #    grid wasn't built for initial payload. (In this case all data
          #    loaded by @_initDataStructure).

          # We build the tree for the first time immediately for the 2 cases above.

          @_rebuildGridTree()

          return
        else # else is here to ease readability
          # If there's a pending flush, wait for it to finish
          # if after it no rebuild is needed perform the first
          # rebuild
          @once "flush", =>
            if @_need_rebuild_count == 0
              @_rebuildGridTree()

    , 250

  _initGridDataCoreIntegration: ->
    # Add references to the main @_grid_data_core data structures
    @items_by_id = @_grid_data_core.items_by_id
    @tree_structure = @_grid_data_core.tree_structure
    @detaching_items_ids = @_grid_data_core.detaching_items_ids

    @_grid_data_core.on "structure-changed", (data) =>
      @_bufferItemsIdsWithChangedChildren(data.items_ids_with_changed_children)

      @_set_need_rebuild()

      @_grid_data_core_structure_changes_dependency.changed()

      return

    @_grid_data_core.on "content-changed", (item_id, changed_fields_array) =>
      if @_items_ids_map_to_grid_tree_indices[item_id]?
        for row in @_items_ids_map_to_grid_tree_indices[item_id]
          @emit "grid-item-changed", row, changed_fields_array

      return

    @_grid_data_core.on "bulk-foreign-keys-updates", (foreign_keys_fields_updates) =>
      for grid_tree_task_details, grid_row_index in @grid_tree
        for field_id, foreign_key_updated_vals of foreign_keys_fields_updates
          if grid_tree_task_details[0][field_id] of foreign_key_updated_vals
            @emit "grid-item-changed", grid_row_index, [field_id]

      return

  # XXX Base the flush process on JustdoHelpers.FlushManager
  _idle_time_ms_before_set_need_flush: 0
  _set_need_flush_timeout: null
  _flush_lock: false
  _flush_blocked_by_lock: false
  _set_need_flush: ->
    if @_flush_lock
      @_flush_blocked_by_lock = true

      return

    if @_flushing
      @logger.info("_set_need_flush: called during flush, ignoring")

      return

    if @_set_need_flush_timeout?
      clearTimeout @_set_need_flush_timeout

    @_set_need_flush_timeout = setTimeout =>
      @_set_need_flush_timeout = null
      @_need_flush.set(++@_need_flush_count)
    , @_idle_time_ms_before_set_need_flush

  _lock_flush: ->
    # Lock
    @_flush_lock = true

    # Remove flush that's about to happen
    if @_set_need_flush_timeout?
      clearTimeout @_set_need_flush_timeout
      @_set_need_flush_timeout = null

      # Mark that a flush is needed upon release
      @_flush_blocked_by_lock = true

  _perform_temporal_strucutral_flush_lock_release: ->
    # If flush is locked and a needed flush already blocked, perform it immediately

    # IMPORTANT! Unlike @_perform_temporal_flush_lock_release this will
    # perform only structural flushes - no data updates

    # Returns true if flush performed; flase otherwise.
    if @_flush_lock and @_flush_blocked_by_lock
      Tracker.nonreactive =>
        @_flush true # passing true as first arg means structure_only 

      # Note, we keep @_flush_blocked_by_lock as is as there might be data changes
      # waiting

      return true

    return false

  _perform_temporal_flush_lock_release: ->
    # If flush is locked and a needed flush already blocked, perform it immediately

    # Returns true if flush performed; flase otherwise.
    if @_flush_lock and @_flush_blocked_by_lock
      Tracker.nonreactive =>
        @_flush()

      @_flush_blocked_by_lock = false

      return true

    return false

  _release_flush: (immediate_flush = false) ->
    # If immediate_flush is true and flush was blocked
    # a flush will be performed right away and not in the 
    # @_idle_time_ms_before_set_need_flush

    # Release lock
    @_flush_lock = false

    # If flush was blocked, set need flush
    if @_flush_blocked_by_lock
      @_flush_blocked_by_lock = false

      if immediate_flush
        @_flush()
      else
        @_set_need_flush()

  _get_need_flush: ->
    @_need_flush.get()

  _init_flush_orchestrator: ->
    if not @_destroyed and not @_flush_orchestrator
      @_flush_orchestrator = Tracker.autorun =>
        # The _flush_orchestrator is used to combine required updates to the
        # internal data structure and perform them together in order to save
        # CPU time and as a result improve the user experience
        #
        # Meteor calls Tracker.autorun when the system is idle. Hence all the
        # @_set_need_flush requests will wait till Meteor is idle (till next
        # Meteor's flush phase) and will be performed together on the internal
        # data strtuctures
        if @_get_need_flush() != 0 # no need to flush on init
          Tracker.nonreactive =>
            @_flush()

  _init_rebuild_orchestrator: ->
    if not @_destroyed and not @_rebuild_orchestrator
      @_rebuild_orchestrator = Tracker.autorun =>
        # The _rebuild_orchestrator is used to combine required updates to the
        # internal data structure and perform them together in order to save
        # CPU time and as a result improve the user experience
        #
        # Meteor calls Tracker.autorun when the system is idle. Hence all the
        # @_set_need_rebuild requests will wait till Meteor is idle (till next
        # Meteor's flush phase) and will be performed together
        if @_need_rebuild.get() != 0 # no need to rebuild on init
          Tracker.nonreactive =>
            @_rebuildGridTree()

  _rebuild_lock: false
  _rebuild_blocked_by_lock: false
  _set_need_rebuild: ->
    if @_rebuild_lock
      @_rebuild_blocked_by_lock = true

      return

    if @_rebuilding
      @logger.info("_set_need_rebuild: called during rebuild, ignoring")

      return

    @_need_rebuild.set(++@_need_rebuild_count)

  _bufferItemsIdsWithChangedChildren: (items_ids_with_changed_children) ->
    _.extend @_items_ids_with_changed_children_buffer, items_ids_with_changed_children

    return

  _flushItemsIdsWithChangedChildren: ->
    items_ids_with_changed_children = @_items_ids_with_changed_children_buffer

    @_items_ids_with_changed_children_buffer = {}

    return items_ids_with_changed_children

  invalidateOnGridDataCoreStructureChange: ->
    if Tracker.currentComputation?
      # If there's no computation - do nothing

      # Call this method on methods that should gets recompute when the
      # data strucutres maintained by GridDataCore changes
      return @_grid_data_core_structure_changes_dependency.depend()

    return 

  invalidateOnRebuild: ->
    if Tracker.currentComputation?
      # If there's no computation - do nothing

      # Call this method on methods that should gets recompute on rebuild (if ran
      # inside a computation)
      return @_rebuild_counter.get()

    return

  _lock: ->
    # Note that @_lock doesn't lock the @_grid_data_core
    # flush process.
    # The @_grid_data_core might be shared with other grid
    # control.
    @_lock_flush()
    @_lock_rebuild()

  _release: (immediate_rebuild) ->
    # See comment on @_lock()
    @_release_flush(immediate_rebuild)
    @_release_rebuild(immediate_rebuild)

  _perform_temporal_rebuild_lock_release: ->
    # If a rebuild was blocked by a lock, perform it now, keep the lock

    # Returns true if rebuild performed; flase otherwise.

    if @_rebuild_blocked_by_lock
      @_rebuildGridTree()

      @_rebuild_blocked_by_lock = false

      return true

    return false

  _perform_temporal_strucutral_release: ->
    # If a flush or a rebuild were blocked due to a lock, perform the blocked
    # operations now and keep the lock

    # IMPORTANT! Unlike @_perform_temporal_release this will
    # perform only structural flushes - no data updates

    # Returns true if rebuild (even if flush didn't) performed; flase otherwise.

    @_perform_temporal_strucutral_flush_lock_release()

    return @_perform_temporal_rebuild_lock_release()

  _perform_temporal_release: ->
    # If a flush or a rebuild were blocked due to a lock, perform the blocked
    # operations now and keep the lock

    # Returns true if rebuild (even if flush didn't) performed; flase otherwise.

    @_perform_temporal_flush_lock_release()

    return @_perform_temporal_rebuild_lock_release()

  _lock_rebuild: ->
    # Lock
    @_rebuild_lock = true

  _release_rebuild: (immediate_rebuild = false) ->
    # If immediate_rebuild is true and rebuild was blocked
    # a rebuild will be performed right away and not in the next
    # tick

    # Release lock
    @_rebuild_lock = false

    # If rebuild was blocked, set need rebuild
    if @_rebuild_blocked_by_lock
      @_rebuild_blocked_by_lock = false

      if immediate_rebuild
        @_rebuildGridTree()
      else
        @_set_need_rebuild()

  _structure_changes_handlers:
    expand_path: (path) ->
      rebuild_tree = false

      if not @_inExpandedPaths(path)
        @_expanded_paths[path] = true

        rebuild_tree = true

      return rebuild_tree

    collapse_path: (path) ->
      rebuild_tree = false

      if @_inExpandedPaths(path)
        delete @_expanded_paths[path]

        rebuild_tree = true

      return rebuild_tree

    collapse_all_paths: ->
      rebuild_tree = false

      if _.isEmpty @_expanded_paths
        return rebuild_tree

      rebuild_tree = true

      for path of @_expanded_paths
        delete @_expanded_paths[path]

      return rebuild_tree

    expand_passed_filter_paths: ->
      # expand all the paths that passed the filter.
      rebuild_tree = true

      # Begin from removing all paths (avoid, duplicates, and avoid longevity memory leak)
      for path of @_expanded_paths
        delete @_expanded_paths[path]

      last_path = null
      # the first path we'll encounter (if any), will necessarily will be of level 1, so
      # with that, we don't need to worry of attempt to expand the null last_path
      last_path_level = 1
      @each "/", {filtered_tree: true, expand_only: false}, (_1, _2, _3, path) =>
        # Check whether the previous item is a parent, if it is, expand it.
        path_level = GridData.helpers.getPathLevel(path)

        if path_level > last_path_level
          # last_path is a parent, expand it.
          @_expanded_paths[last_path] = true

        last_path_level = path_level
        last_path = path

        return

      return rebuild_tree

  invalidateOnFlush: ->
    if Tracker.currentComputation?
      # If there's no computation - do nothing

      # Call this method on methods that should gets recompute on flush (if ran
      # inside a computation)
      return @_flush_counter.get()

  _flush: (structure_only = false) ->
    # Perform pending updates to the internal data structures

    # If structure_only is true, only structure updates will be performed
    # data updates will be ignored.

    if not structure_only
      # If flush as a result of the flush a rebuild will be required
      # the "structure-changed" event will emit. We will catch this
      # emit and call @_set_need_rebuild().
      # Note that if the code below will require rebuild as well,
      # since it calls @_set_need_rebuild() too, only a single
      # rebuild will perform
      @_grid_data_core.flush()

    if (structure_only and @_structure_changes_queue.length == 0) or
         (@_structure_changes_queue.length == 0)
      @logger.debug "No need to flush"

      return

    @logger.debug "Flush: start"

    @_flushing = true

    rebuild_tree = false

    # Preform all required structure changes, structure changes funcs return true
    # if tree rebuild is required.
    for change in @_structure_changes_queue
      # @logger.debug "Flush: process structure changes"
      [type, args] = change
      # @logger.debug "Flush: Process #{type}: #{JSON.stringify args}"
      require_tree_rebuild = @_structure_changes_handlers[type].apply @, args
      rebuild_tree = rebuild_tree || require_tree_rebuild
      # @logger.debug "Flush: process structure changes - done; rebuild_tree = #{rebuild_tree}"

      @_structure_changes_queue = []

    if rebuild_tree
      @logger.debug "Flush: rebuild tree"
      @_set_need_rebuild()

    @logger.debug "Flush: done"

    @_flushing = false

    Tracker.nonreactive =>
      @_flush_counter.set(@_flush_counter.get() + 1)

    @emit "flush"

  _flushAndRebuild: (structure_only) ->
    # Flush and rebuild immediately (regardelss of whether or not flush/rebuild are locked)

    @_flush(structure_only)

    # Call tracker.flush() to perform awaiting required grid
    # rebuilds resulted from the @_flush (@_need_rebuild) right away
    # (by relying on the regular rebuild reactivity triggers,  will
    # rebuild only if necessary)
    try
      Tracker.flush()
    catch
      # If we are already in flush, nothing to do
      true

    if @_rebuild_blocked_by_lock
      # If the reactive rebuild triggers failed to trigger rebuild due to lock
      # perform the rebuild directly
      @_rebuildGridTree()

    return

  _getGridTreeSignature: -> (_.map @grid_tree, (item) -> item[2] + "." + item[3]).join("\n")

  _rebuildGridTree: ->
    @emit "pre_rebuild"

    @logger.debug "Rebuild: start"

    @_rebuilding = true

    # Before grid rebuild we ensure that all flush pending ops are done.
    # This is critical since sections might ask for a rebuild as a result
    # of changes to the @collection, in which case, if the internal data
    # structures (such as items_by_id) won't be synced by flushing, we will
    # run into bugs
    @_flush()

    previous_signature = @_getGridTreeSignature()

    # Initiated in @_buildSections()
    # @grid_tree = []
    # @_items_ids_map_to_grid_tree_indices = {}
    # @_typed_items_paths_map_to_grid_tree_indices = {}

    @_rebuildSections() # defined in grid-sections.coffee

    current_signature = @_getGridTreeSignature()

    raw_diff = JsDiff.diffLines(previous_signature, current_signature)

    last_change_type = 0 # 0 same, 1 removed, 2 added

    # Produce a normalized diff array of structure
    # [["same", same_rows_count], ["changed", removed_rows_count, added_rows_count], ["same", same_rows_count], ["changed", removed_rows_count, added_rows_count], ...]
    diff = []
    last_change_type = 0
    for change in raw_diff
      if change.added
        current_change_type = 2
      else if change.removed
        current_change_type = 1
      else
        current_change_type = 0

      if current_change_type == 0
        diff.push ["same", change.count]
      else if current_change_type == 1
        if diff.length == 0 and (not change.count?)
          # On complete remove we don't get the count of all the rows removed
          change.count = previous_signature.split("\n").length
        diff.push ["diff", change.count, 0]
      else if current_change_type == 2 # don't use else for readability
        if diff.length == 0 and (not change.count?)
          # When diffing with previous empty signatire we don't get the count of all the rows added
          change.count = current_signature.split("\n").length

        if last_change_type == 1
          # update last pushed diff
          diff[diff.length - 1][2] = change.count
        else
          diff.push ["diff", 0, change.count]

      last_change_type = current_change_type

    @_updateGridTreeFilterState()

    @logger.debug "Rebuild: Done"

    @_rebuilding = false

    Tracker.nonreactive =>
      @_rebuild_counter.set(@_rebuild_counter.get() + 1)

    @emit "rebuild", diff, @_flushItemsIdsWithChangedChildren()