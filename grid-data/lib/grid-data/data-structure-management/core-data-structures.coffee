helpers = share.helpers

_.extend GridData.prototype,
  _initCoreStructures: ->
    #
    # Flush managemnt
    #

    @_items_tracker = null
    @_flush_orchestrator = null
    @_foreign_keys_trackers = null
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

    # @_data_changes_queue stores the data changes that will be applied in the
    # next flush.
    # Items are in the form: ["type", update]
    @_data_changes_queue = [] 

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
    # Grid representation
    #
    @items_by_id = {}

    @tree_structure = {} # Note @tree_structure contains both items we have items_by_id, and also those linked by other items as their parents
                         # but aren't present in @items_by_id
    @detaching_items_ids = {} # Keys are items ids that are parents of other items but aren't known to us, values are always true
    @grid_tree = [] # [[item, tree_level, path, expand_state, item_section], ...]
    @_items_ids_map_to_grid_tree_indices = {} # {item_id: [indices in @grid_tree]}
    @_typed_items_paths_map_to_grid_tree_indices = {} # {path: index in grid_tree}
    @_expanded_paths = {} # if path is a key of @_expanded_paths it is expanded regardless of its value

    @_ignore_change_in_fields = []

    @once "_perform_deferred_procedures", -> @_initCoreStructuresManagers()

  _initCoreStructuresManagers: ->
    @_initDataStructure()

    @_init_items_tracker()

    @_init_flush_orchestrator()

    @_init_rebuild_orchestrator()

    @_init_foreign_keys_trackers()

    Meteor.setTimeout =>
      Tracker.nonreactive =>
        if not @_destroyed and @_get_need_flush() == 0
          # @_get_need_flush() == 0 means that no flush performed yet.
          #
          # That can mean 2 things:
          #
          # 1. No items exist for this grid
          # 2. All data from subscriptions was ready before observer (@_init_items_tracker)
          #    was set, as a result, no flush data related flush was required, and
          #    grid wasn't built for initial payload. (In this case all data
          #    loaded by @_initDataStructure).

          # Since we need the tree to build at least once to load sections info,
          # we rebuild the tree for the 2 cases above.

          @_rebuildGridTree()
    , 250

  # we use _idle_time_ms_before_set_need_flush to give priority to
  # @_items_tracker over the flush. If many items arrive at the same time, we
  # don't flush until the batch is ready
  _idle_time_ms_before_set_need_flush: 80
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
    # a flush will be performed right away and not in the next
    # tick

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

  _init_items_tracker: ->
    if not @_destroyed and not @_items_tracker
      # build grid tree for first time
      tracker_init = true
      @_items_tracker = @collection.find().observeChanges
        added: (id, doc) =>
          # @logger.debug "Tracker: Item added #{id}"

          if not tracker_init
            doc._id = id
            @_data_changes_queue.push ["add", [id, doc]]

            @_set_need_flush()

        changed: (id, fields_changes) =>
          # @logger.debug "Tracker: Item changed #{id}"

          fields = _.difference(_.keys(fields_changes), @_ignore_change_in_fields) # remove ignored fields

          # Take care of parents changes
          if "parents" in fields
            @_data_changes_queue.push ["parent_update", [id, fields_changes.parents]]

            @_set_need_flush()

            fields = _.without(fields, "parents") # remove parents field

          # Regular changes
          if fields.length != 0
            @_data_changes_queue.push ["update", [id, fields]]

            @_set_need_flush()

        removed: (id) =>
          # @logger.debug "Tracker: Item removed #{id}"

          @_data_changes_queue.push ["remove", [id]]

          @_set_need_flush()

      tracker_init = false

  _init_foreign_keys_trackers: ->
    if not @_destroyed and not @_foreign_keys_trackers?
      foreign_keys_trackers = {}

      for field_name, field_def of @schema
        if field_def.grid_foreign_key_collection?
          do (field_name, field_def) =>
            tracker_cursor_options = {}

            if _.isObject field_def.grid_foreign_key_collection_relevant_fields
              tracker_cursor_options.fields =
                field_def.grid_foreign_key_collection_relevant_fields

            tracker_init = true

            changesCb = (id) =>
              if not tracker_init
                affected_rows_query = {}
                affected_rows_query[field_name] = id

                affected_items = @collection.find(affected_rows_query, {fields: {_id: 1}}).fetch()

                if affected_items.length > 0
                  for item in affected_items
                    @_data_changes_queue.push ["foreign_key_fields_update", [item._id, [field_name]]]

                  @_set_need_flush()

            foreign_keys_trackers[field_name] =
              field_def.grid_foreign_key_collection().find({}, tracker_cursor_options).observeChanges
                added: changesCb
                changed: changesCb
                removed: changesCb

            tracker_init = false

      if not _.isEmpty foreign_keys_trackers
        # Set to false so the above existence check won't pass in
        # following calls
        @logger.debug "Foreign keys trackers initiated"
        @_foreign_keys_trackers = foreign_keys_trackers

  _destroy_foreign_keys_trackers: ->
    if _.isObject @_foreign_keys_trackers
      for field_name, tracker of @_foreign_keys_trackers
        tracker.stop()

        # Ensure gc will remove any trace
        delete @_foreign_keys_trackers[field_name]

      @logger.debug "Foreign keys trackers destroyed"

  _init_flush_orchestrator: ->
    if not @_destroyed and not @_flush_orchestrator
      @_flush_orchestrator = Meteor.autorun =>
        # The _flush_orchestrator is used to combine required updates to the
        # internal data structure and perform them together in order to save
        # CPU time and as a result improve the user experience
        #
        # Meteor calls Meteor.autorun when the system is idle. Hence all the
        # @_set_need_flush requests will wait till Meteor is idle (till next
        # Meteor's flush phase) and will be performed together on the internal
        # data strtuctures
        if @_get_need_flush() != 0 # no need to flush on init
          Tracker.nonreactive =>
            @_flush()

  _init_rebuild_orchestrator: ->
    if not @_destroyed and not @_rebuild_orchestrator
      @_rebuild_orchestrator = Meteor.autorun =>
        # The _rebuild_orchestrator is used to combine required updates to the
        # internal data structure and perform them together in order to save
        # CPU time and as a result improve the user experience
        #
        # Meteor calls Meteor.autorun when the system is idle. Hence all the
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

  invalidateOnRebuild: ->
    if Tracker.currentComputation?
      # If there's no computation - do nothing

      # Call this method on methods that should gets recompute on rebuild (if ran
      # inside a computation)
      return @_rebuild_counter.get()

  _lock: ->
    @_lock_flush()
    @_lock_rebuild()

  _release: (immediate_rebuild) ->
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

  _data_changes_handlers:
    add: (id, doc) ->
      # console.log "add", id, doc

      # Rebuild tree always required after adding a new item
      rebuild_tree = true

      # Update @items_by_id
      @items_by_id[id] = doc
      delete @detaching_items_ids[id]

      # Update tree structure
      for parent_id, parent_metadata of doc.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}
        @tree_structure[parent_id][parent_metadata.order] = id

        if parent_id != "0" and not (parent_id of @items_by_id)
          @detaching_items_ids[parent_id] = true

      return rebuild_tree

    update: (id, fields) ->
      # console.log "update", id, fields

      # No need to update filters on update, since if the update affect
      # the filter the filter tracker will recognize it and trigger
      # its update

      rebuild_tree = false

      @_updateRowFields(id, fields)

      return rebuild_tree

    foreign_key_fields_update: (id, foreign_key_fields) ->
      # console.log "foreign_key_fields_update", id, foreign_key_fields

      rebuild_tree = false

      if @_items_ids_map_to_grid_tree_indices[id]?
        for row in @_items_ids_map_to_grid_tree_indices[id]
          @emit "grid-item-changed", row, foreign_key_fields

      return rebuild_tree

    remove: (id) ->
      # console.log "remove", id

      # Rebuild tree always required after removing an item
      rebuild_tree = true

      # Update @items_by_id
      item_obj = @items_by_id[id]

      if id of @tree_structure
        @detaching_items_ids[id] = true

      # Remove from tree structure any pointer to item
      for parent_id, parent_metadata of item_obj.parents
        # Make sure parent still exist
        if @tree_structure[parent_id]?
          # Make sure still pointing to item
          if @tree_structure[parent_id][parent_metadata.order] == id
            delete @tree_structure[parent_id][parent_metadata.order]

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

      delete @items_by_id[id]

      return rebuild_tree

    parent_update: (item_id, new_parents_field) ->
      # console.log "parent_update", item_id, new_parents_field

      rebuild_tree = false

      # XXX Is there any situation in which we won't find the item?
      prev_item_obj = @items_by_id[item_id]
      prev_parents_obj = prev_item_obj.parents

      # Update parents
      @items_by_id[item_id].parents = new_parents_field

      for parent_id, new_parent_data of new_parents_field
        new_order = new_parent_data.order
        if parent_id of prev_parents_obj
          prev_order = prev_parents_obj[parent_id].order
          # existed already under this parent
          if new_order == prev_order
            # console.log "Case 1 - item haven't moved" 
            # No changes to this parent
            continue
          else
            # Intra parent order change - update tree structure
            # console.log "Case 2 - Intra parent order change", item_id, parent_id, prev_order, new_order

            rebuild_tree = true

            @tree_structure[parent_id][new_order] = item_id
            # XXX Is it possible that the following won't be true?
            if @tree_structure[parent_id][prev_order] == item_id
              delete @tree_structure[parent_id][prev_order]
        else
          # New parent - update tree structure
          # console.log "Case 3 - New parent", item_id, parent_id

          rebuild_tree = true

          if not @tree_structure[parent_id]?
            @tree_structure[parent_id] = {}

            if parent_id != "0" and not (parent_id of @items_by_id)
              @detaching_items_ids[parent_id] = true

          @tree_structure[parent_id][new_order] = item_id

      for parent_id, prev_parent_obj of prev_parents_obj
        prev_order = prev_parent_obj.order

        if not(parent_id of new_parents_field)
          # Removed from parent - update tree structure
          # console.log "Case 4 - Remove parent", item_id, parent_id

          rebuild_tree = true

          # Update tree structure
          # Make sure no other item moved to removed position already
          # XXX can this situation happen?
          if @tree_structure[parent_id][prev_order] == item_id
            delete @tree_structure[parent_id][prev_order]

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

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

    if (structure_only and @_structure_changes_queue.length == 0) or
         (@_structure_changes_queue.length == 0 and @_data_changes_queue.length == 0)
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

    if not structure_only
      # Preform all required data changes, data changes funcs return true
      # if tree rebuild is required.
      for change in @_data_changes_queue
        # @logger.debug "Flush: process data changes"
        [type, args] = change
        # @logger.debug "Flush: Process #{type}: #{JSON.stringify args}"
        require_tree_rebuild = @_data_changes_handlers[type].apply @, args
        rebuild_tree = rebuild_tree || require_tree_rebuild
        # @logger.debug "Flush: process data changes - done; rebuild_tree = #{rebuild_tree}"

      @_data_changes_queue = []

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
    Tracker.flush()

    if @_rebuild_blocked_by_lock
      # If the reactive rebuild triggers failed to trigger rebuild due to lock
      # perform the rebuild directly
      @_rebuildGridTree()

    return

  _initDataStructure: () ->
    @items_by_id = {}
    @tree_structure = {}

    for item in @collection.find().fetch()
      @items_by_id[item._id] = item
      delete @detaching_items_ids[item._id]

      for parent_id, parent_metadata of item.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}

          if parent_id != "0" and not (parent_id of @items_by_id)
            @detaching_items_ids[parent_id] = true

        if parent_metadata.order? and _.isNumber parent_metadata.order
          @tree_structure[parent_id][parent_metadata.order] = item._id

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

    @emit "rebuild", diff

  _updateRowFields: (item_id, fields) ->
    # update internal data structure
    old_item = @items_by_id[item_id]
    item = @collection.findOne(item_id)

    if old_item? and item?
      for field in fields
        @items_by_id[item_id][field] = item[field]

      for removed_field in _.difference(_.keys(@items_by_id[item_id]), _.keys(item))
        delete @items_by_id[item_id][removed_field]

      if @_items_ids_map_to_grid_tree_indices[item_id]?
        for row in @_items_ids_map_to_grid_tree_indices[item_id]
          @emit "grid-item-changed", row, fields