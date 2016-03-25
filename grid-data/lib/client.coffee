helpers = share.helpers
numSort = (a, b) -> a - b

GridData = (collection) ->
  EventEmitter.call this

  @logger = Logger.get("grid-data")

  @collection = collection

  if not (schema = @collection.simpleSchema())?
    @logger.debug "GridData called for a collection with no simpleSchema definition"
    return

  # XXX need to find a way to bring normalized schema from GridControl
  @schema = schema._schema

  @_initialized = false
  @_destroyed = false

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

  # @_filter_paths_needs_update will set to true if tree structure changed or @_filter_items changed
  # will trigger recalc of @_filter_path at the end of the flush or at the end of tree rebuild (whichever comes first)
  @_filter_paths_needs_update = false

  #
  # Grid representation
  #
  @items_by_id = {}
  @tree_structure = {}
  @grid_tree = [] # [[item, tree_level, path, expand_state], ...]
  @_items_ids_map_to_grid_tree_indices = {} # {item_id: [indices in @grid_tree]}
  @_expanded_paths = {} # if path is a key of @_expanded_paths it is expanded regardless of its value

  @_ignore_change_in_fields = []

  @_metadataGenerators = []

  @filter = new ReactiveVar(null, (a, b) -> JSON.sortify(a) == JSON.sortify(b))
  # item_ids present in @filter_independent_items array will always pass the filter
  @filter_independent_items = new ReactiveVar(null, (a, b) -> JSON.stringify(a) == JSON.stringify(b))
  @_filter_tracker = null
  @_filter_items = null
  @_filter_items_ids = null
  @_filter_paths = null # XXX confusing name, keys are grid_tree indexes value is accordance to presence due to active filter 

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  return @

GridData.helpers = helpers # Expose helpers to other packages throw GridData

Util.inherits GridData, EventEmitter

