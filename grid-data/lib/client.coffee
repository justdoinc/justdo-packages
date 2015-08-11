helpers = share.helpers
numSort = (a, b) -> a - b

GridData = (collection) ->
  EventEmitter.call this

  @collection = collection

  @_initialized = false
  @_destroyed = false

  @_items_tracker = null
  @_flush_orchestrator = null
  @_need_flush = new ReactiveVar(0)

  @_items_needs_update = [] # an array of array of the form: [item_id, [list of changed fields]]
  @_items_with_changed_parents = []
  @_new_items = []
  @_removed_items = []
  @_paths_needs_state_change = {} # keys holds the paths which their collapse/expand state needs to be toggled false value will collapse the path true value will expand it
  @_filter_changed = false

  @items_by_id = {}
  @tree_structure = {}
  @grid_tree = [] # [[item, tree_level, parent_path], ...]
  @_items_ids_map_to_grid_tree_indices = {} # {item_id: [indices in @grid_tree]}
  @_expanded_paths = {} # if path is a key of @_expanded_paths it is expanded regardless of its value

  @_current_filter = null

  # note if users changed the subscription should remove the doc if user lose access
  @_ignore_change_in_fields = ["users"]

  @logger = Logger.get("grid-data")

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
  _idle_time_ms_before_set_need_flush: 30
  _set_need_flush_timeout: null
  _set_need_flush: ->
    if @_set_need_flush_timeout?
      clearTimeout @_set_need_flush_timeout

    @_set_need_flush_timeout = setTimeout =>
      @_need_flush.set(++@_need_flush_count)
    , @_idle_time_ms_before_set_need_flush

  _get_need_flush: ->
    @_need_flush.get()

  _init_items_tracker: ->
    if not @_destroyed and not @_items_tracker
      # build grid tree for first time
      tracker_init = true
      @_items_tracker = @collection.find().observeChanges
        added: (id, fields) =>
          if not tracker_init
            fields._id = id
            @_new_items.push [id, fields]

            @_set_need_flush()

        changed: (id, fields_changes) =>
          fields = _.difference(_.keys(fields_changes), @_ignore_change_in_fields) # remove ignored fields

          # Take care of parents changes
          if "parents" in fields
            @_items_with_changed_parents.push [id, fields_changes.parents]
            fields = _.difference(_.keys(fields), ["parents"]) # remove parents field

          # Regular changes
          if fields.length != 0
            @_items_needs_update.push [id, fields]

          @_set_need_flush()

        removed: (id) =>
          @_removed_items.push id

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

  _flush: () ->
    # perform pending required updates to the internal data structures

    rebuild_needed = false

    non_optimized_updated = false
    non_optimized_update = _.once =>
      # every op can be optimized by manipulating the existing data-structure instead of rebuilding it
      # @_initDataStructure()
      non_optimized_updated = true

    getItemById = (item_id) => @collection.findOne(item_id)

    edited_parents_of_new_items = {} # XXX
    if @_items_with_changed_parents.length != 0
      #console.log "Parents changed"
      #for item in @_items_with_changed_parents
      #  [item_id, changes] = item
      #  console.log "Parents changed", item_id, changes, getItemById(item_id)

      console.log "Items with changed parents", @_items_with_changed_parents

      intra_parent_order_change = {} # {parent_id: [[item_id, prev_order, new_order], [item_id, new_order]...]...}
      new_to_parent = {} # {parent_id: [[item_id, order], [item_id, order]...]...}
      removed_from_parent = {} # {parent_id: [[item_id, prev_order], [item_id, prev_order],...]}
      for item in @_items_with_changed_parents
        [item_id, new_parents_obj] = item
        prev_item_obj = @items_by_id[item_id]

        # If we don't know this item yet
        if not prev_item_obj?
          edited_parents_of_new_items[item_id] = new_parents_obj
          continue

        prev_parents_obj = prev_item_obj.parents

        for parent_id, new_parent_data of new_parents_obj
          if parent_id of prev_parents_obj
            # existed already under this parent
            if new_parent_data.order == prev_parents_obj[parent_id].order
              # No changes to this parent
              continue
            else
              # intra-parent order change
              if not intra_parent_order_change[parent_id]?
                intra_parent_order_change[parent_id] = []
              intra_parent_order_change[parent_id].push [item_id, prev_parents_obj[parent_id].order, new_parent_data.order]
          else
            # new to this parent
            if not new_to_parent[parent_id]?
              new_to_parent[parent_id] = []
            new_to_parent[parent_id].push [item_id, new_parent_data.order]

            # # Save a copy of the pre flush parent children order to original_node_order, if we haven't did so already
            # if not original_node_order[parent_id]?
            #   original_node_order[parent_id] = _.extend {}, @tree_structure[parent_id]

            # # Update @items_by_id
            # prev_parents_obj[parent_id].order = new_parent_data[parent_id].order

            # # Update tree structure
            # @tree_structure[parent_id][parent_metadata.order] = new_parent_data[parent_id].order

        for parent_id, prev_parent_obj of prev_parents_obj
          if not(parent_id of new_parents_obj)
            # removed item
            if not removed_from_parent[parent_id]?
              removed_from_parent[parent_id] = []
            removed_from_parent[parent_id].push [item_id, prev_parent_obj.order]

        # console.log new_parent_data, new_parents_obj

        console.log item_id, new_parents_obj, prev_parents_obj

      console.log "INTRA PARENT ORDER CHANGE", intra_parent_order_change
      console.log "NEW TO PARENT", new_to_parent
      console.log "REMOVED FROM PARENT", removed_from_parent
      # intra_parent_order_change = {} # [parent_id, item_id, new_order]
      # new_to_parent = {} # [parent_id, item_id, order]
      # removed_from_parent = {} # [parent_id, item_id]

      # XXX original_node_order = {}
      for parent_id, changed_children_order of intra_parent_order_change
        # XXX Save a copy of the pre flush parent children order to original_node_order
        # original_node_order[parent_id] = _.extend {}, @tree_structure[parent_id]

        for child_new_order in changed_children_order
          [child_id, prev_order, new_order] = child_new_order

          # Update @items_by_id
          @items_by_id[child_id].parents[parent_id].order = new_order

          # Update tree structure
          @tree_structure[parent_id][new_order] = child_id

          # If still attached to old order under @tree_structure delete it (during the update it might no longer be true in some circumctences)
          if @tree_structure[parent_id][prev_order] == child_id
            delete @tree_structure[parent_id][prev_order]

      for parent_id, new_children of new_to_parent
        for child_new_order in changed_children_order
          [child_id, order] = child_new_order

          # Update @items_by_id
          @items_by_id[child_id].parents[parent_id].order = order

          # Update tree structure
          if not @tree_structure[parent_id]?
            @tree_structure[parent_id] = {}
          @tree_structure[parent_id][order] = child_id

      for parent_id, new_children of new_to_parent
        for new_child in new_children
          [child_id, order] = new_child

          # Update @items_by_id
          @items_by_id[child_id].parents[parent_id].order = order

          # Update tree structure
          if not @tree_structure[parent_id]?
            @tree_structure[parent_id] = {}
          @tree_structure[parent_id][order] = child_id

      for parent_id, removed_children of removed_from_parent
        for removed_child in removed_children
          [child_id, prev_order] = removed_child

          # Update @items_by_id
          delete @items_by_id[child_id].parents[parent_id]

          # Update tree structure
          # Make sure no other item moved to removed position already
          if @tree_structure[parent_id][prev_order] == child_id
            delete @tree_structure[parent_id][prev_order]

          if _.size(@tree_structure[parent_id]) == 0
            delete @tree_structure[parent_id]

      # compare old node order with new order
      # for node_parent, original_children_order of original_node_order
      #   current_children_order = @tree_structure[node_parent]

      #   current_size = _.size(current_children_order)
      #   original_size = _.size(original_children_order)

      #   console.log current_size, original_size
      #   if current_size == original_size
      #     if _.isEqual(_.values(current_children_order), _.values(original_children_order))
      #       console.log "Same order, nothing to do"
      #     else
      #       console.log "Different order, update grid_tree"
      #   else
      #     # Logically, current_size can be only smaller.
      #     console.log "Some items removed"
        
      #   console.log current_children_order, original_children_order

      # non_optimized_update()
      rebuild_needed = true

    if @_removed_items.length != 0
      #console.log "Removed Item"
      for item_id in @_removed_items
        # Update @items_by_id
        item_obj = @items_by_id[item_id]

        delete @items_by_id[item_id]

        # Remove from tree_structure
        delete @tree_structure[item_id]

        # Remove from tree structure any pointer to item
        for parent_id, parent_metadata of item_obj.parents
          # Make sure still pointing to item
          if @tree_structure[parent_id][parent_metadata.order] == item_id
            delete @tree_structure[parent_id][parent_metadata.order]


      console.log "REMOVED ITEMS", @_removed_items

      # non_optimized_update()
      rebuild_needed = true
    
    if @_new_items.length != 0
      #console.log "New Item"
      # console.log "New Items", @_new_items

      # for item in @_new_items
      for item in @_new_items
        [item_id, item_obj] = item

        # If parents object changed during this flush
        if edited_parents_of_new_items[item_id]?
          item_obj.parents = edited_parents_of_new_items[item_id]

        # Update @items_by_id
        @items_by_id[item_id] = item_obj

        # Update tree structure
        for parent_id, parent_metadata of item_obj.parents
          if not @tree_structure[parent_id]?
            @tree_structure[parent_id] = {}
          @tree_structure[parent_id][parent_metadata.order] = item_id

      rebuild_needed = true

    if @_filter_changed is true
      # console.log "Filter Changed", @_current_filter

      non_optimized_update()
      rebuild_needed = true

    if not(_.isEmpty(@_paths_needs_state_change)) and not non_optimized_updated
      # if non_optimized_updated the internal strucutres got rebuilt already
      # with all needed updates

      # no need to build internal data structure for _paths_needs_state_change hance
      # we don't call @non_optimized_updated()

      for path, new_state of @_paths_needs_state_change
        if new_state == false and path of @_expanded_paths
          delete @_expanded_paths[path]

        if new_state == true and not(path of @_expanded_paths)
          @_expanded_paths[path] = true

      rebuild_needed = true

    if @_items_needs_update.length != 0 and not non_optimized_updated
      # if non_optimized_updated the internal strucutres got rebuilt already
      # with all needed updates
      for item in @_items_needs_update
        [item_id, fields] = item

        # update internal data structure
        item = getItemById(item_id)

        item_pass_filter = @_item_pass_filter item # check whether before update item passed the filter

        if item? # if false, item removed already, expect rebuild later
          if @_item_pass_filter(@items_by_id[item_id]) != @_item_pass_filter(item)
            # if filtering state of item changed - we must rebuild the tree (changes the tree structure)
            non_optimized_update()
            rebuild_needed = true
          else
            _.extend @items_by_id[item_id], item

            for removed_field in _.difference(_.keys(@items_by_id[item_id]), _.keys(item))
              delete @items_by_id[item_id][removed_field]

        if @_items_ids_map_to_grid_tree_indices[item_id]?
          for row in @_items_ids_map_to_grid_tree_indices[item_id]
            @emit "grid-item-changed", row, fields

    @_items_needs_update = []
    @_items_with_changed_parents = []
    @_new_items = []
    @_removed_items = []
    @_paths_needs_state_change = {}
    @_filter_changed = false

    if rebuild_needed
      @_rebuildGridTree()

    # we use this even for unittesting
    @emit "_flush"

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

    if @_current_filter?
      @_filterNodeItems @tree_structure[0]

  _item_pass_filter: (item) ->
    # item can be either string or object
    # will be interepreted as item_id in case of string
    if @_current_filter?
      if _.isString(item)
        item = @items_by_id[item]

      field_val = item[@_current_filter.field]

      if not field_val?
        return false
      
      for valid_val in @_current_filter.values
        if field_val is valid_val
          return true

      return false

    # if no filter defined return true
    return true

  _filterNodeItems: (node) ->
    # Recursively removes @tree_structure items that don't pass @_current_filter
    # and don't have descendants that match the filter.
    found_matching_descendant = false

    for order, child_id of node
      pass_filter = @_item_pass_filter child_id
      if @tree_structure[child_id]?
        # it won't exist if we filtered it already
        descendant_pass_filter = @_filterNodeItems @tree_structure[child_id]
      else
        descendant_pass_filter = false

      if pass_filter or descendant_pass_filter
        found_matching_descendant = true
      else
        delete node[order]
        delete @tree_structure[child_id]

    return found_matching_descendant

  _rebuildGridTree: () ->
    @emit "pre_rebuild"

    @grid_tree = []
    @_items_ids_map_to_grid_tree_indices = {}

    if @tree_structure[0]?
      @_buildNode @tree_structure[0], 0, "/"

    @emit "rebuild"

  _buildNode: (node, level, node_path) ->
    child_orders = (_.keys node).sort(numSort)

    if level == 0 or node_path of @_expanded_paths # top level always open
      for child_order in child_orders
        child_id = node[child_order]
        child = @items_by_id[child_id]
        index = @grid_tree.push([child, level, node_path + child_id + "/"]) - 1

        if not @_items_ids_map_to_grid_tree_indices[child_id]?
          @_items_ids_map_to_grid_tree_indices[child_id] = []
        @_items_ids_map_to_grid_tree_indices[child_id].push(index)

        if child_id of @tree_structure
          @_buildNode(@tree_structure[child_id], level + 1, "#{node_path}#{child_id}/")

  _init: ->
    if @_initialized or @_destroyed
      return
    @_initialized = true

    @_initDataStructure()
    @_rebuildGridTree() # build tree based on the data structure for the first time

    @_init_items_tracker()
    @_init_flush_orchestrator()

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

    @emit "destroyed"

  # ** Tree info **
  itemIdHasChildern: (item_id) ->
    # size will be 0 if filter applied and as a result all childrens of node got filtered
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
    # Return the index of path in @grid_tree note: if parent not expanded or if path not exist will return false
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

  # ** filters **
  _filter: (field, values) ->
    @_current_filter =
      field: field
      values: values

    @_filter_changed = true

    @_set_need_flush()

  clearFilter: () ->
    @_current_filter = null

    @_filter_changed = true

    @_set_need_flush()

  filter: (filter) ->
    # Filter presented tree items
    #
    # Item pass the filter if it or one of its descendants pass the the filter
    # test.
    #
    # filter format: { field: { $in: [<value1>, <value2>, ... <valueN> ] } }
    #
    # Note:
    #  * Only one field supported at the moment
    #  * Value should be an exact match of one of the filters values

    if filter? and _.isObject filter
      fields = _.keys(filter)
      if fields.length == 1
        field = fields[0]
        if field of @collection.simpleSchema()._schema
          if filter[field].$in?
            values = filter[field].$in
            if _.isArray(values) and values.length > 0
              @_filter(field, values)
            else
              @logger.error "$in parameter should be non-empty array"
              throw new Meteor.Error "wrong-input", "$in parameter should be non-empty array"
          else
            @logger.error "No values specified for field"
            throw new Meteor.Error "wrong-input", "No values specified for field"
        else
          @logger.error "Field `#{field}` doesn't exist"
          throw new Meteor.Error "wrong-input", "Field `#{field}` doesn't exist"
      else if fields.length > 1
        @logger.error "At the moment, only single field filters are supported"
        throw new Meteor.Error "wrong-input", "At the moment, only single field filters are supported"
      else if fields.length == 0
        @logger.error "No field provided for the filter"
        throw new Meteor.Error "wrong-input", "No field provided for the filter"
    else
      @logger.error "filter is not an object"
      throw new Meteor.Error "wrong-input", "filter is not an object"

    return true

  # ** Search **
  search: (term, fields=null) ->
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
        child_path = "#{path}#{child_id}/"
        child = grid_control._grid_data.items_by_id[child_id]

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
  getPathIsExpand: (path) -> helpers.normalizePath(path) of @_expanded_paths

  expandPath: (path) ->
    path = helpers.normalizePath path

    if helpers.isRootPath path
      # root always expanded
      return

    for ancestor_path in helpers.getAllAncestorPaths(path)
      if not(@getPathIsExpand(ancestor_path)) and @pathExpandable(ancestor_path)
        @_paths_needs_state_change[ancestor_path] = true
        @_set_need_flush()

  collapsePath: (path) ->
    path = helpers.normalizePath(path)

    if @getPathIsExpand(path)
      @_paths_needs_state_change[path] = false
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
      @_items_needs_update.push [item_id, [col_field]]
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

  # ** Misc. **
  getCollectionMethodName: (name) -> helpers.getCollectionMethodName(@collection, name)

subscribeDefaultGridSubscription = (collection, condition=null) ->
  # Note: we call Meteor.userId() as last argument.
  # Meteor.userId() is not part of the publication args, used here only to
  # trigger reactivity (re-running this func if called in a computation) when
  # the user changes and make Meteor recognise that the subscription changed.
  Meteor.subscribe helpers.getCollectionPubSubName(collection), condition, Meteor.userId()