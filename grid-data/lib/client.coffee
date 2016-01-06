helpers = share.helpers
numSort = (a, b) -> a - b

GridData = (collection) ->
  EventEmitter.call this

  @collection = collection

  @_initialized = false
  @_destroyed = false

  #
  # Flush managemnt
  #

  @_items_tracker = null
  @_flush_orchestrator = null
  @_need_flush = new ReactiveVar(0)
  @_flushing = false # Will be true during flush process

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

  # note if users changed the subscription should remove the doc if user lose access
  @_ignore_change_in_fields = ["users"]

  @_metadataGenerators = []

  @logger = Logger.get("grid-data")

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
  _need_flush_count: 0
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

  isActiveFilter: -> @filter.get()? # True if there's an active filter, false otherwise

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

  _init_filter_tracker: ->
    # Track changes to current filter query and @_filter_items (the query result set)
    if not @_destroyed and not @_filter_tracker?
      @_filter_tracker = Tracker.autorun =>
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

            fields = _.difference(_.keys(fields), ["parents"]) # remove parents field

          # Regular changes
          if fields.length != 0
            item = @items_by_id[id]

            if item?
              # If item is in the internal data structure, update immediately don't wait
              # for flush.
              # This is very important due to the fact that when there's an active filter,
              # the filter tracker will update the filtered items even when flush is locked
              # as a result, if a structural release will occur
              # (@_perform_temporal_strucutral_flush_lock_release) if data for existing items
              # won't update, it will seems as if items is out of sync with the filter.
              @_updateRowFields id, fields
            else
              #If item is not in the internal data structure yet (added during current flush cycle)
              @_data_changes_queue.push ["update", [id, fields]]

              @_set_need_flush()

        removed: (id) =>
          # @logger.debug "Tracker: Item removed #{id}"

          @_data_changes_queue.push ["remove", [id]]

          @_set_need_flush()

      tracker_init = false

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

    @_initialized = true

    Meteor.setTimeout =>
      Tracker.nonreactive =>
        if not @_destroyed and @_get_need_flush() == 0
          # We call _set_need_flush here to make sure the first flush will
          # occur even if we have no data for the grid (if @_get_need_flush() != 0
          # data exist, and either flushed already or waiting to be flushed).
          # This is important since grid_control rely on the first `flush`
          # event to triggers its `ready` event/state.

          # Note: Data is considered ready by grid_control the first time
          # @_init_flush_orchestrator triggers flush.
          @_set_need_flush()
    , 1000

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

    @emit "destroyed"

  # ** Tree info **
  itemIdHasChildern: (item_id) ->
    (item_id of @tree_structure) and (_.size(@tree_structure[item_id]) > 0)

  pathExist: (path) ->
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
    # return true if path exists and have children
    if @pathExist path
      item_id = helpers.getPathItemId path

      return @itemIdHasChildern item_id

    return false

  pathExpandable: (path) -> @pathHasChildren path # alias to pathHasChildren

  # ** Grid tree info **
  # Reminder: Grid tree is the single dimensional representation of the tree
  # stored in @grid_tree. The word Item follows slick grid terminology (that
  # requires us to provide it with getItem() method in the data source object).
  # Do not confuse item below with the tree items that stored in the collection.
  getItem: (id) -> @grid_tree[id][0]

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

  getItemHasChild: (id) -> @itemIdHasChildern @getItemId(id)

  getItemLevel: (id) -> @grid_tree[id][1]

  getLength: -> @grid_tree.length

  # ** Search **
  search: (term, fields=null, exclude_filtered_paths=false) ->
    # term should be a regex
    # fields should be array of fields names or null.
    # If fields is null we'll look for term in all fields.
    paths = []

    if not _.isRegExp(term)
      throw new Meteor.Error "wrong-input", "search() supports only regular expressions as term argument"

    if fields? and not _.isArray(fields)
      throw new Meteor.Error "wrong-input", "search() `fields` argument must be array or null"

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

  getPathIsExpand: (path) ->
    # IMPORTANT! be careful when using, as path can be expanded
    # but not visible (if one of its ancesors isn't expanded)
    # therefore, if you want to check whether a path is shown
    # use isPathVisible and not this method.
    path = helpers.normalizePath(path)

    path == "/" or path of @_expanded_paths

  expandPath: (path, force=false) ->
    # if force is true we will trigger path expansion even if it isn't
    # yet expandable (useful, when flush lock is on, and we know the
    # item is going to be expandable)
    path = helpers.normalizePath path

    if helpers.isRootPath path
      # root always expanded
      return

    for ancestor_path in helpers.getAllAncestorPaths(path)
      if not(@getPathIsExpand(ancestor_path)) and (@pathExpandable(ancestor_path) or force)
        @_structure_changes_queue.push ["expand_path", [ancestor_path]]
        @_set_need_flush()

  collapsePath: (path) ->
    path = helpers.normalizePath(path)

    if @getPathIsExpand(path)
      @_structure_changes_queue.push ["collapse_path", [path]]
      @_set_need_flush()

  # ** Tree view ops on items **
  getItemIsExpand: (id) -> @getItemPath(id) of @_expanded_paths

  toggleItem: (id) ->
    if @getItemIsExpand id
      @collapseItem id
    else
      @expandItem id

  expandItem: (id) ->
    if @getItemHasChild id
      @expandPath(@getItemPath id)

  collapseItem: (id) ->
    if @getItemHasChild id
      @collapsePath(@getItemPath id)

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
      edit_failed(new Meteor.Error "edit-blocked-by-hook", "Edit blocked by hook")

  addChild: (path, fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, child_id, child_path)

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("addChild"), path, fields, (err, child_id) ->
      if cb?
        if err?
          cb err
        else
          cb err, child_id, path + child_id + "/"

  addSibling: (path, fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, sibling_id, sibling_path)

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("addSibling"), path, fields, (err, sibling_id) ->
      if cb?
        if err?
          cb err
        else
          cb err, sibling_id, helpers.getParentPath(path) + sibling_id + "/"

  removeParent: (path) ->
    path = helpers.normalizePath(path)
    Meteor.call @getCollectionMethodName("removeParent"), path

  movePath: (path, new_location, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err)

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("movePath"), path, new_location, (err) ->
      if cb?
        cb err

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

  sortChildren: (path, field, ascDesc) ->
    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("sortChildren"), path, field, ascDesc, (err) ->
      if cb?
        cb err

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