# GridDataCore takes care of maintaining data structures
# related to the current grid state. 
#
# Main data structures maintained and exposed are
# -----------------------------------------------
#
# @items_by_id: keys are items ids value is the item doc
#
# @tree_structure: Tree representation based on the parents
#                  field of each item. ids are items_ids
#                  value format gives us information about
#                  the children of each id in the form:
#                  {order: item_id, order: item_id, ...}
#
# @detaching_items_ids: Keys are items ids that we don't have
#                       information about but are used as parents
#                       by other items, values are always true
#
# Notes:
# 
#   * All the above structures are exposed as part of the
#     @_immediateInit(). The same object is used throughout
#     the GridDataCore instance life.
#     Hence, you can assign them directly as variables/properties
#     instead of having to keep referring them in the instance
#     object.
#   * Not all the keys present in @tree_structure available in
#     @items_by_id, such keys will be found in @detaching_items_ids.
#   * When an item content changes (any field other than 'parents')
#     its @items_by_id[id] object will be updated and not replaced
#     by the new object, to ease references maintanance. 
#     
# Events
# ------
#
# GridDataCore instances emits events upon changes to the main
# data structures. We chose to emit events and not implement
# reactive resources to skip the need of relying solutions to
# wait for Meteor flush process to notice changes.
# (EventEmitter events are 100% synchronous, binded events aren't
# happening in the next tick but as soon as the event is emitted
# before the following js line is processed).
#
# The events are:
# 
#   structure-changed() - emits after @tree_structure and/or
#                         @detaching_items_ids changed
#
#   content-changed(item_id, changed_fields_array) -
#      emits after changes to @items_by_id to any field
#      other then parent (read note above, items in @items_by_id
#      maintains the same obj between updates)
#
#      Special case: for fields that are foreign keys
#      to other collections, that is, fields that have
#      the grid_foreign_key_collection option in their schema
#      set, we will fire the content-changed event every
#      time their foreign document changes.

default_options = {}
# Required options:
#   collection: the grid data core's collection

GridDataCore = (options) ->
  # skeleton-version: v0.0.2

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("grid-data-core")

  @logger.debug "Init begin"

  @_on_destroy_procedures = []

  @options = _.extend {}, default_options, options

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  Tracker.nonreactive =>
    # on the client, call @_immediateInit() in an isolated
    # computation to avoid our init procedures from affecting
    # the encapsulating computation (if any)
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits GridDataCore, EventEmitter