_.extend GridData.prototype,
  _error: JustdoHelpers.constructor_error

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
      # @logger.debug("_set_need_flush: called during flush, ignoring")

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

   # True if there's an active filter, false otherwise; note that for
   # reactivity purposes an invalidation will occur on every filter change
   # (which is desired - don't change this behavior as some parts of the code
   # depend on it)
  isActiveFilter: -> @filter.get()?

  getFilterPaths: -> @_filter_paths

  _setFilterPathsNeedsUpdate: ->
    @_filter_paths_needs_update = true
    @_set_need_flush()

  _hasPassingFilterDecendents: (item_id, tested_item = true) ->
    if not tested_item
      # We don't want to test the first item_id _hasPassingFilterDecendents
      # was called with, we care only about its decendents
      if item_id of @_filter_items_ids
        return true

    if not @tree_structure[item_id]?
      return false

    for order, child_id of @tree_structure[item_id]
      res = @_hasPassingFilterDecendents(child_id, false)

      if res
        return true

    return false

  setFilter: (filter_query) ->
    @filter.set(filter_query)
    # Update @_filter_items immediately so computations that
    # tracks @filter changes will have the up-to-date @_filter_items
    # available 
    @_updateFilterItems()
    # @_updateFilterItems() will call @_setFilterPathsNeedsUpdate so
    # @_update_filter_paths will update @_filter_paths
    @_update_filter_paths()

  _update_filter_paths: ->
    # Filter paths against current @_filter_items, set result to @_filter_paths
    # Also maintains the @_filter_items_ids used for optimized filtered items lookup

    if not @_filter_paths_needs_update
      @logger.debug "Filter paths don't need update"

      return
    else
      @logger.debug "Update filter paths"

    @_filter_paths_needs_update = false

    filter = @filter.get()

    if not filter?
      if @_filter_paths?
        # If not null already
        @_filter_items_ids = null
        @_filter_paths = null

        @emit "filter-paths-cleared"
    else
      if not @_filter_items?
        @logger.warn "@_update_filter_paths called with active filter but no @_filter_items"

        return

      # calculate filter paths
      # [item_filter_state, special_position]
      #
      # item_filter_state:
      #   0: didn't pass filter
      #   1: decendent pass filter, inner node in filtered tree
      #   2: pass filter and decendent pass filter, inner node in filtered tree
      #   3: pass filter, a leaf in the filtered tree
      #
      # special_position
      #   0: not special
      #   1: first passing item
      #   2: last passing item
      #   3: only passing item

      @_filter_items_ids = {}

      for item in @_filter_items
        @_filter_items_ids[item._id] = true

      @_filter_paths = []

      if @getLength() > 0
        # When we find a node that is part of the filtered tree parent_level
        # will hold the level of its parent
        parent_level = null
        # inner_node is true when we find an inner node
        inner_node = false
        
        last_visible_found = false
        first_visible_index = null
        for i in [(@getLength() - 1)..0]
          [child, level, path, expand_state] = @grid_tree[i]
          item_id = child._id

          @_filter_paths[i] = [0, 0]

          inner_node = false
          if parent_level?
            if level == parent_level
              if level == 0
                parent_level = null
              else
                parent_level -= 1

              inner_node = true

          if not inner_node and expand_state == 0
            # If node is collapsed, we need to check whether one of its decendents
            # pass the filter, before we can conclude whether it's an inner_node of the
            # filtered tree or not.
            # We have to do it in order to be able to present its expand/collapse toggle button
            # in the filtered tree only if it has decendent/s that pass the filter
            if @_hasPassingFilterDecendents(item_id)
              if level > 0            
                parent_level = level - 1

              inner_node = true

          if inner_node
            # at the minimum it's 1, might turn out to be 2 later
            @_filter_paths[i][0] = 1

          if item_id of @_filter_items_ids
            if level > 0
              parent_level = level - 1

            if inner_node
              @_filter_paths[i][0] = 2
            else
              @_filter_paths[i][0] = 3

          if @_filter_paths[i][0] > 0
            first_visible_index = i
            if not last_visible_found
              @_filter_paths[i][1] = 2
              last_visible_found = true

        if first_visible_index?
          if @_filter_paths[first_visible_index][1] == 2
            @_filter_paths[first_visible_index][1] = 3
          else
            @_filter_paths[first_visible_index][1] = 1

      @emit "filter-paths-update"

  _updateFilterItems: ->
    # Update @_filter_items based on current @filter

    filter = @filter.get()

    if not filter?
      # If filter cleared, init @_filter_items
      @_filter_items = null
    else
      @_filter_items = @collection.find(@filter.get(), {fields: {_id: 1}}).fetch()

      filter_independent_items = @filter_independent_items.get()

      if filter_independent_items?
        for item_id in filter_independent_items
          @_filter_items.push {_id: item_id}

    # If init is undergoing, we don't want to call @_setFilterPathsNeedsUpdate()
    # yet since it will trigger a flush and we want the first flush to be a result
    # of the initial items data load.
    # Once data will start to load the items observer will request filter update
    # anyway.
    if @_initialized
      @_setFilterPathsNeedsUpdate()

    @logger.debug "@_filter_items updated"

  _init_filter_tracker: ->
    # Track changes to current filter query and @_filter_items (the query result set)
    if not @_destroyed and not @_filter_tracker?
      @_filter_tracker = Tracker.autorun => @_updateFilterItems()

  clearFilterIndependentItems: ->
    @filter_independent_items.set(null)

  addFilterIndependentItems: ->
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      independent_items = []
    else
      # Copy, so reactive dict will be able to see difference
      independent_items = independent_items.slice()

    independent_items = independent_items.concat(_.toArray(arguments))

    @filter_independent_items.set _.uniq(independent_items)

  removeFilterIndependentItems: ->
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      return

    @filter_independent_items.set _.difference(independent_items, _.toArray(arguments))

  _destroy_filter_manager: ->
    if @_filter_tracker?
      @_filter_tracker.stop()

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

  extendItemForeignKeys: (item, options) ->
    # XXX this is the right place to implement caching mechanism for foreign keys
    # docs for fields the user is interested to cache
    #
    # item: an item document, the same object will be edited
    # options:
    #   in_place: true by default. if true , we'll augment the item received
    #             if false a new item will return
    #   foreign_keys: null by default. If is array only the foreign keys
    #                 listed in the array will be extended

    # doc will be returned under a new property named after the foreign_key
    # if foreign_key name ends with _id - without the "_id"
    # otherwise "_doc" will be added

    # Reactive resource

    if options.in_place is false # considered true by default
      # Copy item to new doc
      item = _.extend {}, item

    # Get the list of all the foreign keys from the _foreign_keys_trackers object - we use it
    # only for this data - nothing elese
    #
    # XXX optimize - no need to do this more then once!
    all_foreign_keys = _.keys @_foreign_keys_trackers

    foreign_keys = options.foreign_keys
    if not foreign_keys?
      # Extend all
      foreign_keys = all_foreign_keys

    if _.isEmpty foreign_keys
      @logger.debug "extendItemForeignKeys: No foreign keys to extend"

      return item

    for foreign_key in foreign_keys
      if foreign_key not in all_foreign_keys
        @logger.warn "extendItemForeignKeys: Unknown foreign key #{foreign_key} provided, skipping" 

        continue

      id_suffix_regex = /_id$/
      if id_suffix_regex.test(foreign_key)
        # If ends with _id just remove _id
        extended_field_name = foreign_key.replace id_suffix_regex, ""
      else
        # Else add "_doc" ending
        extended_field_name += "_doc"

      item[extended_field_name] =
        @schema[foreign_key].grid_foreign_key_collection().findOne(item[foreign_key])

    return item

  _init_flush_orchestrator: ->
    if not @_destroyed and not @_flush_orchestrator
      @_flush_orchestrator = Meteor.autorun =>
        # The _flush_orchestrator is used to combine required updates to the
        # internal data structure and perform them together in order to save
        # CPU time and as result improve user experience
        #
        # Meteor calls Meteor.autorun when the system is idle. Hence all the
        # @_set_need_flush requests will wait till Meteor is idle (till next
        # Meteor's flush phase) and will be performed together on the internal
        # data strtuctures
        if @_get_need_flush() != 0 # no need to flush on init
          Tracker.nonreactive =>
            @_flush()

  _structure_changes_handlers:
    expand_path: (path) ->
      rebuild_tree = false

      if not(path of @_expanded_paths)
        @_expanded_paths[path] = true

        rebuild_tree = true

        @_setFilterPathsNeedsUpdate()

      return rebuild_tree

    collapse_path: (path) ->
      rebuild_tree = false

      if path of @_expanded_paths
        delete @_expanded_paths[path]

        rebuild_tree = true

        @_setFilterPathsNeedsUpdate()

      return rebuild_tree

  _data_changes_handlers:
    add: (id, doc) ->
      # console.log "add", id, doc

      # Rebuild tree always required after adding a new item
      rebuild_tree = true

      # Update @items_by_id
      @items_by_id[id] = doc

      # Update tree structure
      for parent_id, parent_metadata of doc.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}
        @tree_structure[parent_id][parent_metadata.order] = id

      @_setFilterPathsNeedsUpdate()

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

      delete @items_by_id[id]

      # Remove from tree_structure
      delete @tree_structure[id]

      # Remove from tree structure any pointer to item
      for parent_id, parent_metadata of item_obj.parents
        # Make sure parent still exist
        if @tree_structure[parent_id]?
          # Make sure still pointing to item
          if @tree_structure[parent_id][parent_metadata.order] == id
            delete @tree_structure[parent_id][parent_metadata.order]

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]

      @_setFilterPathsNeedsUpdate()

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

      @_setFilterPathsNeedsUpdate()

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
      @_rebuildGridTree()
    else
      # @_update_filter_paths() is called in @_rebuildGridTree() so
      # there's no need to call it again if rebuild performed.
      # We call @_update_filter_paths() on @_rebuildGridTree() since we want the
      # filter to be ready when the `rebuild` event is emitted.
      @_update_filter_paths()

    @logger.debug "Flush: done"

    @_flushing = false

    Tracker.nonreactive =>
      @_flush_counter.set(@_flush_counter.get() + 1)

    @emit "flush"

  _initDataStructure: () ->
    @items_by_id = {}
    @tree_structure = {}

    for item in @collection.find().fetch()
      @items_by_id[item._id] = item

      for parent_id, parent_metadata of item.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}

        if parent_metadata.order? and _.isNumber parent_metadata.order
          @tree_structure[parent_id][parent_metadata.order] = item._id

  _getGridTreeSignature: -> (_.map @grid_tree, (item) -> item[2] + "." + item[3]).join("\n")

  _rebuildGridTree: () ->
    @emit "pre_rebuild"

    previous_signature = @_getGridTreeSignature()

    @grid_tree = []
    @_items_ids_map_to_grid_tree_indices = {}

    if @tree_structure[0]?
      @_buildNode @tree_structure[0], 0, "/"

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

    @_update_filter_paths()

    @emit "rebuild", diff

  _buildNode: (node, level, node_path) ->
    child_orders = (_.keys node).sort(numSort)

    if level == 0 or node_path of @_expanded_paths # top level always open
      for child_order in child_orders
        child_id = node[child_order]
        child = @items_by_id[child_id]
        expandable = (child_id of @tree_structure) and _.size(@tree_structure[child_id]) > 0
        path = node_path + child_id + "/"
        expand_state = -1
        if expandable
          if path of @_expanded_paths
            expand_state = 1
          else
            expand_state = 0
        
        index = @grid_tree.push([child, level, path, expand_state]) - 1

        if not @_items_ids_map_to_grid_tree_indices[child_id]?
          @_items_ids_map_to_grid_tree_indices[child_id] = []
        @_items_ids_map_to_grid_tree_indices[child_id].push(index)

        if child_id of @tree_structure
          @_buildNode(@tree_structure[child_id], level + 1, "#{node_path}#{child_id}/")

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

  _init: ->
    if @_initialized or @_destroyed
      return

    # Init filter tracker before the data structure and the tree
    # so in the end of _rebuildGridTree we will build the filter
    # if one was set before init
    @_init_filter_tracker()

    @_initDataStructure()

    @_init_items_tracker()
    @_init_flush_orchestrator()

    @_init_foreign_keys_trackers()

    @_initialized = true

    Meteor.setTimeout =>
      Tracker.nonreactive =>
        if not @_destroyed and @_get_need_flush() == 0
          # No needed flush for the given time after init can mean 2 things:
          #
          # 1. No items exist for this grid
          # 2. All data from subscriptions was ready before observer (@_init_items_tracker)
          #    was set, as a result, no flush data related flush was required, and
          #    grid wasn't built for initial payload. (In this case all data
          #    loaded by @_initDataStructure).

          if not _.isEmpty @items_by_id
            # If we have data already, build the tree accordingly

            # Set filter paths needs update so the @_update_filter_paths call at the end of
            # _rebuildGridTree will update the paths (otherwise it'll skip) 
            @_setFilterPathsNeedsUpdate()
            @_rebuildGridTree()

          # We call _set_need_flush here to make sure the first flush will
          # occur even if we have no data for the grid.
          # This is important since grid_control rely on the first `flush`
          # event to triggers its `ready` event/state.

          # Note: Data is considered ready by grid_control the first time
          # @_init_flush_orchestrator triggers flush.
          @_set_need_flush()
    , 250

    @emit "init"

  destroy: ->
    if @_destroyed
      return
    @_destroyed = true

    if @_items_tracker?
      @_items_tracker.stop()
      @_items_tracker = null # As of Meteor 1.0.4 observers handles don't have
                             # computation-like stopped attribute. Threfore we
                             # set _items_tracker back to null, so we can test
                             # that it's stopped.

    if @_flush_orchestrator?
      @_flush_orchestrator.stop()

    @_destroy_filter_manager()

    @_destroy_foreign_keys_trackers()

    @emit "destroyed"

  # ** Tree info **
  getDescendantsItemsIds: (item_id, inclusive=false, ids_arr=null, _initial=true) ->
    # Returns an array of all item_id descendants ids

    # If inclusive is true the array will include also item_id

    # Not filter aware

    # Not reactive

    if ids_arr?
      ids_arr = ids_arr
    else
      ids_arr = []

    if inclusive
      ids_arr.push item_id

    if @tree_structure[item_id]?
      for order, child_id of @tree_structure[item_id]
        @getDescendantsItemsIds child_id, true, ids_arr, false

    if _initial
      return _.uniq ids_arr

  itemIdHasChildren: (item_id) ->
    # Reactive resource

    # Not filters aware, calculating whether an item
    # that **isn't on the grid** has filtered decendents
    # is too expensive and we don't have use cases
    # that requires this information.

    # To check whether items that are on the grid has
    # children in a filters aware mode use: pathHasChildren()
    # or getItemHasChildren()

    # Note: if item doesn't exist we return false here.
    @invalidateOnFlush()

    if (item_id of @tree_structure) and (_.size(@tree_structure[item_id]) > 0)
      return true

    return false

  pathExist: (path) ->
    # Note: not filters aware, not reactive

    # return true if path exists false otherwise
    path = helpers.normalizePath path

    path_array = helpers.getPathArray(path)
    current_node = @tree_structure[0]
    while path_array.length > 0
      cur_id = path_array.shift()

      next_node = null
      for order, item_id of current_node
        if item_id == cur_id
          next_node = @tree_structure[cur_id]

          break

      if next_node?
        current_node = next_node
      else if not(next_node is null) and path_array.length == 0
        # Do nothing, path is a leaf, while loop is done here
      else
        return false

    return true

  pathPassFilter: (path) ->
    if not path?
      @logger.debug("No path provided to pathPassFilter")

      return false

    filter_exist = Tracker.nonreactive =>
      if @filter.get()?
        return true

      return false

    if not filter_exist or not @_filter_items_ids?
      # if no filter applied, all items are passing
      return true

    item_id = helpers.getPathItemId(path)

    if item_id of @_filter_items_ids or @_hasPassingFilterDecendents(item_id)
      return true

    return false

  pathHasChildren: (path) ->
    # !important: reliable only for visible paths - for hidden/non existing
    # paths will return 0 even if path actually has children

    # Returns 0 if path is a leaf, hidden, hidden by filter or doesn't exist
    #         1 if path has children
    #         2 if path has children - but all are hidden by active filter

    # Reactive resource

    # Filters aware (filters reactivity results from @getItemRowByPath())

    # If inside a computation, should invalidate when grid
    # changes
    @invalidateOnFlush()

    item_row = @getItemRowByPath path
    if item_row?
      return @getItemHasChildren item_row

    return 0

  pathExpandable: (path) ->
    # !important: works only on visible paths

    # Reactive resource

    # Filters aware

    @pathHasChildren(path) == 1

  # ** Grid tree info **
  # Reminder: Grid tree is the single dimensional representation of the tree
  # stored in @grid_tree. The word Item follows slick grid terminology (that
  # requires us to provide it with getItem() method in the data source object).
  # Do not confuse item below with the tree items that stored in the collection.
  getItem: (id) -> @grid_tree[id][0]

  getItemWithForeignKeys: (row_id, foreign_keys) ->
    @extendItemForeignKeys @getItem(row_id),
      in_place: false
      foreign_keys: foreign_keys

  getItemId: (id) -> @getItem(id)._id

  getItemPath: (id) ->
    @grid_tree[id][2]

  getItemRowByPath: (path) ->
    # Return the index of path in @grid_tree note: if parent not expanded or if path not exist will return null
    path = helpers.normalizePath path

    item_id = helpers.getPathItemId path

    item_rows_in_tree = @_items_ids_map_to_grid_tree_indices[item_id]
    item_paths = _.map item_rows_in_tree, (row) => @getItemPath(row)
    item_paths_to_rows_in_tree =_.object item_paths, item_rows_in_tree

    if path of item_paths_to_rows_in_tree
      return item_paths_to_rows_in_tree[path]
    else
      return null

  getItemIdPath: (item_id) ->
    # Returns one of the paths that leads to the requested item_id
    # the path that is picked picked arbitrarily.
    #
    # Will return null if no such item_id in the tree.

    if item_id == "0"
      return "/"

    path = []

    while item_id != "0"
      if not (cur_item = @items_by_id[item_id])?
        if path.length > 0
          # If path is not empty, original item_id param exists but
          # we can't find the chain to the root
          @logger.warn "getItemIdPath reached a broken chain"

        return null

      path.unshift(item_id)

      for parent_id of cur_item.parents
        item_id = parent_id

        break

    return GridData.helpers.joinPathArray path

  getItemHasChildren: (id) ->
    # Reactive resource

    # Returns 0 if item is a leaf or hidden by filter
    #         1 if item has children
    #         2 if item has children - but all are hidden by active filter

    # Filters aware

    # Taken care by @itemIdHasChildren()
    # @invalidateOnFlush()

    has_children = @itemIdHasChildren @getItemId(id)

    active_filter = @isActiveFilter()
    filter_paths = @getFilterPaths()

    path = helpers.normalizePath(path)

    if not has_children
      return 0

    if not active_filter
      return 1

    if filter_paths[id][0] in [1, 2] # has passing filter decendents
      return 1

    # appears as leaf, but has children - all filtered
    return 2

  getItemLevel: (id) -> @grid_tree[id][1]

  getLength: -> @grid_tree.length

  getNextItem: (id) ->
    # Returns null if id is the last item (last visible item if filters enabled)
    # Filter aware

    # Reactive resource

    # If inside a computation, should invalidate when grid
    # changes
    @invalidateOnFlush()

    next_item_row = id + 1

    if @isActiveFilter()
      # If there's an active filter, look for visible prev item
      filter_paths = @getFilterPaths()

      # XXX Note that we have in filter_paths info that can be used to optimize
      # this (info about which is first/last visible)
      while next_item_row < @getLength()
        if filter_paths[next_item_row][0] > 0 # means passing filter
          break

        next_item_row += 1     

    if next_item_row >= @getLength()
      return null

    return next_item_row

  getPreviousItem: (id) ->
    # Returns null if id is the first item (first visible item if filters enabled)
    # Filter aware

    # Reactive resource

    # If inside a computation, should invalidate when grid
    # changes
    @invalidateOnFlush()

    previous_item_row = id - 1

    if @isActiveFilter()
      # If there's an active filter, look for visible next item
      filter_paths = @getFilterPaths()

      # XXX Note that we have in filter_paths info that can be used to optimize
      # this (info about which is first/last visible)
      while previous_item_row >= 0
        if filter_paths[previous_item_row][0] > 0 # means passing filter
          break

        previous_item_row -= 1

    if previous_item_row < 0
      return null

    return previous_item_row

  # ** Search **
  search: (term, fields=null, exclude_filtered_paths=false) ->
    # term should be a regex
    # fields should be array of fields names or null.
    # If fields is null we'll look for term in all fields.
    paths = []

    if not _.isRegExp(term)
      throw @_error "wrong-input", "search() supports only regular expressions as term argument"

    if fields? and not _.isArray(fields)
      throw @_error "wrong-input", "search() `fields` argument must be array or null"

    _search = (node, path) ->
      # Recursively find paths with fields matching term

      keys = _.keys(node).sort(numSort) # search in right order to have result paths array in right order
      for order in keys
        child_id = node[order]

        if exclude_filtered_paths and @_filter_items_ids?
          if not (child_id of @_filter_items_ids or @_hasPassingFilterDecendents(child_id))
            continue

        child_path = "#{path}#{child_id}/"
        child = @items_by_id[child_id]

        if fields?
          for field in fields
            if child[field]? and term.test(child[field])
              paths.push child_path

              break
        else
          for field, value of child
            if term.test(value)
              paths.push child_path

              break

        if @tree_structure[child_id]?
          _search.call @, @tree_structure[child_id], child_path

    _search.call @, @tree_structure[0], "/"

    return paths

  # ** Tree view ops on paths **
  isPathVisible: (path) ->
    # Returns true if item is in the visible tree
    @getItemRowByPath(path)?

  getPathLevel: (path) ->
    # XXX Can be optimized...
    path = helpers.normalizePath path

    return @getItemLevel @getItemRowByPath path

  getPathIsExpand: (path) ->
    # !important: works correctly only for visible paths

    # Reactive resource

    # Filters aware

    path = helpers.normalizePath(path)

    if helpers.isRootPath path
      return true

    @invalidateOnFlush()

    active_filter = @isActiveFilter()
    filter_paths = @getFilterPaths()

    expanded = path of @_expanded_paths

    if not expanded
      return false

    # If marked as expanded, it is expanded if it actually has children
    return @pathHasChildren path

  expandPath: (path) ->
    path = helpers.normalizePath path

    if helpers.isRootPath path
      # root always expanded
      return

    if @pathExist path
      for ancestor_path in helpers.getAllAncestorPaths(path)
        if not(ancestor_path of @_expanded_paths)
          @_structure_changes_queue.push ["expand_path", [ancestor_path]]
          @_set_need_flush()
    else
      @_error "unknown-path", "Can't expand unknown path: #{path}", {path: path}

    return

  collapsePath: (path) ->
    path = helpers.normalizePath(path)

    if helpers.isRootPath path
      # root always expanded
      return

    if path of @_expanded_paths
      @_structure_changes_queue.push ["collapse_path", [path]]
      @_set_need_flush()

  getPathDetails: (path) ->
    path = helpers.normalizePath(path)

    # Avoid non O(1) details unless really necessary.
    # Avoid reactive resources.

    item_id = helpers.getPathItemId(path)
    parent_id = helpers.getPathParentId path
    item = @items_by_id[item_id]
    order = item.parents[parent_id].order

    details =
      item_id: item_id
      parent_id: parent_id
      order: order

    return details

  _getNeighboringPath: (path, prev) ->
    # returns the prev path if prev = true; the next path
    # otherwise.
    # Return null if there's no such path or if provided path is unknown

    # Filters aware
    row_id = @getItemRowByPath(path)

    if not row_id?
      return null

    if prev
      item = @getPreviousItem row_id
    else
      item = @getNextItem row_id

    if not item?
      return null

    return @getItemPath item

  getNextPath: (path) -> @_getNeighboringPath(path, false)

  getPreviousPath: (path) -> @_getNeighboringPath(path, true)

  getNextLteLevelPath: (path) ->
    # Gets a path and returns the next path in the tree
    # that is positioned in either the same level or in
    # a lower level.

    # Returns null if there's no such path or if provided
    # path doesn't exist.

    # Filters aware

    # If inside a computation, should invalidate when grid
    # changes
    @invalidateOnFlush()

    row_id = @getItemRowByPath(path)

    if not row_id?
      return null

    item_level = @getItemLevel(row_id)

    active_filter = @isActiveFilter()
    filter_paths = @getFilterPaths()

    next_item_row = row_id + 1
    while next_item_row < @getLength()
      if active_filter
        # Check if item passed the filter

        # XXX Note that we have in filter_paths info that can be used to optimize
        # this (info about which is first/last visible)
        if filter_paths[next_item_row][0] == 0 # means not passing filter
          next_item_row += 1
          continue

      if @getItemLevel(next_item_row) <= item_level
        return @getItemPath(next_item_row)

      next_item_row += 1

    # None found
    return null

  # ** Tree view ops on items **
  getItemIsExpand: (id) -> @getPathIsExpand(@getItemPath(id))

  toggleItem: (id) ->
    if @getItemIsExpand id
      @collapseItem id
    else
      @expandItem id

  expandItem: (id) -> @expandPath(@getItemPath id)

  collapseItem: (id) -> @collapsePath(@getItemPath id)

  # ** Tree ops **
  edit: (edit_req) ->
    [row, cell, grid, item] = [edit_req.row, edit_req.cell, edit_req.grid, edit_req.item]
    col_field = grid.getColumns()[cell].id
    item_id = item._id

    update = {$set: {}}
    update["$set"][col_field] = item[col_field]

    edit_failed = (err) =>
      @_data_changes_queue.push ["update", [item_id, [col_field]]]

      @_set_need_flush()

      @emit "edit-failed", err

    executed = @collection.update item._id, update, (err) =>
      if err
        # observeChanges doesn't revert failed edits
        # See: https://github.com/meteor/meteor/issues/4282
        edit_failed(err)

    if executed is false
      # executed is false if edit blocked by events hooks
      edit_failed(@_error "edit-blocked-by-hook", "Edit blocked by hook")

  addChild: (path, fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, child_id, child_path)

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("addChild"), path, fields, (err, child_id) ->
      if err?
        helpers.callCb cb, err
      else
        helpers.callCb cb, err, child_id, path + child_id + "/"

  addSibling: (path, fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, sibling_id, sibling_path)

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("addSibling"), path, fields, (err, sibling_id) ->
      if err?
        helpers.callCb cb, err
      else
        helpers.callCb cb, err, sibling_id, helpers.getParentPath(path) + sibling_id + "/"

  removeParent: (path, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err)
    path = helpers.normalizePath(path)
    Meteor.call @getCollectionMethodName("removeParent"), path, (err) ->
      helpers.callCb cb, err

  movePath: (path, new_location, cb, usersDiffConfirmationCb) ->
    # Put path in the position provided in new_location.

    # new_location can be either object of the form:
    # {
    #   parent: "parent_id",
    #   order: order_int
    # }
    #
    # or an array of the form: [new_position_path, relation] where
    # new_position_path is a path and relation is one of -1, 0, 1
    # If relation is:
    #   0:  path will be placed as the first child of new_position_path
    #   -1: path will be placed before new_position_path
    #    1: path will be placed after new_position_path
    #   2:  path will be placed as the last child of new_position_path

    # If new_location is array

    # If cb provided, cb will be called when excution completed:
    # cb args will be determined by new_location type:
    # if new_location is an array: cb(err, new_path)
    #   new_path we will determine new_location based on new_position_path and relation.
    # if new_location is an object: cb(err)

    # if usersDiffConfirmationCb is provided, if users of path and
    # provided new_location aren't the same the move operation will be
    # suspended and usersDiffConfirmationCb will be called with the following
    # args:
    #   usersDiffConfirmationCb(item_id, target_id, diff, proceed, cancel)
    #   item_id: the id of the item we move
    #   target_id: the id of the new parent
    #   diff: will be null if users are equal otherwise it'll be of the form:
    #         {
    #           absent: [uid, uid, ...] # can be empty
    #           alien: [uid, uid, ...] # can be empty
    #         }
    #         absent lists users that exists in path but don't in new_location
    #         alien lists users that don't exist in path but do in new_location
    #   proceed: a callback, if called, move operation will continue
    #   cancel: a callback, if called, move operation will cancel
    # if new location is the root we ignore usersDiffConfirmationCb
    path = helpers.normalizePath(path)

    new_location_type = null
    new_location_obj = null
    new_path = null
    if not _.isArray new_location
      new_location_type = "object"
      new_location_obj = new_location
    else
      new_location_type = "array"

      path_details = @getPathDetails path

      [position_path, relation] = new_location
      position_path = helpers.normalizePath(position_path)

      position_path_details = @getPathDetails position_path
      if position_path == "/"
        # edge case position_path == "/" parent is "0"
        new_location_obj =
          parent: "0"

        # ignore -1/1 relations (assume only 0/2 are possible)
        if relation == 0
          new_location_obj.order = 0

        new_path = "/#{path_details.item_id}/"
      else if relation in [0, 2]
        new_location_obj =
          parent: position_path_details.item_id

        if relation == 0
          new_location_obj.order = 0

        new_path = "#{position_path}#{path_details.item_id}/"
      else # relation -1 or 1
        new_location_obj =
          parent: position_path_details.parent_id
          order: position_path_details.order

        if relation == 1
          new_location_obj.order += 1

        new_path = "#{helpers.getParentPath(position_path)}#{path_details.item_id}/"

    performOp = =>
      Meteor.call @getCollectionMethodName("movePath"), path, new_location_obj, (err) ->
        if new_location_type == "object"
          helpers.callCb cb, err
        else
          if not err?
            helpers.callCb cb, err, new_path
          else
            helpers.callCb cb, err

    if not(usersDiffConfirmationCb? and _.isFunction usersDiffConfirmationCb)
      # Perform operation right away.
      performOp()
    else
      path_item_id = helpers.getPathItemId(path)
      new_parent_item_id = new_location_obj.parent

      if new_parent_item_id == "0"
        # moving to root, no diff as root isn't a real item
        # perform op right away

        @logger.debug "usersDiffConfirmationCb skipped, moving item to root"

        return performOp()

      path_item_users = @items_by_id[path_item_id].users
      new_parent_item_users = @items_by_id[new_parent_item_id].users

      diff =
        absent: _.difference path_item_users, new_parent_item_users
        alien: _.difference new_parent_item_users, path_item_users

      if _.isEmpty(diff.absent) and _.isEmpty(diff.alien)
        # no diff perform op right away

        @logger.debug "usersDiffConfirmationCb skipped, no diff"

        return performOp()

      proceed = ->
        performOp()

      cancel = =>
        @logger.debug "movePath cancelled by usersDiffConfirmationCb"

        # call cb with error
        helpers.callCb cb, @_error("operation-cancelled", "movePath operation cancelled by usersDiffConfirmationCb")

      usersDiffConfirmationCb(path_item_id, new_parent_item_id, diff, proceed, cancel)

  sortChildren: (path, field, asc_desc, cb) ->
    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("sortChildren"), path, field, asc_desc, (err) ->
      helpers.callCb cb, err

  bulkUpdate: (items_ids, modifier, cb) ->
    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("bulkUpdate"), items_ids, modifier, (err, changed_items_count) ->
      helpers.callCb cb, err, changed_items_count

  getItemMetadata: (index) ->
    # Get the metadata from each one of the generators
    generators_metadata =
      _.map @_metadataGenerators, (generator) =>
        generator(@grid_tree[index][0], @grid_tree[index], index)

    # Merge metadata, give recent registered generators priority
    if not _.isEmpty generators_metadata
      # the receiver obj, new one is required, since we do later deep merge of style
      # (otherwise last one will become the first one)
      generators_metadata.unshift {}
      metadata = _.extend.apply(_, generators_metadata)

    # deep merge the `style` metadata
    styles = _.map generators_metadata, (metadata) -> metadata.style
    styles = _.without styles, undefined
    if not _.isEmpty styles
      styles.unshift {} # receiver obj
      metadata.style = _.extend.apply(_, styles)
    else
      delete metadata.style

    # union all `cssClasses` metadata
    cssClasses = _.map generators_metadata, (metadata) -> metadata.cssClasses
    cssClasses = _.without cssClasses, undefined
    if not _.isEmpty cssClasses
      metadata.cssClasses = _.union.apply(_, cssClasses)
    else
      delete metadata.cssClasses

    return metadata

  registerMetadataGenerator: (cb) ->
    # Register metadata function of the form cb(item, item_meta_details, index),
    # that will be called with the item index, and should return an object
    # of item meta data.
    # Important! must return an object, if no metadata for item, return empty
    # object.

    # Returns true if cb added, false otherwise
    if _.isFunction cb
      if not(cb in @_metadataGenerators)
        @_metadataGenerators.push cb

        return true
      else
        @logger.warn "registerMetadataGenerator provided an already registered generator"
    else
      @logger.warn "registerMetadataGenerator was called with no callback"

    return false

  unregisterMetadataGenerator: (cb) ->
    @_metadataGenerators = _.without @_metadataGenerators, cb

# ** Misc. **
  getCollectionMethodName: (name) -> helpers.getCollectionMethodName(@collection, name)

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
  subscribeDefaultGridSubscription:  ->
    # subscribeDefaultGridSubscription: (collection, arg1, arg2, ...)
    #
    # Subscribes to the subscription created by GridDataCom.setGridPublication
    # as long as the `name` option didn't change.
    #
    # Arguments that follows the collection argument will be used as the subscription
    # args.
    args = _.toArray(arguments).slice(1)

    args.unshift helpers.getCollectionPubSubName(@collection)

    Meteor.subscribe.apply @, args