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
  @_path_state_changed = false # changed to true after a path gets expand/collapse

  @items_by_id = {}
  @tree_structure = {}
  @grid_tree = [] # [[item, tree_level, parent_path], ...]
  @_items_ids_map_to_grid_tree_indices = {} # {item_id: [indices in @grid_tree]}
  @_expanded_paths = {} # if path is a key of @_expanded_paths it is expanded regardless of its value

  # note if users changed the subscription should remove the doc if user lose access
  @_ignore_change_in_fields = ["users"]

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  return @

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
      @_initDataStructure()
      non_optimized_updated = true

    getItemById = (item_id) => @collection.findOne(item_id)

    if @_removed_items.length != 0
      #console.log "Removed Item"
      #for item in @_removed_items
      #  [item_id, changes] = item
      #  console.log "Removed Item", item_id, doc, getItemById(item_id)

      non_optimized_update()
      rebuild_needed = true
    
    if @_new_items.length != 0
      #console.log "New Item"
      #for item in @_new_items
      #  [item_id, changes] = item
      #  console.log "New Item", item_id, doc, getItemById(item_id)

      non_optimized_update()
      rebuild_needed = true

    if @_items_with_changed_parents.length != 0
      #console.log "Parents changed"
      #for item in @_items_with_changed_parents
      #  [item_id, changes] = item
      #  console.log "Parents changed", item_id, changes, getItemById(item_id)

      non_optimized_update()
      rebuild_needed = true

    if @_path_state_changed and not non_optimized_updated
      # if non_optimized_updated the internal strucutres got rebuilt already
      # with all needed updates

      # no need to build internal data structure for _path_state_changed hance
      # we don't call @non_optimized_updated()
      rebuild_needed = true

    if @_items_needs_update.length != 0 and not non_optimized_updated
      # if non_optimized_updated the internal strucutres got rebuilt already
      # with all needed updates
      for item in @_items_needs_update
        [item_id, fields] = item

        # update internal data structure
        item = getItemById(item_id)
        if item? # if false, item removed already, expect rebuild later
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
    @_path_state_changed = false

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

  expandPath: (path) ->
    if not(path of @_expanded_paths)
      @_expanded_paths[path] = true
      @_path_state_changed = true
      @_set_need_flush()

  collapsePath: (path) ->
    if path of @_expanded_paths
      delete @_expanded_paths[path]
      @_path_state_changed = true
      @_set_need_flush()

  getItem: (id) -> @grid_tree[id][0]

  getItemId: (id) -> @getItem(id)._id

  getItemPath: (id) -> @grid_tree[id][2]

  getItemRowByPath: (path) ->
    path_arr = path.split("/")
    path_arr.pop() # remove redundant ""
    item_id = _.last path_arr
    item_rows_in_tree = @_items_ids_map_to_grid_tree_indices[item_id]
    item_paths = _.map item_rows_in_tree, (row) => @getItemPath(row)
    item_paths_to_rows_in_tree =_.object item_paths, item_rows_in_tree

    if path of item_paths_to_rows_in_tree
      return item_paths_to_rows_in_tree[path]
    else
      return null

  getItemIsExpand: (id) -> @getItemPath(id) of @_expanded_paths

  getItemHasChild: (id) -> @getItemId(id) of @tree_structure

  getItemLevel: (id) -> @grid_tree[id][1]

  getLength: -> @grid_tree.length

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

  edit: (edit_req) ->
    [row, cell, grid, item] = [edit_req.row, edit_req.cell, edit_req.grid, edit_req.item]
    col_field = grid.getColumns()[cell].id
    item_id = item._id

    update = {$set: {}}
    update["$set"][col_field] = item[col_field]

    @collection.update item._id, update, (err) =>
      if err
        # observeChanges doesn't revert failed edits
        @_items_needs_update.push [item_id, [col_field]]
        @_set_need_flush()

        @emit "edit-failed", err

  getCollectionMethodName: (name) -> helpers.getCollectionMethodName(@collection, name)

  addChild: (path) ->
    Meteor.call @getCollectionMethodName("addChild"), path

  addSibling: (path) ->
    Meteor.call @getCollectionMethodName("addSibling"), path

  removeParent: (path) ->
    Meteor.call @getCollectionMethodName("removeParent"), path

subscribeDefaultGridSubscription = (collection) ->
  Meteor.subscribe helpers.getCollectionPubSubName(collection), Meteor.userId() # userId for reactivity