_.extend GridDataCore.prototype,
  _error: JustdoHelpers.constructor_error

  _immediateInit: ->
    if not (@collection = @options.collection)?
      throw @_error "required-option-missing", "Missing required option 'collection'"

    # By passing options.tasks_query the user of grid data core can specify a query that will limit the tasks
    # we'll fetch from @collection to populate the tree with.
    if not (@tasks_query = @options.tasks_query)?
      @tasks_query = {}

    if not (_.isEmpty(@tasks_query) or (_.size(@tasks_query) == 1 and "project_id" of @tasks_query))
      throw @_error "invalid-options", "At the moment only tasks_query={} or task_query={project_id: XXX} are supported"

    if not (schema = @collection.simpleSchema())?
      throw @_error "schemaless-collection"

      return
    @schema = schema._schema

    @items_by_id = null
    @tree_structure = null
    @order_overridden_items = {}
    @detaching_items_ids = null

    # @_data_changes_queue stores the data changes that will be applied in the
    # next flush.
    # Items are in the form: ["type", update]
    @_data_changes_queue = []
    @_new_items_pending_insert = {}
    @_frozen_items_in_items_by_id = {}

    @flush_manager = new JustdoHelpers.FlushManager
      min_flush_delay: 80

    @_initCollectionItemsDescendantsChangesTracker()

    Tracker.nonreactive =>
      # We don't want GDC's internal computation to affect
      # any enclosing computations
      @_initDataStructure()
      @_initFlushProcedures()
      @_initItemsTracker()
      @_initForeignKeysTrackers()

    return

  _deferredInit: ->
    return

  itemInsertedInCurrentFlushBatch: (id) ->
    # Read comment "ITEMS BY ID MAINTANANCE" under "after-set"
    return id of @_new_items_pending_insert

  _data_changes_handlers:
    add: (id, doc) ->
      # console.log "add", id, doc

      # New item always changes tree structure
      structure_changed = true
      items_ids_with_changed_children = {}

      delete @detaching_items_ids[id]

      # Update tree structure
      for parent_id, parent_metadata of doc.parents
        items_ids_with_changed_children[parent_id] = true

        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}
        
        if @tree_structure[parent_id][parent_metadata.order]? # There is already an item with the same order
          @addItemIdToOrderOverriddenItems(id, parent_id, parent_metadata.order)
        else
          @tree_structure[parent_id][parent_metadata.order] = id

        if parent_id != "0" and not (parent_id of @items_by_id)
          @detaching_items_ids[parent_id] = true

      return [structure_changed, items_ids_with_changed_children]

    unset_fields: (id, fields_ids) ->
      # console.log "unset_fields", id, fields_ids

      # No need to update filters on update, since if the update affect
      # the filter the filter tracker will recognize it and trigger
      # its update

      structure_changed = false
      items_ids_with_changed_children = {}

      if not @itemInsertedInCurrentFlushBatch(id)
        # See below COMMENT-REGARDING-EDITING-FROZEN-DOCUMENTS
        for field_id in fields_ids
          delete @items_by_id[id][field_id]

      @emit "content-changed", id, fields_ids

      return [structure_changed, items_ids_with_changed_children]

    update: (id, fields) ->
      # console.log "update", id, fields

      # No need to update filters on update, since if the update affect
      # the filter the filter tracker will recognize it and trigger
      # its update

      structure_changed = false
      items_ids_with_changed_children = {}

      if not @itemInsertedInCurrentFlushBatch(id)
        # See below COMMENT-REGARDING-EDITING-FROZEN-DOCUMENTS
        Object.assign(@items_by_id[id], fields)

      @emit "content-changed", id, Object.keys(fields)

      return [structure_changed, items_ids_with_changed_children]

    foreign_keys_fields_update: (id, foreign_keys_fields_updates) ->
      # console.log "foreign_keys_fields_update", id, foreign_keys_fields_updates
      #
      # To keep things consistent, we still pass id as the first arg, it will always be "0"

      structure_changed = false
      items_ids_with_changed_children = {}

      @emit "bulk-foreign-keys-updates", foreign_keys_fields_updates

      return [structure_changed, items_ids_with_changed_children]

    remove: (id, removed_doc) ->
      # console.log "remove", id, removed_doc

      # Item removal always changes tree structure
      structure_changed = true
      items_ids_with_changed_children = {}

      item_obj = removed_doc # Before, we used here @items_by_id[id], but in cases where the id
                             # removed is @itemInsertedInCurrentFlushBatch(id) we won't have
                             # a frozen copy for it, in which case, @items_by_id[id] will already
                             # be undefined for it (since it been removed from the underlying id-map)
                             # we therefore use instead removed_doc, which should be fine to our
                             # needs, since even if in the trace of updates for that document
                             # there were updates to parents (which the details about we use later)
                             # those updates been processed by parent_update according to the new_parents_fields

      if id of @tree_structure
        @detaching_items_ids[id] = true

      # Remove from tree structure any pointer to item
      for parent_id, parent_metadata of item_obj.parents
        items_ids_with_changed_children[parent_id] = true

        # Make sure parent still exist
        if @tree_structure[parent_id]?
          # Make sure still pointing to item
          if @tree_structure[parent_id][parent_metadata.order] == id
            # Check if there is a order_overridden_item with the same order, if so, bring it back to tree_structure
            delete @tree_structure[parent_id][parent_metadata.order]
            @restoreFromOrderOverriddeItemsIfExist(parent_id, parent_metadata.order)
          @removeItemIdFromOrderOverriddeItems(parent_id, parent_metadata.order, id)
          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

      @_removeFrozenItemByIdItem(id) # <- call @_removeFrozenItemByIdItem without waiting for the flush to finish, to ensure items_by_id reflects the state correctly
                                     # note, no issue with calling _removeFrozenItemByIdItem twice for the same item id.

      return [structure_changed, items_ids_with_changed_children]

    parent_update: (item_id, new_parents_field) ->
      # console.log "parent_update", item_id, new_parents_field

      structure_changed = false
      items_ids_with_changed_children = {}

      # XXX Is there any situation in which we won't find the item?
      prev_item_obj = @items_by_id[item_id]
      prev_parents_obj = prev_item_obj.parents

      if not @itemInsertedInCurrentFlushBatch(item_id)
        # Update parents see COMMENT-REGARDING-EDITING-FROZEN-DOCUMENTS
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

            structure_changed = true

            if @tree_structure[parent_id][new_order]? # There is alreay an item with the same order
              @addItemIdToOrderOverriddenItems(item_id, parent_id, new_order)
            else
              @tree_structure[parent_id][new_order] = item_id
            
            if @tree_structure[parent_id][prev_order] == item_id
              delete @tree_structure[parent_id][prev_order]
              @restoreFromOrderOverriddeItemsIfExist(parent_id, prev_order)
            if @getOrderOverriddenItems(parent_id, prev_order)?.has(item_id)  # item was in order_overridden_items (could be an else if but just to be safe)
              @removeItemIdFromOrderOverriddeItems(parent_id, prev_order, item_id)
        else
          # New parent - update tree structure
          # console.log "Case 3 - New parent", item_id, parent_id

          structure_changed = true

          items_ids_with_changed_children[parent_id] = true

          if not @tree_structure[parent_id]?
            @tree_structure[parent_id] = {}

            if parent_id != "0" and not (parent_id of @items_by_id)
              @detaching_items_ids[parent_id] = true

          if @tree_structure[parent_id][new_order]? # There is alreay an item with the same order
            @addItemIdToOrderOverriddenItems(item_id, parent_id, new_order)
          else
            @tree_structure[parent_id][new_order] = item_id

      for parent_id, prev_parent_obj of prev_parents_obj
        prev_order = prev_parent_obj.order

        if not(parent_id of new_parents_field)
          # Removed from parent - update tree structure
          # console.log "Case 4 - Remove parent", item_id, parent_id

          structure_changed = true

          items_ids_with_changed_children[parent_id] = true

          # Update tree structure
          # Make sure no other item moved to removed position already
          # XXX can this situation happen?
          if @tree_structure[parent_id][prev_order] == item_id
            delete @tree_structure[parent_id][prev_order]
            @restoreFromOrderOverriddeItemsIfExist(parent_id, prev_order)

          @removeItemIdFromOrderOverriddeItems(parent_id, prev_order, item_id)  

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

      return [structure_changed, items_ids_with_changed_children]

  addItemIdToOrderOverriddenItems: (item_id, parent_id, order) ->
    key = "#{parent_id}:#{order}"
    if not @order_overridden_items[key]?
      @order_overridden_items[key] = new Set()

    @order_overridden_items[key].add(item_id)
    
    return

  getOrderOverriddenItems: (parent_id, order) ->
    return @order_overridden_items["#{parent_id}:#{order}"]

  removeItemIdFromOrderOverriddeItems: (parent_id, order, item_id) ->
    if (order_overridden_item_ids = @getOrderOverriddenItems(parent_id, order))?
      order_overridden_item_ids.delete(item_id)
      if order_overridden_item_ids.size == 0
        delete @order_overridden_items["#{parent_id}:#{order}"]
    
    return
  
  restoreFromOrderOverriddeItemsIfExist: (parent_id, order) ->
    if (order_overridden_item_ids = @getOrderOverriddenItems(parent_id, order))?.size > 0
      order_overridden_item_id = order_overridden_item_ids.entries().next().value[0] # deque the first overridden item
      @tree_structure[parent_id][order] = order_overridden_item_id
      @removeItemIdFromOrderOverriddeItems(parent_id, order, order_overridden_item_id)
    
    return

  _initDataStructure: ->
    @items_by_id = Object.create(JustdoHelpers.getCollectionIdMap(APP.collections.Tasks)._map)
    @tree_structure = {}
    @detaching_items_ids = {}

    for item_id, item of @items_by_id
      if not @isDocMatchedByTasksQuery(item)
        continue

      delete @detaching_items_ids[item._id]

      for parent_id, parent_metadata of item.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}

          if parent_id != "0" and not (parent_id of @items_by_id)
            @detaching_items_ids[parent_id] = true

        if not parent_metadata?
          console.error "A corrupted parent object found, ignoring parent"
          
          continue

        if parent_metadata.order? and _.isNumber parent_metadata.order
          if @tree_structure[parent_id][parent_metadata.order]? # There is already an item with the same order
            @addItemIdToOrderOverriddenItems(item._id, parent_id, parent_metadata.order)
          else
            @tree_structure[parent_id][parent_metadata.order] = item._id

    return

  _initFlushProcedures: ->
    @flush_manager.on "flush", =>
      @flush()

      return

  isDocMatchedByTasksQuery: (doc) ->
    return doc? and (not @tasks_query.project_id? or doc.project_id == @tasks_query.project_id)

  isDocIdRelatedToTasksQuery: (id) ->
    if id of @_new_items_pending_insert
      return true

    return @isDocMatchedByTasksQuery(@items_by_id[id])

  itemsByIdHasOwnProperty: (item_id) ->
    # Id-maps object is created using this._map = Object.create(null);
    # hence it doesn't have hasOwnProperty in its prototype.
    return Object.hasOwnProperty.call(@items_by_id, item_id)

  _freezeItemByIdItemState: (item_id, item_value_to_freeze, ejson_clone_necessary=false, force_freeze_for_items_inserted_in_current_flush=false) ->
    # Grids are updated upon processing of stream of changes by grid-data-core, they aren't
    # updated as soon as changes arrive from the DDP.
    #
    # That processing of changes received from the DDP is called the flush process of the grid-data-core.
    #
    # @items_by_id is expected to represent the items state as of the last flush and not the most active
    # state reported by the DDP. Since changes to the grid are happening between flushes to the grid-data-core,
    # developers can rely on @items_by_id to avoid quirks resulting from access to unprocessed data.
    #
    # For example, imagine that a certain task's title been updated. Until the following flush, in the grid,
    # that task will appear with the previous, now-outdated, title. If before the flush a certain process
    # will want to present the user information about the title, say an alert(), if it will access the title
    # by using Tasks.findOne(task-id).title it will show the user the new title that isn't in-line
    # with what is shown in the grid. But using @items_by_id the developer is promised to receive the accurate
    # last processed value, and hence, the one the user expects to see in any given moment.
    #
    # Starting from v3.113.29 items_by_id is a mere prototypical inheritance of the Tasks collection's id-map
    # created using Object.create and , preventing the need clone each task document to maintain its state in
    # the time of the flush. Before, such clones, led to the allocation of the memory space for the tasks involved
    # in the grid twice (one extra copy to the one already existing under the collection's id-map). By using
    # inheritance, we save the memory and the time it takes to maintain that useless copies.
    #
    # To accomodate that change in data structure, once a change from the ddp arrives for a certain
    # item we need to freeze that item's previous value so attempts to access it using items_by_id[item_id]
    # won't show the new value (temporarily preventing the access to the inherited id-map document by placing
    # a document of the same id in items_by_id level).
    #
    # _freezeItemByIdItemState facilitates that process, it receives an item_id and a value to freeze.
    # Until the followup call to @_removeFrozenItemByIdItem() with the same item_id calls to items_by_id[item_id]
    # will return item_value_to_freeze.
    #
    # In practice we will call @_removeFrozenItemByIdItem() after the full flush process. For the items ids
    # we processed.
    #
    # COMMENT-REGARDING-EDITING-FROZEN-DOCUMENTS During the flush itself we will actually update the frozen
    # documents with changes, the reason for that is that potentially, a stream of updates
    # received for the same document: e.g 1) Update title 2) remove docuemnt ; in such case before 2 is processed
    # the document in items_by_id should reflect the document with the changed title. If we were to
    # simply call _removeFrozenItemByIdItem() on the first change that updated title, items_by_id for the item
    # would have actually become undefined (since in the real underlying id-map it is already removed), and
    # that will produce bugs in the grid level that would expect to find a document.
    #
    # It is important to note that we create the copy to the item doc on the first request to freeze it, the assumption
    # is that between flushes, that document can't change anyway, and worst, by allowing more than one freeze
    # we might even receive a wrong document value to freeze.
    #
    # in the processing of the id map events, for each event a comment: ITEMS BY ID MAINTANANCE
    # is left before the processing.
    #
    # Read also comment "ITEMS BY ID MAINTANANCE" under "after-set"

    # Additional arguments:
    # 
    # ejson_clone_necessary: set to true, if a clone is necessary, if you know that the document provided
    # by reference isn't going to change from now on - prefer avoiding copying it - to save the time and memory
    # involved in the process.

    # Returned value:
    #
    # Returns nothing to avoid confusion in case that the item_value_to_freeze didn't replace an already
    # existing value.

    if not force_freeze_for_items_inserted_in_current_flush and @_new_items_pending_insert[item_id]?
      # Item for which a freeze request received is for an item we didn't process its insert yet,
      # hence we don't need freeze it. Read "ITEMS BY ID MAINTANANCE" comment under "after-set"

      return

    if force_freeze_for_items_inserted_in_current_flush and item_id of @_new_items_pending_insert
      delete @_new_items_pending_insert[item_id]

    if @itemsByIdHasOwnProperty(item_id)
      # Nothing to do, read comment above.

      return

    if ejson_clone_necessary
      item_value_to_freeze = EJSON.clone(item_value_to_freeze)

    @_frozen_items_in_items_by_id[item_id] = true
    @items_by_id[item_id] = item_value_to_freeze

    return

  _freezeItemByIdItemStateSelf: (item_id, force_freeze_for_items_inserted_in_current_flush) ->
    if not @items_by_id[item_id]?
      # Nothing to do.
      return

    @_freezeItemByIdItemState(item_id, @items_by_id[item_id], true, force_freeze_for_items_inserted_in_current_flush)

    return

  _removeFrozenItemByIdItem: (item_id) ->
    # Read above detailed explanation regarding the purpose of this method under _freezeItemByIdItemState()

    if @itemsByIdHasOwnProperty(item_id) # Deleting from an object is an expensive process in js, avoid it unless it is really necessary
      delete @items_by_id[item_id]

    return

  _removeAllFrozenItems: ->
    for frozen_item_id of @_frozen_items_in_items_by_id
      # console.log "HERE frozen item loop" <- uncomment to track optimization issues.
      @_removeFrozenItemByIdItem(frozen_item_id)
    
    @_frozen_items_in_items_by_id = {}

    return

  _initItemsTracker: ->
    if not @destroyed and not @_collection_id_map_events_listeners?
      @_collection_id_map_events_listeners =
        "after-set": (id, value) =>
          if not value.parents?
            # If a docuemnt received without a parents object we skip it since we assume
            # that it is either a private-fields transmission, or augmented fields that
            # received before the task object itself.
            #
            # Later on, when we will get the update for that object that will include
            # parents we will treat that update as the initial add. See below
            # COMMENT_REGARDING_SET_WITHOUT_PARENTS
            return

          if not @isDocMatchedByTasksQuery(value)
            return

          @_data_changes_queue.push ["add", [id, value]]
          @_new_items_pending_insert[id] = true

          # ITEMS BY ID MAINTANANCE:
          #
          # We do Nothing.
          #
          # We DO NOT prevent access to newly added items, since there shouldn't be a case where a grid that
          # isn't aware of their existence (pre-flush) will attempt to access their value.
          #
          # By avoid adding a @_freezeItemByIdItemState(id, null, false) we save the time that it will take
          # to delete this document from the items_by_id level later.
          #
          # Please note that because of this choice, we ensure before the processing of every update
          # that the its target item isn't in @_new_items_pending_insert using @itemInsertedInCurrentFlushBatch()

          @flush_manager.setNeedFlush()

          return

        "before-remove": (id, removed_doc) =>
          if not @isDocIdRelatedToTasksQuery(id)
            return

          # ITEMS BY ID MAINTANANCE:
          @_freezeItemByIdItemState(id, removed_doc, false) # false is to avoid cloning this removed_doc, it isn't going to change.

          # The actual processing is happening under after-remove

          return

        "after-remove": (id, removed_doc) =>
          if not @isDocIdRelatedToTasksQuery(id)
            return

          @_data_changes_queue.push ["remove", [id, removed_doc]]

          # ITEMS BY ID MAINTANANCE:
          # Taken care of under "before-remove"

          @flush_manager.setNeedFlush()

          return

        "before-unset-doc-fields": (id, removed_fields) =>
          if not @isDocIdRelatedToTasksQuery(id)
            return

          # ITEMS BY ID MAINTANANCE:
          @_freezeItemByIdItemStateSelf(id)

          # The actual processing is happening under after-unsetDocFields

          return

        "after-unsetDocFields": (id, removed_fields) =>
          if not @isDocIdRelatedToTasksQuery(id)
            return

          @_data_changes_queue.push ["unset_fields", [id, removed_fields]]

          # ITEMS BY ID MAINTANANCE:
          # Taken care of under "before-unset-doc-fields"

          @flush_manager.setNeedFlush()

          return

        "before-setDocFields": (id, fields_changes, changed_field_old_values) =>
          if not @isDocIdRelatedToTasksQuery(id)
            return

          # ITEMS BY ID MAINTANANCE:
          if "parents" of fields_changes
            # Unlike fields like title, if parents changed, we have to track the changes carefully even if 
            # the item inserted in the current flush - to update the tree structure correctly.
            @_freezeItemByIdItemStateSelf(id, true)
          else
            @_freezeItemByIdItemStateSelf(id)

          # The actual processing is happening under after-setDocFields

          return

        "after-setDocFields": (id, fields_changes, changed_field_old_values) =>
          # console.log "after-set-doc-fields", id, fields_changes

          # @logger.debug "Tracker: Item changed #{id}"

          if not @isDocIdRelatedToTasksQuery(id)
            return

          # Take care of parents changes
          if "parents" of fields_changes
            if not changed_field_old_values? or not changed_field_old_values.parents?
              # COMMENT_REGARDING_SET_WITHOUT_PARENTS
              #
              # Updates for privated fields created this object before the actual task received
              # treat this update as a simple add
              #
              # We send to after-set not only the fields_changes but all the fields so the private/augmented fields
              # received earlier will also be included in the queue produced (otherwise those fields will never go
              # through the queue and that might produce quirks)
              @_collection_id_map_events_listeners["after-set"](id, JustdoHelpers.getCollectionIdMap(@collection).get(id))
              return

            @_data_changes_queue.push ["parent_update", [id, fields_changes.parents, changed_field_old_values.parents]]

            @flush_manager.setNeedFlush()

          changed_fields = _.omit(fields_changes, "parents") # Note in this process we are creating a new object from fields_changes
          changed_field_old_values = _.omit(changed_field_old_values, "parents") # Note in this process we are creating a new object from changed_field_old_values

          # Regular changes
          if not _.isEmpty(changed_fields)
            @_data_changes_queue.push ["update", [id, changed_fields, changed_field_old_values]]

            @flush_manager.setNeedFlush()

          # ITEMS BY ID MAINTANANCE:
          # Taken care of under "before-setDocFields"

          return

        "before-bulkSet": (docs) =>
          if _.isEmpty(@items_by_id)
            # If no items are in items_by_id, no chance that before-setDocFields below will be fired, hence nothing to do.
            #
            # (Optimizes, the initial load, avoids redundant extra loop over docs).
            return

          # ITEMS BY ID MAINTANANCE:
          # Just proxy to the others
          for doc_id, doc of docs
            if doc_id of @items_by_id
              @_collection_id_map_events_listeners["before-setDocFields"](doc_id, doc)
            # else <- there's no handling of before-set, so nothing to do in that case.
            #   @_collection_id_map_events_listeners["before-set"](doc_id, doc)

          return

        "after-bulkSet": (docs) =>
          # Just proxy to the others
          for doc_id, doc of docs
            if doc_id of @items_by_id
              @_collection_id_map_events_listeners["after-setDocFields"](doc_id, doc)
            else
              @_collection_id_map_events_listeners["after-set"](doc_id, doc)

          # ITEMS BY ID MAINTANANCE:
          # Taken care of under "before-bulkSet"

          return

      for listener_id, listener of @_collection_id_map_events_listeners
        JustdoHelpers.getCollectionIdMap(@collection).on listener_id, listener

      @onDestroy =>
        for listener_id, listener of @_collection_id_map_events_listeners
          JustdoHelpers.getCollectionIdMap(@collection).off listener_id, listener

        return

      return

  _initForeignKeysTrackers: ->
    @_foreign_keys_fields_updates_flush_manager = new JustdoHelpers.FlushManager
      min_flush_delay: 10

    foreign_keys_fields_updates = {}
    @_foreign_keys_fields_updates_flush_manager.on "flush", =>
      @_data_changes_queue.push ["foreign_keys_fields_update", ["0", foreign_keys_fields_updates]]
      foreign_keys_fields_updates = {}

      @flush_manager.setNeedFlush()

      return


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
                if not foreign_keys_fields_updates[field_name]?
                  foreign_keys_fields_updates[field_name] = {}

                foreign_keys_fields_updates[field_name][id] = true

                @_foreign_keys_fields_updates_flush_manager.setNeedFlush()

              return

            foreign_keys_trackers[field_name] =
              field_def.grid_foreign_key_collection().find({}, tracker_cursor_options).observeChanges
                _suppress_initial: true
                added: changesCb
                changed: changesCb
                removed: changesCb

            tracker_init = false

      if not _.isEmpty foreign_keys_trackers
        # Set to false so the above existence check won't pass in
        # following calls
        @logger.debug "Foreign keys trackers initiated"
        @_foreign_keys_trackers = foreign_keys_trackers

  _destroyForeignKeysTrackers: ->
    if _.isObject @_foreign_keys_trackers
      for field_name, tracker of @_foreign_keys_trackers
        tracker.stop()

        delete @_foreign_keys_trackers[field_name]

      @logger.debug "Foreign keys trackers destroyed"

  flush: ->
    if @destroyed
      return

    if @_data_changes_queue.length == 0
      @logger.debug "Flush: queue empty, flush not required"

      return

    @logger.debug "Flush: begin"

    structure_changed = false
    returned_ops_items_ids_with_changed_children = [{}] # We init with empty {} so the _.extend() below won't changed returned objects

    # Preform all required data changes, data changes funcs return true
    # if tree structure changed.
    for change in @_data_changes_queue
      # @logger.debug "Flush: process data changes - begin"
      [type, args] = change
      # @logger.debug "Flush: Process #{type}: #{JSON.stringify args}"
      [op_changed_structure, op_items_ids_with_changed_children] = @_data_changes_handlers[type].apply @, args
      structure_changed = structure_changed || op_changed_structure
      if not _.isEmpty(op_items_ids_with_changed_children)
        returned_ops_items_ids_with_changed_children.push op_items_ids_with_changed_children

      # @logger.debug "Flush: process data changes - done; structure_changed = #{structure_changed}"

    items_ids_with_changed_children = _.extend.apply _, returned_ops_items_ids_with_changed_children

    processed_data_changes_queue = @_data_changes_queue

    @_data_changes_queue = []
    @_new_items_pending_insert = {}
    @_removeAllFrozenItems()

    if structure_changed
      @emit "structure-changed", {items_ids_with_changed_children}

    # Init queue
    try
      @emit "data-changes-queue-processed", {queue: processed_data_changes_queue} # Note that content changes are emitted in the
                                                                          # _data_changes_handlers hance, it would be wrong
                                                                          # having data-changes-queue-processed called
                                                                          # before structure-changed.
                                                                          #
                                                                          # If necessary, a pre-processing event can be emitted
                                                                          # before the loop.
    catch e
      console.error "grid-data: A hook attached to 'data-changes-queue-processed' raised an exception", e

    @logger.debug "Flush: done"

    return

  lock: -> @flush_manager.lock()

  release: (immediate) -> @flush_manager.release()

  getAllCollectionPaths: (item_id) ->
    # These are not grid tree paths - but the path created from the natural parents structure

    if not @items_by_id[item_id]?
      return []

    collection_paths = [[item_id, "/#{item_id}/"]]
    collection_paths_edited = true
    while collection_paths_edited
      collection_paths_edited = false
      new_collection_paths = []

      for collection_path in collection_paths
        [current_root, current_path] = collection_path

        if current_root == "0" or current_root == "s"
          new_collection_paths.push collection_path
          continue

        all_parents_docs = @getAllDirectParentsItemsDocs([current_root])

        if _.isNumber(@items_by_id[current_root]?.parents?["0"]?.order)
          new_collection_paths.push ["0", current_path]
        else if _.isEmpty(all_parents_docs)
          new_collection_paths.push ["s", "/s#{current_path}"]

        for parent_doc in all_parents_docs   
          parent_id = parent_doc._id     
          collection_paths_edited = true
          new_collection_paths.push [parent_id, "/#{parent_id}#{current_path}"]

      collection_paths = new_collection_paths

    return _.map collection_paths, (collection_path) -> collection_path[1]

  getAllDirectParentsItemsDocs: (items_ids) ->
    res = []

    for item_id in items_ids
      if item_id == "0" or item_id == 0
        # Root
        continue

      if (parents_ids = _.keys(@items_by_id[item_id]?.parents))
        for parent_id in parents_ids
          if (parent_doc = @items_by_id[parent_id])?
            res.push parent_doc

    # Remove parents found more than once
    res = _.uniq res, false, (doc) -> doc._id # false is for isSorted

    return res

  _initCollectionItemsDescendantsChangesTracker: ->
    self = @

    @_collection_items_tracked_for_descendants_changes = {}
    # _collection_items_tracked_for_descendants_changes Structure:
    # {
    #   "item_id": [ # An array because there can be more than one tracker for the same item_id
    #     {
    #       tracker_id: A random id for this tracker, so we can remove it when it isn't needed anymore
    #       direct_children_only: false # true / false
    #       descendants_changed_dep: new Tracker.Dependency() # The Dependency that we'll call the .changed()
    #                                                         # when descendants changed according to the
    #                                                         # tracker options.
    #       tracked_fields: [] # Either undefined, or an array of fields, if undefined, all fields are
    #                          # tracked
    #     }
    #   ]
    # }

    announceTrackedItemChanged = (tracked_item_id, is_direct_children_changed, fields_affected) =>
      # fields_affected might be undefined, in which case we assume all the fields
      # are affected

      for tracker in @_collection_items_tracked_for_descendants_changes[tracked_item_id]
        if tracker.direct_children_only and not is_direct_children_changed
          continue

        if fields_affected?
          # When fields_affected is undefined - we assume all the fields are affected by this change,
          # hence no need to check intersection with the tracker tracked fields.
          if tracker.tracked_fields? and _.isEmpty(_.intersection(tracker.tracked_fields, fields_affected))
            continue

        tracker.descendants_changed_dep.changed()

      return

    @on "structure-changed", (changes) ->
      if _.isEmpty(@_collection_items_tracked_for_descendants_changes)
        # Nothing to do
        return

      # Note, unlike content-changed below, the changes provided here are already pointing
      # to their parents. Hence we begin differently - looping over all the parents, which
      # we regard as direct parents of the changes, and only then looping over their descendants.

      for parent_id of changes.items_ids_with_changed_children
        if parent_id of @_collection_items_tracked_for_descendants_changes
          announceTrackedItemChanged(parent_id, true) 

      # Go up the tree, for every parent, check if it is in the
      # _collection_items_tracked_for_descendants_changes
      items_to_check = _.keys(changes.items_ids_with_changed_children)
      while (not _.isEmpty(parents_docs = self.getAllDirectParentsItemsDocs(items_to_check)))
        items_to_check = []

        for parent_doc in parents_docs
          if parent_doc._id of @_collection_items_tracked_for_descendants_changes
            announceTrackedItemChanged(parent_doc._id, false) # false is for direct parents

          items_to_check.push parent_doc._id

      return


    @on "content-changed", (item_id, changed_fields_array) ->
      if _.isEmpty(@_collection_items_tracked_for_descendants_changes)
        # Nothing to do
        return

      # Go up the tree, for every parent, check if it is in the
      # _collection_items_tracked_for_descendants_changes
      items_to_check = [item_id]
      direct_parents = true
      while (not _.isEmpty(parents_docs = self.getAllDirectParentsItemsDocs(items_to_check)))
        items_to_check = []

        for parent_doc in parents_docs
          if parent_doc._id of @_collection_items_tracked_for_descendants_changes
            announceTrackedItemChanged(parent_doc._id, direct_parents, changed_fields_array)

          items_to_check.push parent_doc._id

        direct_parents = false # After the first loop, we are not checking item_id direct parents
                               # any longer

      return

    return

  invalidateOnCollectionItemDescendantsChanges: (collection_item_id, options) ->
    if not Tracker.currentComputation?
      console.error "invalidateOnCollectionItemDescendantsChanges must be called inside a computation"

      return

    default_options =
      direct_children_only: false
      tracked_fields: undefined # Usage example for direct_children_only: ["title", "status"]
                                #
                                # Note, structure changes (add/remove parent) are considered
                                # as changing all the fields, so even if option is set to
                                # ["title", "status"] , add child to the tracked
                                # collection_item_id will still trigger invalidation.
    options = _.extend default_options, options

    tracker_id = Random.id()
    tracker_dep = new Tracker.Dependency()

    tracker_dep.depend()

    tracker_def =
      tracker_id: tracker_id
      direct_children_only: options.direct_children_only or false
      tracked_fields: options.tracked_fields or undefined
      descendants_changed_dep: tracker_dep

    if not @_collection_items_tracked_for_descendants_changes[collection_item_id]?
      @_collection_items_tracked_for_descendants_changes[collection_item_id] = []
    @_collection_items_tracked_for_descendants_changes[collection_item_id].push tracker_def

    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        # Once invalidated, remove the tracker.

        @_collection_items_tracked_for_descendants_changes[collection_item_id] =
          _.filter(@_collection_items_tracked_for_descendants_changes[collection_item_id], (_tracker_def) -> _tracker_def.tracker_id != tracker_id)

        if _.isEmpty(@_collection_items_tracked_for_descendants_changes[collection_item_id])
          delete @_collection_items_tracked_for_descendants_changes[collection_item_id]

        return

    return

  getAllItemsKnownAncestorsIdsObj: (items_ids_arr, _ancestors_obj) ->
    # By known ancestors, we mean ancestors for which we have a reference under:
    # @items_by_id
    #
    # Returns an object in which values are meaningless.

    if not _ancestors_obj?
      _ancestors_obj = {}

    next_iteration_items_ids = []

    for item_id in items_ids_arr
      for parent_id of @items_by_id[item_id]?.parents
        if parent_id of _ancestors_obj or # If already encountered -> no need to go upwards again
           parent_id == "0" or
           not @items_by_id[parent_id]?
          continue

        _ancestors_obj[parent_id] = true
        next_iteration_items_ids.push parent_id

    if next_iteration_items_ids.length > 0
      @getAllItemsKnownAncestorsIdsObj(next_iteration_items_ids, _ancestors_obj)

    return _ancestors_obj

  getAllItemsKnownDescendantsIdsObj: (items_ids_arr, _descendants_obj) ->
    # By known descendants, we mean descendants for which we have a reference under:
    # @items_by_id
    #
    # Returns an object in which values are meaningless.

    if not _descendants_obj?
      _descendants_obj = {}

    next_iteration_items_ids = []

    for item_id in items_ids_arr
      if @tree_structure[item_id]?
        for order, child_id of @tree_structure[item_id]
          if child_id of _descendants_obj or # If already encountered -> no need to go downwards again
             not @items_by_id[child_id]?
            continue

          _descendants_obj[child_id] = true
          next_iteration_items_ids.push child_id

    if next_iteration_items_ids.length > 0
      @getAllItemsKnownDescendantsIdsObj(next_iteration_items_ids, _descendants_obj)

    return _descendants_obj

  onDestroy: (proc) ->
    # not to be confused with @destroy, onDestroy registers procedures to be called by @destroy()
    @_on_destroy_procedures.push proc

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @_destroyForeignKeysTrackers()

    @flush_manager.destroy()

    @destroyed = true

    @logger.debug "Destroyed"
