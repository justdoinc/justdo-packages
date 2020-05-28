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

    if not (schema = @collection.simpleSchema())?
      throw @_error "schemaless-collection"

      return
    @schema = schema._schema

    @items_by_id = null
    @tree_structure = null
    @detaching_items_ids = null

    # @_data_changes_queue stores the data changes that will be applied in the
    # next flush.
    # Items are in the form: ["type", update]
    @_data_changes_queue = [] 

    @_items_tracker = null

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

  _data_changes_handlers:
    add: (id, doc) ->
      # console.log "add", id, doc

      # New item always changes tree structure
      structure_changed = true
      items_ids_with_changed_children = {}

      # Update @items_by_id
      @items_by_id[id] = doc
      delete @detaching_items_ids[id]

      # Update tree structure
      for parent_id, parent_metadata of doc.parents
        items_ids_with_changed_children[parent_id] = true

        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}
        @tree_structure[parent_id][parent_metadata.order] = id

        if parent_id != "0" and not (parent_id of @items_by_id)
          @detaching_items_ids[parent_id] = true

      return [structure_changed, items_ids_with_changed_children]

    update: (id, fields) ->
      # console.log "update", id, fields

      # No need to update filters on update, since if the update affect
      # the filter the filter tracker will recognize it and trigger
      # its update

      structure_changed = false
      items_ids_with_changed_children = {}

      # update items_by_id[id] without replacing it with a
      # new object (make use of original object). 
      old_item = @items_by_id[id]
      item = @collection.findOne(id)

      # If by the time we are flushing, item doesn't
      # exist anymore, no point to update it.
      # If old_item doesn't exist, something weird happened...
      if old_item? and item?
        for field in fields
          @items_by_id[id][field] = item[field]

        for removed_field in _.difference(_.keys(@items_by_id[id]), _.keys(item))
          delete @items_by_id[id][removed_field]

        @emit "content-changed", id, fields 

      return [structure_changed, items_ids_with_changed_children]

    foreign_key_fields_update: (id, foreign_key_fields) ->
      # console.log "foreign_key_fields_update", id, foreign_key_fields

      structure_changed = false
      items_ids_with_changed_children = {}

      @emit "content-changed", id, foreign_key_fields

      return [structure_changed, items_ids_with_changed_children]

    remove: (id) ->
      # console.log "remove", id

      # Item removal always changes tree structure
      structure_changed = true
      items_ids_with_changed_children = {}

      # Update @items_by_id
      item_obj = @items_by_id[id]

      if id of @tree_structure
        @detaching_items_ids[id] = true

      # Remove from tree structure any pointer to item
      for parent_id, parent_metadata of item_obj.parents
        items_ids_with_changed_children[parent_id] = true

        # Make sure parent still exist
        if @tree_structure[parent_id]?
          # Make sure still pointing to item
          if @tree_structure[parent_id][parent_metadata.order] == id
            delete @tree_structure[parent_id][parent_metadata.order]

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

      delete @items_by_id[id]

      return [structure_changed, items_ids_with_changed_children]

    parent_update: (item_id, new_parents_field) ->
      # console.log "parent_update", item_id, new_parents_field

      structure_changed = false
      items_ids_with_changed_children = {}

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

            structure_changed = true

            @tree_structure[parent_id][new_order] = item_id
            # XXX Is it possible that the following won't be true?
            if @tree_structure[parent_id][prev_order] == item_id
              delete @tree_structure[parent_id][prev_order]
        else
          # New parent - update tree structure
          # console.log "Case 3 - New parent", item_id, parent_id

          structure_changed = true

          items_ids_with_changed_children[parent_id] = true

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

          structure_changed = true

          items_ids_with_changed_children[parent_id] = true

          # Update tree structure
          # Make sure no other item moved to removed position already
          # XXX can this situation happen?
          if @tree_structure[parent_id][prev_order] == item_id
            delete @tree_structure[parent_id][prev_order]

          if _.isEmpty @tree_structure[parent_id]
            delete @tree_structure[parent_id]
            delete @detaching_items_ids[parent_id]

      return [structure_changed, items_ids_with_changed_children]

  _initDataStructure: ->
    @items_by_id = {}
    @tree_structure = {}
    @detaching_items_ids = {}

    for item in @collection.find(@tasks_query).fetch()
      @items_by_id[item._id] = item
      delete @detaching_items_ids[item._id]

      for parent_id, parent_metadata of item.parents
        if not @tree_structure[parent_id]?
          @tree_structure[parent_id] = {}

          if parent_id != "0" and not (parent_id of @items_by_id)
            @detaching_items_ids[parent_id] = true

        if parent_metadata.order? and _.isNumber parent_metadata.order
          @tree_structure[parent_id][parent_metadata.order] = item._id

  _initFlushProcedures: ->
    @flush_manager.on "flush", =>
      @flush()

  _initItemsTracker: ->
    if not @destroyed and not @_items_tracker
      # The first time we build the tree is with @_initDataStructure()
      # so, any data existing prior init will be taken by it,
      # tracker_init var is here to avoid adding this data
      # second time.
      tracker_init = true
      @_items_tracker = @collection.find(@tasks_query).observeChanges
        added: (id, doc) =>
          # @logger.debug "Tracker: Item added #{id}"

          if not tracker_init
            doc._id = id
            @_data_changes_queue.push ["add", [id, doc]]

            @flush_manager.setNeedFlush()

        changed: (id, fields_changes) =>
          # @logger.debug "Tracker: Item changed #{id}"

          fields = _.difference(_.keys(fields_changes), @_ignore_change_in_fields) # remove ignored fields

          # Take care of parents changes
          if "parents" in fields
            @_data_changes_queue.push ["parent_update", [id, fields_changes.parents]]

            @flush_manager.setNeedFlush()

            fields = _.without(fields, "parents") # remove parents field

          # Regular changes
          if fields.length != 0
            @_data_changes_queue.push ["update", [id, fields]]

            @flush_manager.setNeedFlush()

        removed: (id) =>
          # @logger.debug "Tracker: Item removed #{id}"

          @_data_changes_queue.push ["remove", [id]]

          @flush_manager.setNeedFlush()

      tracker_init = false

  _initForeignKeysTrackers: ->
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

                  @flush_manager.setNeedFlush()

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
      returned_ops_items_ids_with_changed_children.push op_items_ids_with_changed_children

      # @logger.debug "Flush: process data changes - done; structure_changed = #{structure_changed}"

    items_ids_with_changed_children = _.extend.apply _, returned_ops_items_ids_with_changed_children

    if structure_changed
      @emit "structure-changed", {items_ids_with_changed_children}

    @emit "data-changes-queue-processed", {queue: @_data_changes_queue} # Note that content changes are emitted in the
                                                                        # _data_changes_handlers hance, it would be wrong
                                                                        # having data-changes-queue-processed called
                                                                        # before structure-changed.
                                                                        #
                                                                        # If necessary, a pre-processing event can be emitted
                                                                        # before the loop.

    # Init queue
    @_data_changes_queue = []

    @logger.debug "Flush: done"

  lock: -> @flush_manager.lock()

  release: (immediate) -> @flush_manager.release()

  _initCollectionItemsDescendantsChangesTracker: ->
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

    getAllDirectParentsItemsDocs = (items_ids) =>
      res = []

      # TODO: ensure each doc returns only once!

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
      while (not _.isEmpty(parents_docs = getAllDirectParentsItemsDocs(items_to_check)))
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
      while (not _.isEmpty(parents_docs = getAllDirectParentsItemsDocs(items_to_check)))
        items_to_check = []

        for parent_doc in parents_docs
          if parent_doc._id of @_collection_items_tracked_for_descendants_changes
            announceTrackedItemChanged(parent_doc._id, direct_parents, changed_fields_array)

          items_to_check.push parent_doc._id

        direct_parents = false # After the first loop, we are not checking item_id direct parents
                               # any longer

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

    @_items_tracker.stop()

    @flush_manager.destroy()

    @destroyed = true

    @logger.debug "Destroyed"
