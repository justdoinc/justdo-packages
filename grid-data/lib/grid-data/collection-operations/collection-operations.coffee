helpers = share.helpers

_.extend GridData.prototype,
  # ** Misc. **
  getCollectionMethodName: (name) -> helpers.getCollectionMethodName(@collection, name)

  edit: (item_id, field, value) ->
    update =
      $set:
        [field]: value

    edit_failed = (err) =>
      # XXX We used to think we need the following, now it seems
      # that following a code refactor it became redundant.
      # (was very hacky, so it's very good)
      #
      # See related topic: observeChanges doesn't revert failed edits
      # See: https://github.com/meteor/meteor/issues/4282
      # @_data_changes_queue.push ["update", [item_id, [col_field]]] # NEED REWRITE

      @_set_need_flush()

      @emit "edit-failed", err

    executed = @collection.update item_id, update, (err) =>
      if err?
        edit_failed(err)

        return false

      return true

    if executed is false or executed is 0
      # executed is false if edit blocked by events hooks
      @_grid_data_core._data_changes_handlers.update.call(@_grid_data_core, item_id, {"#{field}": @collection.findOne(item_id, {fields: {"#{field}": 1}})?[field]})
      
      edit_failed(@_error "edit-blocked-by-hook", "Edit blocked by hook")


    return

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

  bulkAddChild: (path, childs_fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, [[child_id, child_path]])

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("bulkAddChild"), path, childs_fields, (err, childs_ids) ->
      if err?
        helpers.callCb cb, err
      else
        results = []
        for child_id in childs_ids
          results.push([child_id, path + child_id + "/"])

        helpers.callCb cb, err, results

      return

    return

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

  bulkAddSibling: (path, siblings_fields, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err, [[sibling_id, sibling_path]])

    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("bulkAddSibling"), path, siblings_fields, (err, siblings_ids) ->
      if err?
        helpers.callCb cb, err
      else
        results = []

        for sibling_id in siblings_ids
          results.push([sibling_id, helpers.getParentPath(path) + sibling_id + "/"])

        helpers.callCb cb, err, results 

      return

    return

  removeParent: (paths, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err)
    if _.isString(paths)
      paths = [paths]

    paths = _.map paths, (paths) -> helpers.normalizePath(paths)

    Meteor.call @getCollectionMethodName("removeParent"), paths, (err) ->
      helpers.callCb cb, err

    return

  bulkRemoveParents: (paths, cb) ->
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err)

    paths = _.map paths, (path) -> helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("bulkRemoveParents"), paths, (err) ->
      helpers.callCb cb, err

      return

    return

  addParent: (item_id, new_parent, cb, usersDiffConfirmationCb) ->
    # Add item_id to the parent detailed in new_parent.
    #
    # new_parent structure:
    # {
    #   parent: "", # the new parent id, use "0" for root
    #   order: int # order under the new parent - not required, will be added as the last item if not specified. 
    # }
    #
    # If cb provided, cb will be called with the following args when excution
    # completed:
    # cb(err)
    #
    # if usersDiffConfirmationCb is provided, if users of item_id and
    # new_parent aren't the same the addParent operation will be
    # suspended and usersDiffConfirmationCb will be called with the following
    # args:
    #   usersDiffConfirmationCb(item_id, target_id, diff, proceed, cancel)
    #   item_id: is the item_id arg provided to addParent
    #   target_id: the id of the new parent
    #   diff: An object of the form:
    #         {
    #           absent: [uid, uid, ...] # can be empty
    #           alien: [uid, uid, ...] # can be empty
    #         }
    #         absent lists users that exists in path but don't in new_location
    #         alien lists users that don't exist in path but do in new_location
    #   proceed: a callback, if called, move operation will continue
    #   cancel: a callback, if called, move operation will cancel
    # if new location is the root we ignore usersDiffConfirmationCb
    new_parent = _.pick new_parent, ["parent", "order"]

    performOp = =>
      Meteor.call @getCollectionMethodName("addParent"), item_id, new_parent, (err) ->
        helpers.callCb cb, err

    if not(usersDiffConfirmationCb? and _.isFunction usersDiffConfirmationCb)
      # Perform operation right away.
      return performOp()
    else
      new_parent_item_id = new_parent.parent

      if new_parent_item_id == "0"
        # moving to root, no diff as root isn't a real item
        # perform op right away

        @logger.debug "usersDiffConfirmationCb skipped, adding root as parent"

        return performOp()

      augmented_fields_sub = JD.subscribeItemsAugmentedFields [item_id, new_parent_item_id], ["users"], {}, =>
        item_users = APP.collections.TasksAugmentedFields.findOne(item_id).users
        new_parent_item_users = APP.collections.TasksAugmentedFields.findOne(new_parent_item_id).users

        augmented_fields_sub.stop()

        diff =
          alien: _.difference new_parent_item_users, item_users
          # absent: _.difference item_users, new_parent_item_users # We decided not to suggest removing members absent in the parent task when adding new parent

        if _.isEmpty(diff.absent) and _.isEmpty(diff.alien)
          # no diff perform op right away

          @logger.debug "usersDiffConfirmationCb skipped, no diff"

          return performOp()

        proceed = ->
          return performOp()

        cancel = =>
          @logger.debug "addParent cancelled by usersDiffConfirmationCb"

          # call cb with error
          helpers.callCb cb, @_error("operation-cancelled", "addParent operation cancelled by usersDiffConfirmationCb")

          return

        usersDiffConfirmationCb(item_id, new_parent_item_id, diff, proceed, cancel)

        return

    return

  movePath: (paths, new_location, cb, usersDiffConfirmationCb) ->
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
    # if new_location is an array: cb(err, new_paths)
    #   new_paths we will determine new_location based on new_position_path and relation.
    #   it will be an array of paths if paths provided as an Array of strings, if it was
    #   provided as a string it will be a string for the new path.
    # if new_location is an object: cb(err)

    # IMPORTANT usersDiffConfirmationCb is supported only if either a single path
    # is provided in the paths array or a String path is provided.

    # if usersDiffConfirmationCb is provided, if users of path and
    # provided new_location aren't the same the move operation will be
    # suspended and usersDiffConfirmationCb will be called with the following
    # args:
    #   usersDiffConfirmationCb(item_id, target_id, diff, proceed, cancel)
    #   item_id: the id of the item we move
    #   target_id: the id of the new parent
    #   diff: An object of the form:
    #         {
    #           absent: [uid, uid, ...] # can be empty
    #           alien: [uid, uid, ...] # can be empty
    #         }
    #         absent lists users that exists in path but don't in new_location
    #         alien lists users that don't exist in path but do in new_location
    #   proceed: a callback, if called, move operation will continue
    #   cancel: a callback, if called, move operation will cancel
    # if new location is the root we ignore usersDiffConfirmationCb

    # Originally, movePath worked with a single string path, string_path_provided is used
    # to maintain backward-compatibility.
    string_path_provided = false
    if _.isString(paths)
      string_path_provided = true
      paths = [paths]
    
    check paths, [String]

    if paths.length > 1
      @logger.debug "movePath: more than one path provided, usersDiffConfirmationCb skipped"
      usersDiffConfirmationCb = null
      
    relative_paths = _.map(paths, (path) => @getPathRelativePath(helpers.normalizePath(path)))
    new_location_type = null
    new_location_obj = null
    new_paths = null
    if not _.isArray new_location
      new_location_type = "object"
      new_location_obj = new_location
    else
      new_location_type = "array"

      paths_items_ids = _.map paths, (path) =>
        if not (path_details = @getPathNaturalCollectionTreeInfo(path))?
          throw new Error "movePath: provided path #{path} is unknown"

        return path_details.item_id

      [position_path, relation] = new_location
      position_path = helpers.normalizePath(position_path)

      position_path_details = @getPathNaturalCollectionTreeInfo position_path
      if position_path == "/"
        # edge case position_path == "/" parent is "0"
        new_location_obj =
          parent: "0"

        # ignore -1/1 relations (assume only 0/2 are possible)
        if relation == 0
          new_location_obj.order = 0

        new_paths = _.map paths_items_ids, (item_id) => "/#{item_id}/"
      else if relation in [0, 2]
        new_location_obj =
          parent: position_path_details.item_id

        if relation == 0
          new_location_obj.order = 0

        new_paths = _.map paths_items_ids, (item_id) => "#{position_path}#{item_id}/"
      else # relation -1 or 1
        new_location_obj =
          parent: position_path_details.parent_id
          order: position_path_details.order

        if relation == 1
          new_location_obj.order += 1

        new_paths = _.map paths_items_ids, (item_id) => "#{helpers.getParentPath(position_path)}#{item_id}/"
    performOp = =>
      Meteor.call @getCollectionMethodName("movePath"), relative_paths, new_location_obj, (err) ->
        if new_location_type == "object"
          helpers.callCb cb, err
        else
          if not err?
            if string_path_provided
              helpers.callCb cb, err, new_paths[0] # For backward-compatibility
            else
              helpers.callCb cb, err, new_paths
          else
            helpers.callCb cb, err

    if not(usersDiffConfirmationCb? and _.isFunction usersDiffConfirmationCb)
      # Perform operation right away.
      return performOp()
    else
      path = paths[0] # Only a single path is supported for usersDiffConfirmationCb therefore, we can assume that paths[0] is the only one.
      path_item_id = helpers.getPathItemId(path)
      new_parent_item_id = new_location_obj.parent

      is_intra_parent_move = GridData.helpers.getPathParentId(path) == new_location_obj.parent

      if new_parent_item_id == "0" or is_intra_parent_move
        # We don't show members diff if moving to root or
        # if moving within the same parent.

        @logger.debug "usersDiffConfirmationCb skipped, moving item to root"

        return performOp()

      augmented_fields_sub = JD.subscribeItemsAugmentedFields [path_item_id, new_parent_item_id], ["users"], {}, =>
        path_item_users = APP.collections.TasksAugmentedFields.findOne(path_item_id).users
        new_parent_item_users = APP.collections.TasksAugmentedFields.findOne(new_parent_item_id).users

        augmented_fields_sub.stop()
        
        diff =
          absent: _.difference path_item_users, new_parent_item_users
          alien: _.difference new_parent_item_users, path_item_users

        if _.isEmpty(diff.absent) and _.isEmpty(diff.alien)
          # no diff perform op right away

          @logger.debug "usersDiffConfirmationCb skipped, no diff"

          return performOp()

        proceed = ->
          return performOp()

        cancel = =>
          @logger.debug "movePath cancelled by usersDiffConfirmationCb"

          # call cb with error
          helpers.callCb cb, @_error("operation-cancelled", "movePath operation cancelled by usersDiffConfirmationCb")

          return

        usersDiffConfirmationCb(path_item_id, new_parent_item_id, diff, proceed, cancel)

        return

    return

  sortChildren: (path, field, asc_desc, cb) ->
    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("sortChildren"), path, field, asc_desc, (err) ->
      helpers.callCb cb, err

  bulkUpdate: (items_ids, modifier, cb) ->
    path = helpers.normalizePath(path)

    Meteor.call @getCollectionMethodName("bulkUpdate"), items_ids, modifier, (err, changed_items_count) ->
      helpers.callCb cb, err, changed_items_count
