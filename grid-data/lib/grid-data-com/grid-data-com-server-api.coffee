Fiber = Npm.require "fibers"

helpers = share.helpers

_.extend GridDataCom.prototype,
  _isPerformAsProvided: (perform_as) ->
    if not perform_as?
      throw @_error "missing-argument", "You must provide the perform_as field"

  _insertItem: (fields) ->
    task_id = Random.id()

    upsert_mutator = {$set: fields}

    {no_changes_to_public_task, mutator, private_fields_mutator} =
      @_extractPrivateDataUpdatesFromMutatorInPlace(upsert_mutator)
    upsert_mutator = mutator # upsert_mutator is edited in place, still, I leave this for readability (Daniel C.)

    Fiber.current._allow_tasks_upsert = true
    try
      @collection.upsert({_id: task_id}, upsert_mutator, {upsert: true})
    catch e
      console.error "grid-data-com: Failed to insert document", e

      return undefined
    finally
      delete Fiber.current._allow_tasks_upsert

    if _.size(private_fields_mutator) > 0
      # Note, by this point thanks to the allow deny rules defined on initDefaultGridAllowDenyRules() of the
      # grid data com package, we know for sure the user belongs to the task. We assume that since the
      # task belongs to the user, the user also belongs to the project (not necessarily true in the theoretical
      # case).
      #
      # Also, note, that the only fields that can be included in the private_fields_mutator are prefixed
      # with the "priv:" prefix, as required by _upsertItemPrivateData
      APP.projects._grid_data_com._upsertItemPrivateData(fields.project_id, task_id, private_fields_mutator, fields.created_by_user_id)

    return task_id

  _upsertItemPrivateData: (project_id, task_id, mutators, user_id) ->
    check project_id, String
    check task_id, String
    check mutators, Object
    check user_id, String

    # IMPORTANT 1: By this point, we assume security related verification been performed.
    #
    # (e.g. we assume user_id belongs to task_id, and project_id, that mutators are
    # valid and so on)
    #
    # Note, user_id is the last argument, and isn't coming before mutator, to keep consistent
    # with other JustDo apis.
    #
    # IMPORTANT 2: We are assuming that mutators only affects fields that are prefixed with
    # "priv:", thus, we don't need to worry about attempts to affect internal fields, such
    # as the user_id/task_id, etc. by mutators.

    Fiber.current._allow_tasks_private_data_upsert = true
    try
      #
      # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
      # and to drop obsolete indexes (see FETCH_PROJECT_TASK_PRIVATE_DATA_OF_SPECIFIC_USER_INDEX there)
      #
      @private_data_collection.upsert({project_id, task_id, user_id}, mutators, {upsert: true, bypassCollection2: true})
    catch e
      console.error "grid-data-com: Failed to insert private data document", e

      return undefined
    finally
      delete Fiber.current._allow_tasks_private_data_upsert

    return


  _getCurrentDateUpdateObjectForUsers: (prefix, users) ->
    ret = {}

    for user_id in users
      ret["#{prefix}.#{user_id}"] = true

    return ret

  _addRawFieldsUpdatesToUpdateModifier: (modifier, existing_doc) ->
    # Note: edits modifier in place !

    if (existing_current_date_mod = modifier.$currentDate)?
      current_date_updates = existing_current_date_mod
    else
      current_date_updates = {}

    if (existing_unset_mod = modifier.$unset)?
      unset_updates = existing_unset_mod
    else
      unset_updates = {}

    if (existing_add_to_set_mod = modifier.$addToSet)?
      add_to_set_updates = existing_add_to_set_mod
    else
      add_to_set_updates = {}

    if (existing_pull_mod = modifier.$pull)?
      pull_updates = existing_pull_mod
    else
      pull_updates = {}

    _.extend current_date_updates,
      _raw_updated_date: true

    #
    # Find changes in users
    #
    added_users = []
    removed_users = []

    if (pushed_users = modifier.$push?.users?.$each)?
      added_users = added_users.concat(pushed_users)

    if (pulled_users = modifier.$pull?.users?.$in)?
      removed_users = removed_users.concat(pulled_users)

    if (users = modifier.$set?.users)?
      if (existing_users = existing_doc?.users)?
        added_users = added_users.concat(_.difference users, existing_users)
        removed_users = removed_users.concat(_.difference existing_users, users)

        if not _.isEmpty(added_users) and not _.isEmpty(removed_users)
          throw @_error "operation-blocked", "$set.users update that involves both removal and addition of new users, isn't allowed" # since we can't $pull and $addToSet items from/to _raw_added_users_dates with a single query

      else
        # If no existing_doc, assume insert of new document
        _.extend current_date_updates, @_getCurrentDateUpdateObjectForUsers("_raw_added_users_dates", users)

    #
    # If users changed, update relevant raw fields
    #
    if not _.isEmpty(added_users)
      _.extend current_date_updates, @_getCurrentDateUpdateObjectForUsers("_raw_added_users_dates", added_users)

      for user_id in added_users
        unset_updates["_raw_removed_users_dates.#{user_id}"] = ""

      pull_updates._raw_removed_users =
        $in: added_users

    if not _.isEmpty(removed_users)
      _.extend current_date_updates, @_getCurrentDateUpdateObjectForUsers("_raw_removed_users_dates", removed_users)

      for user_id in removed_users
        unset_updates["_raw_added_users_dates.#{user_id}"] = ""

      add_to_set_updates._raw_removed_users =
        $each: removed_users

    #
    # Update changed modifiers
    #
    if not _.isEmpty current_date_updates
      modifier["$currentDate"] = current_date_updates

    if not _.isEmpty unset_updates
      modifier["$unset"] = unset_updates

    if not _.isEmpty add_to_set_updates
      modifier["$addToSet"] = add_to_set_updates

    if not _.isEmpty pull_updates
      modifier["$pull"] = pull_updates

    return

  setupGridCollectionHooks: ->
    @collection.before.insert =>
      # Since we need to update the raw fields that needs the update's operator $currentDate,
      # we can't allow inserts using the .insert() operator, only .upsert()s are allowed.
      throw @_error "operation-blocked", "Inserts aren't allowed on grid-data-com's @collection. Use @_insertItem() instead."

    @collection.before.upsert (user_id, selector, modifier, options) =>
      # We allow upserts only for inserts since the @_addRawFieldsUpdatesToUpdateModifier(modifier)
      # makes the assumption that if a doc wasn't provided in its second argument, we are dealing with
      # creation of a new document, and updates of raw fields related to remoevd users, shouldn't be
      # updated in case where $set.users is provided (there might be other unexpected results).

      if not Fiber.current._allow_tasks_upsert?
        throw @_error "operation-blocked", "Upserts for grid-data-com's @collection are allowed only to insert new documents. If you are intending to use this upsert in order to insert new documents (only), search the code for Fiber.current._allow_tasks_upsert to learn more."

      @_addRawFieldsUpdatesToUpdateModifier(modifier)

      return

    @collection.before.update (user_id, doc, field_names, modifier, options) =>
      if "$unset" of modifier
        first_unset_field = _.keys(modifier.$unset)[0]

        if _.size(modifier.$unset) == 1 and "." not in first_unset_field
          # Backward compatibility, replace $unset with set to null.

          # On the mobile, $unset was used before, we want the apps to keep
          # working after the point in which we stopped supporting $unset
          # of Tasks fields.
          #
          # All the cases in which mobiles used $unset examined, they all had a
          # single field involved and they all can be replaced with {$set: {field:
          # null}}.

          Meteor._ensure(modifier, "$set")

          _.extend modifier.$set, {"#{first_unset_field}": null}

          delete modifier.$unset
        else
          for field of modifier["$unset"]
            if "." not in field
              throw @_error "operation-blocked", "We do not permit $unset of top-level fields of the tasks collection documents (read web-app Changelog for v1.117.0 to learn more)."

      @_addRawFieldsUpdatesToUpdateModifier(modifier, doc)

      return

    # Define hooks that will let packages hook to our pseudo remove

    @collection.before.pseudo_remove = (cb) =>
      # cb returned value is ignored.
      # cb(user_id, doc to be removed before any change, update to be performed)

      @register "BeforePseudoRemove", cb

      return

    @collection.after.pseudo_remove = (cb) =>
      # cb returned value is ignored.
      # cb(user_id, doc to be removed before any change, update performed)

      @register "AfterPseudoRemove", cb

      return

    @collection.before.remove (user_id, doc) =>
      current_date_updates = 
        _raw_removed_date: true
        # Note, _raw_updated_at and others will be taken care of by @_addRawFieldsUpdatesToUpdateModifier().

      update =
        $unset: {}
        $currentDate: current_date_updates
        $set:
          users: []

      result = @processHandlers("BeforePseudoRemove", user_id, doc, update)
      if result is false
        return false

      for field_name of doc
        if field_name not in ["_id", "users", "seqId", "project_id", "_raw_added_users_dates", "_raw_updated_date", "_raw_removed_date", "_raw_removed_users", "_raw_removed_users_dates"]
          update.$unset[field_name] = ""

      @_addRawFieldsUpdatesToUpdateModifier(update, doc)

      APP.justdo_analytics.logMongoRawConnectionOp(@collection._name, "update", {_id: doc._id}, update)
      @collection.rawCollection().update {_id: doc._id}, update, Meteor.bindEnvironment (err) =>
        if err?
          console.error(err)

          return

        @processHandlers("AfterPseudoRemove", user_id, doc, update)

        return

      return false

    return

  _addRawFieldsUpdatesToTasksPrivateDataUpdateModifier: (modifier, existing_doc) ->
    # Note: edits modifier in place !

    if (existing_current_date_mod = modifier.$currentDate)?
      current_date_updates = existing_current_date_mod
    else
      current_date_updates = {}

    _.extend current_date_updates,
      _raw_updated_date: true

    #
    # Update changed modifiers
    #
    if not _.isEmpty current_date_updates
      modifier["$currentDate"] = current_date_updates

    return

  setupGridPrivateDataCollectionHooks: ->
    self = @

    @private_data_collection.before.insert =>
      # Since we need to update the raw fields that needs the update's operator $currentDate,
      # we can't allow inserts using the .insert() operator, only .upsert()s are allowed.
      throw @_error "operation-blocked", "Inserts aren't allowed on grid-data-com's @private_data_collection. Use @_upsertItemPrivateData() instead."

    @private_data_collection.before.upsert (user_id, selector, modifier, options) =>
      # At the moment we force all upserts to go through @_upsertItemPrivateData()
      # so we'll know for sure what to expect in terms of selector/modifier/options.
      if not Fiber.current._allow_tasks_private_data_upsert?
        throw @_error "operation-blocked", "Upserts for grid-data-com's @private_data_collection are allowed only when called from @_upsertItemPrivateData()."

      if "$unset" of modifier
        for field of modifier["$unset"]
          if "." not in field
            throw @_error "operation-blocked", "We do not permit $unset of top-level fields of the private data collection documents (read web-app Changelog for v1.117.0 to learn more)."

      @_addRawFieldsUpdatesToTasksPrivateDataUpdateModifier(modifier)

      return

    @private_data_collection.before.update (user_id, doc, field_names, modifier, options) =>
      # Since we want all the updates/inserts to go through @_upsertItemPrivateData()
      # as a single point for operations, we block updates.
      throw @_error "operation-blocked", "Updates aren't allowed on grid-data-com's @private_data_collection. Use @_upsertItemPrivateData() instead."

      return

    @private_data_collection.before.remove (user_id, doc) =>
      console.warn "Operation blocked: attempt to remove private data for task #{doc.task_id}, (private data doc id: #{doc._id}). We do not allow removal of private data docs as it interferes with the tasks_grid_um publication (Read web-app Changelog for v1.117.0 to learn more)."

      return false

    @collection.after.pseudo_remove (user_id, doc) =>
      # After an item is pseudo removed (equivalent to irreversible real remove), we remove all
      # the @private_data_collection items associated with the removed item.
      #
      # Read web-app Changelog for v1.117.0 to learn more .

      # This Query is using the FETCH_PROJECT_TASK_PRIVATE_DATA_OF_SPECIFIC_USER_INDEX index
      query = {task_id: doc._id}

      APP.justdo_analytics.logMongoRawConnectionOp(@private_data_collection._name, "remove", query)
      @private_data_collection.rawCollection().remove query, (err) ->
        if err?
          console.error(err)

        return

      return

    @collection.after.update (user_id, doc, field_names, modifier, options) ->
      if "users" in field_names
        # Maintain the _raw_frozen field of fields associated to the tasks private
        # data docs as a result of users changes.
        added_users = _.difference doc.users, @previous.users
        removed_users = _.difference @previous.users, doc.users

        if not _.isEmpty added_users
          self._setPrivateDataDocsFreezeState(added_users, [doc._id], false)

        if not _.isEmpty removed_users
          self._setPrivateDataDocsFreezeState(removed_users, [doc._id], true)

        console.warn "A task `users' field been updated using a direct call to the collections .update() method, it is highly recommanded to use the tasks_bulkUpdate ddp method or GridDataCom's bulkUpdate api, as they employ a far more efficient procedure."

      return

    return

  _freezeAllProjectPrivateDataDocsForUsersIds: (project_id, users_ids) ->
    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_TASK_PRIVATE_DATA_OF_SPECIFIC_USER_INDEX there)
    #
    query =
      project_id: project_id
      user_id:
        $in: users_ids

    modifier = {$set: {_raw_frozen: true}}

    APP.justdo_analytics.logMongoRawConnectionOp(@private_data_collection._name, "update", query, modifier, {multi: true})
    @private_data_collection.rawCollection().update query, modifier, {multi: true}, (err) ->
      if err?
        console.error(err)

      return

    return

  _setPrivateDataDocsFreezeState: (users_ids, tasks_ids, freeze=true) ->
    # Freeze any tasks_ids private data docs of users in users_ids.

    check users_ids, [String]
    check tasks_ids, [String]

    if freeze
      modifier = {$set: {_raw_frozen: true}}
    else
      modifier = {$unset: {_raw_frozen: ""}}

    @_addRawFieldsUpdatesToTasksPrivateDataUpdateModifier(modifier)

    for user_id in users_ids
      #
      # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
      # and to drop obsolete indexes (see FETCH_PROJECT_TASK_PRIVATE_DATA_OF_SPECIFIC_USER_INDEX there)
      #
      query = 
        task_id: 
          $in: tasks_ids
        user_id: user_id

      APP.justdo_analytics.logMongoRawConnectionOp(@private_data_collection._name, "update", query, modifier, {multi: true})
      @private_data_collection.rawCollection().update query, modifier, {multi: true}, (err) ->
        if err?
          console.error(err)

        return

    return

  _extractPrivateDataUpdatesFromMutatorInPlace: (mutator) ->
    # IMPORTANT! Mutator is edited in-place

    no_changes_to_public_task = false

    private_fields_mutator = {}
    for modifier, mutation of mutator
      for field, modification of mutation
        if field.substr(0, 5) == "priv:"
          Meteor._ensure private_fields_mutator, modifier, field

          private_fields_mutator[modifier][field] = modification

          delete mutation[field]

      # Remove modifiers that left without mutations
      if _.size(mutation) == 0
        delete mutator[modifier]

    if _.size(mutator) == 0
      no_changes_to_public_task = true

    if _.size(mutator) == 1 and _.size(mutator.$set) == 2 and mutator.$set.updated_by? and mutator.$set.updatedAt?
      no_changes_to_public_task = true

    return {no_changes_to_public_task, mutator, private_fields_mutator}

  setupGridCollectionWritesProxies: ->
    # We make the existance of the @private_data_collection transparent to the client
    # private fields defined for the user are published in the tasks_grid_um pulication
    # as if they were part of the @collection itself. The only identification we leave is
    # the "priv:" prefix, that we prefix the private fields with to identify them later on.
    #
    # Hence, when the client asks to perform actions on fields that begins with the "priv:" prefix,
    # we know that we actually need to update the user's private field doc of that task (and create
    # one if one doesn't exists).

    @collection.beforeAllowDenyUpdate = (user_id, selector, mutator, options, doc) =>
      # The hook for beforeAllowDenyUpdate is defined in: tasks-collection-constructor-and-initiator.js
      # of the justdo-tasks-collections-manager package.

      if not user_id?
        console.warn "beforeAllowDenyUpdate: Couldn't find #{user_id}, this shouldn't happen, check why it happened (skipping)"

        return

      if not (_.isString(selector) or (_.isObject(selector) and _.size(selector) == 1 and _.isString(selector._id)))
        console.warn "beforeAllowDenyUpdate: received selector which isn't of specific ID, this shouldn't happen, check why it happened (skipping)"

        return

      if not (project_id = doc.project_id)?
        console.warn "beforeAllowDenyUpdate: the associated task doesn't have project_id set to it, this shouldn't happen, check why it happened (skipping)"

        return      

      if _.isString selector
        task_id = selector
      else
        task_id = selector._id

      {no_changes_to_public_task, mutator, private_fields_mutator} =
        @_extractPrivateDataUpdatesFromMutatorInPlace(mutator)

      if _.size(private_fields_mutator) > 0
        # Note, by this point thanks to the allow deny rules defined on initDefaultGridAllowDenyRules() of the
        # grid data com package, we know for sure the user belongs to the task. We assume that since the
        # task belongs to the user, the user also belongs to the project (not necessarily true in the theoretical
        # case).
        #
        # Also, note, that the only fields that can be included in the private_fields_mutator are prefixed
        # with the "priv:" prefix, as required by _upsertItemPrivateData
        APP.projects._grid_data_com._upsertItemPrivateData(project_id, task_id, private_fields_mutator, user_id)

      if no_changes_to_public_task
        return false # don't proceed with the update to the tasks collection, there's nothing to do with it.

      return true

    return


  # Allow adding root child without going through the addChild method
  # to allow adding a root child to a specific non-logged-in user 
  addRootChild: (fields, perform_as) ->
    check(fields, Object)

    @_isPerformAsProvided(perform_as)

    new_item = _.extend {}, fields,
      parents:
        "0":
          order:
            @collection.getNewChildOrder("0", fields)
      users: [perform_as]

    @_runGridMethodMiddlewares "addChild", "/", new_item, perform_as

    return @_insertItem new_item

  addChild: (path, fields = {}, perform_as) ->
    check(path, String)
    check(fields, Object)

    @_isPerformAsProvided(perform_as)

    check(perform_as, String)

    if path == "/"
      return @addRootChild fields, perform_as

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    # If users for the new task weren't provided, set users to be the parent task users
    if not (users = fields.users)?
      users = item.users

    # perform_as must always be part of the task users
    if perform_as not in users
      users = users.slice()

      users.push(perform_as)

    new_item = _.extend {}, fields, {parents: {}, users: users}
    new_item.parents[item._id] = {order: @collection.getNewChildOrder(item._id, fields)}

    @_runGridMethodMiddlewares "addChild", path, new_item, perform_as

    return @_insertItem new_item

  addSibling: (path, fields = {}, perform_as) ->
    check(path, String)
    check(fields, Object)

    @_isPerformAsProvided(perform_as)

    check(perform_as, String)

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    parent_id = helpers.getPathParentId(path)

    # If users for the new task weren't provided
    if not (users = fields.users)?
      if parent_id == "0"
        # item that is added to the top level is added with the adding user only
        users = [perform_as]
      else
        # non top-level item inherents its parent users
        parent_doc = @collection.getItemById(parent_id)
        users = parent_doc.users

    # perform_as must always be part of the task users
    if perform_as not in users
      users = users.slice()

      users.push(perform_as)

    sibling_order = item.parents[parent_id].order + 1

    new_item = _.extend {}, fields, {parents: {}, users: users}
    new_item.parents[parent_id] = {order: sibling_order}

    @_runGridMethodMiddlewares "addSibling", path, new_item, perform_as

    @collection.incrementChildsOrderGte parent_id, sibling_order, item

    return @_insertItem new_item

  removeParent: (path, perform_as) ->
    check(path, String)

    @_isPerformAsProvided(perform_as)

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    parent_id = helpers.getPathParentId(path)

    if not (parent_id of item.parents)
      throw @_error "unknown-parent", "#{parent_id} isn't a parent of #{item._id}"

    # Perform removal
    if _.size(item.parents) == 1
      # Remove last parent, and the item itself.
      # We don't allow removing an item with children

      if @collection.getChildrenCount(item._id, item) > 0
        throw @_error "operation-blocked", 'Can\'t remove the last parent of an item that has sub-items. (You might not see sub-items you aren\'t member of)'

      @_runGridMethodMiddlewares "removeParent", path, perform_as,
        # the etc obj
        item: item 
        parent_id: parent_id,
        no_more_parents: true
        update_op: undefined

      @collection.remove item._id
    else
      # Remove parent
      update_op = {$unset: {}}
      update_op.$unset["parents.#{parent_id}"] = ""

      @_runGridMethodMiddlewares "removeParent", path, perform_as,
        # the etc obj
        item: item 
        parent_id: parent_id,
        no_more_parents: false
        update_op: update_op

      @collection.update item._id, update_op

    return
  
  addParent: (item_id, new_parent, perform_as) ->
    # new parent should be of the form:
    #
    # {
    #   parent: "", # the new parent id, use "0" for root
    #   order: int # order under the new parent - not required, will be added as the last item if not specified. 
    # }

    check(item_id, String)

    if (not _.isObject(new_parent))
      throw @_error "missing-argument", 'new_parent argument is missing'

    @_isPerformAsProvided(perform_as)

    new_parent = _.pick new_parent, ["parent", "order"]

    {parent, order} = new_parent
    new_parent_id = parent # Improved readability
    new_parent_order = order

    #
    # Validate args
    #
    if not new_parent_id?
      throw @_error "missing-argument", 'new_parent.parent is not set'      

    check(new_parent_id, String)
    check(new_parent_order, Match.Maybe(Number))

    if not (item = @collection.getItemByIdIfUserBelong item_id, perform_as)?
      throw @_error "unknown-id"

    # Check if already parent of item
    if new_parent_id of item.parents
      throw @_error "parent-already-exists"

    # Check whether item is an ancestor of new_parent_id
    if @collection.isAncestor(new_parent_id, item._id)
      throw @_error "infinite-loop", "Can\'t add parent: #{item._id} is an ancestor of #{new_parent_id}"

    # Check whether new_parent_id exists and belongs to user
    new_parent_item = null
    if new_parent_id != "0"
      # if 0, always belongs...
      new_parent_item = @collection.findOne(new_parent_id)
      if not(new_parent_item? and @collection.isUserBelongToItem(new_parent_item, perform_as))
        throw @_error "unknown-path", 'Error: Can\'t add parent: new parent doesn\'t exist' # we don't indicate existance in case no permission

    # If no new_parent_order provided, set to new_parent_order to the end of the item
    if not new_parent_order?
      new_parent_order = @collection.getNewChildOrder(new_parent_id, item)

    # Add new parent update operation object
    set_new_parent_update_op = {$set: {}}
    set_new_parent_update_op.$set["parents.#{new_parent_id}"] = {order: new_parent_order}

    @_runGridMethodMiddlewares "addParent", perform_as,
      # the etc obj
      new_parent: {
        parent: new_parent_id
        order: new_parent_order
      }
      item: item
      new_parent_item: new_parent_item
      update_op: set_new_parent_update_op

    # Check if an item exist already in new_parent_order
    item_in_new_location =
      @collection.getChildreOfOrder(new_parent_id, new_parent_order, item)

    if item_in_new_location?
      # if there's an item in the new location.
      # Note we check above that it isn't the same item. We don't use sub if since
      # we want to run the middlewares only when we are sure the operation is ready
      # to be performed. 
      @collection.incrementChildsOrderGte new_parent_id, new_parent_order, item

    @collection.update item._id, set_new_parent_update_op

    return

  updateItem: (item_id, update_op, perform_as) ->
    # edit item_id by performing the mongo structured update_op object on it.
    #
    # IMPORTANT - this method is meant to be used by trusted, server originated
    # operations only! Do not proxy a Meteor Method to it without carefully
    # checking the update operation and limiting it only to a set of allowed
    # updates operations - other wise your server will probably be volvulnerable
    # to mongo injections 

    check(item_id, String)
    check(update_op, Object) # this is enough only because we allow calling this method
                          # only by trusted code

    @_isPerformAsProvided(perform_as)

    #
    # Validate args
    #
    if not (item = @collection.getItemByIdIfUserBelong item_id, perform_as)?
      throw @_error "unknown-id"

    update_op = _.extend update_op # shallow copy original, since we
                                   # allow middlewares to change it

    @_runGridMethodMiddlewares "updateItem", perform_as,
      # the etc obj
      item: item
      update_op: update_op

    @collection.update item_id, update_op

    return

  movePath: (path, new_location, perform_as) ->
    check(path, String)
    check(new_location, {
      parent: Match.Maybe(String)
      order: Match.Maybe(Number)
    })

    @_isPerformAsProvided(perform_as)

    if (not _.isObject(new_location)) or
       (not (("order" of new_location) or ("parent" of new_location)))
        # if new_location doens't have information for new location
        throw @_error "missing-argument", 'Error: Can\'t move path: new_location argument lack information for new location'

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    current_parent_id = helpers.getPathParentId(path)

    if not ("parent" of new_location)
      # If parent is not provided in new_location we assume change of order under same item
      new_location.parent = current_parent_id

    if current_parent_id != new_location.parent
      if @collection.isAncestor(new_location.parent, item._id)
        throw @_error "infinite-loop", "Error: Can\'t move path: #{item._id} is an ancestor of #{new_location.parent}"

    new_parent_item = null
    if new_location.parent != "0"
      new_parent_item = @collection.findOne(new_location.parent)
      if not(new_parent_item? and @collection.isUserBelongToItem(new_parent_item, perform_as))
        throw @_error "unknown-path", 'Error: Can\'t move path: new parent doesn\'t exist' # we don't indicate existance in case no permission

    if not ("order" of new_location)
      new_location.order = @collection.getNewChildOrder(new_location.parent, item)

    # Remove current parent op prepeation
    remove_current_parent_update_op = {$unset: {}}
    remove_current_parent_update_op.$unset["parents.#{current_parent_id}"] = ""

    # Add to new parent op prepeation
    set_new_parent_update_op = {$set: {}}
    set_new_parent_update_op.$set["parents.#{new_location.parent}"] = {order: new_location.order}

    # Check if an item exist already in new_location order
    item_in_new_location = @collection.getChildreOfOrder(new_location.parent, new_location.order, item)

    # We used to have the following optimization but we found out that 
    # it doesn't work well.
    #
    # If an item has multiple parents and you try to move it from one parent
    # to another one in which it is in, under the same order, it should
    # combine into one with the one in the new location.
    #
    # With this optimization, the original position won't remove and
    # client will show wrong tree representation post-drop to the new
    # position, as in reality with this optimization we don't  perform
    # any action but the user actually changed the tree structure.
    #
    # if item_in_new_location? and item_in_new_location._id == item._id
    #   # There's already an item in the new location, the same item..., nothing to do.
    #   return

    @_runGridMethodMiddlewares "movePath", path, perform_as,
      # the etc obj
      new_location: _.extend {}, new_location
      item: item
      current_parent_id: current_parent_id
      new_parent_item: new_parent_item
      remove_current_parent_update_op: remove_current_parent_update_op
      set_new_parent_update_op: set_new_parent_update_op

    if item_in_new_location?
      # if there's an item in the new location.
      # Note we check above that it isn't the same item. We don't use sub if since
      # we want to run the middlewares only when we are sure the operation is ready
      # to be performed. 
      @collection.incrementChildsOrderGte new_location.parent, new_location.order, item

    # Remove current parent
    @collection.update item._id, remove_current_parent_update_op

    # Add to new parent
    @collection.update item._id, set_new_parent_update_op

    return

  sortChildren: (path, field, sort_order, perform_as) ->
    check(path, String)
    check(field, String)
    check(sort_order, Match.Maybe(Number))

    @_isPerformAsProvided(perform_as)

    if path == "/"
      throw @_error "cant-perform-on-root"

    if not (parent = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    query = {}
    query["parents.#{parent._id}"] = {$exists: true}

    sort = {}
    sort[field] = 1
    if sort_order != 1
      sort[field] = -1

    order = 0
    @collection.find(query, {sort: sort}).forEach (child) =>
      # IMPORTANT!!!
      #
      # If you change the following modifiers in the future
      # pay strong attention to the fact that we are bypassing collection2.
      #
      # Make sure your changes doesn't compromise security without collection2's
      # schema restrictions!

      set = {$set: {}}
      set.$set["parents.#{parent._id}.order"] = order

      # We don't want tasks which their order had been changed by the
      # sortChildren by command to show in the recently changed items.
      # We do so by so skipping collection2 procedures.
      # Result was very messy and counter-productive as a result of this action
      # in the recently updated view.

      @collection.update child._id, set, {bypassCollection2: true}, (err) =>
        if err?
          @logger.error "sortChildren: failed to change item order #{JSON.stringify(err)}"

      order += 1

    return

  _bulkUpdateFromSecureSource: (query, modifier, cb) ->
    # Like bulkUpdate, but when we trust query and modifier completely!

    @_addRawFieldsUpdatesToUpdateModifier(modifier)

    # Use rawCollection here, skip collection2/hooks
    APP.justdo_analytics.logMongoRawConnectionOp(@collection._name, "update", query, modifier, {multi: true})
    return @collection.rawCollection().update query, modifier, {multi: true}, Meteor.bindEnvironment (err) ->
      if err?
        console.error(err)

      JustdoHelpers.callCb cb, err

      return

  bulkUpdate: (items_ids, modifier, perform_as) ->
    #
    # Validate inputs
    #
    check(items_ids, [String])

    # To avoid security risk, we are whitelisting the allowed bulkUpdates
    allowed_modifiers = [
      {
        $pull:
          users:
            $in: [String]
      }
      {
        $push:
          users:
            $each: [String]
      }
      {
        $set:
          owner_id: String
          pending_owner_id: null
      }
      {
        $set:
          pending_owner_id: null
      }
    ]
    check(modifier, Match.OneOf.apply(Match, allowed_modifiers))

    @_isPerformAsProvided(perform_as)

    #
    # Exec
    #

    # Returns the count of changed items
    selector = 
      _id:
        $in: items_ids
      users: perform_as

    @_runGridMethodMiddlewares "bulkUpdate", selector, modifier, perform_as

    # We make sure that the middleware don't change this condition, too risky.
    selector.users = perform_as

    # XXX in terms of security we rely on the fact that the user belongs to
    # the requested items (see selector query) to let him/her do basically
    # whatever action they like (worst case... he destory his own data.
    # perhaps in the future we'd like to apply some more checks here.

    added_users = []
    removed_users = []

    if (pushed_users = modifier.$push?.users?.$each)?
      added_users = added_users.concat(pushed_users)

    if (pulled_users = modifier.$pull?.users?.$in)?
      removed_users = removed_users.concat(pulled_users)

    if not _.isEmpty added_users
      @_setPrivateDataDocsFreezeState(added_users, items_ids, false)

    if not _.isEmpty removed_users
      @_setPrivateDataDocsFreezeState(removed_users, items_ids, true)

    return @_bulkUpdateFromSecureSource(selector, modifier)

  getContexts: (task_id, options, perform_as) ->
    options = {} # Force to empty object for now, options will be defined in the future

    check(task_id, String)

    @_isPerformAsProvided(perform_as)

    findParentsPaths = (task_id, user_id, _first_iteration=true) =>
      # This function will return an array of arrays of the following form:
      #
      # [
      #  [{_id: "", title: "", seqId: ""}, {_id: "", title: "", seqId: ""}, ...]
      #  [{_id: "", title: "", seqId: ""}, {_id: "", title: "", seqId: ""}, ...]
      # ]
      #
      # Each sub-array represents task_id's path that is known to user_id .
      #
      # Notes:
      #
      # 1. We represent items that aren't known to the user with _id: -1
      #
      #   Example path: 
      #   [ { _id: -1, title: 'Shared with me', seqId: null },
      #       { _id: 'cxhpvSW3zC6mkoZ4C', title: undefined, seqId: 29 },
      #       { _id: 'JDCfBrRJkW2DnvDjG', title: undefined, seqId: 30 },
      #       { _id: 'doJWiByooShyeHtzS', title: undefined, seqId: 31 } ]
      #
      # 2. As in other places, root is represented with _id: 0
      #
      # 3. seqId will be null for pseudo items (root, shared with me)
      #
      # 4. IMPORTANT: The following pseudo items aren't supported at the moment:
      #    Tickets Queues, Direct Tasks.
      #
      # Todo:
      #
      # This alg involves n calls to the mongo server where n is the amount of ancestors.
      # Can be optimised to n calls where n is the longest path to root.

      contexts = []

      if (task = @collection.findOne({_id: task_id, users: user_id}))?
        for parent_id, parent_info of task.parents
          if parent_id != "0"
            contexts = contexts.concat(findParentsPaths(parent_id, user_id, false))
          else
            contexts = contexts.concat([[{_id: 0, title: "", seqId: null}]])

        for context in contexts
          context.push {_id: task._id, title: task.title, seqId: task.seqId}
      else
        if _first_iteration
          # If first iteration, the user doesn't even know the task_id
          # provided to getContexts(), or the task doesn't exists at all

          return []

        contexts = contexts.concat([[{_id: -1, title: "Shared with me", seqId: null}]])

      return contexts

    contexts = findParentsPaths task_id, perform_as

    known_parent_exists = false
    unknown_parents_found = false
    for context, i in contexts
      if context[0]._id != -1 or context.length > 2
        known_parent_exists = true
      
      if context[0]._id == -1 and context.length == 2
        if unknown_parents_found
          # An item will appear as a child of Shared with me for only one of its parents.
          contexts[i] = null
        else
          unknown_parents_found = true

    contexts = _.compact contexts

    if known_parent_exists and unknown_parents_found
      # If an item got known parents, the parents that aren't known won't cause
      # him to appear under the shared with me (it won't appear under the shared
      # with me at all)
      contexts = _.filter contexts, (context) -> context[0]._id != -1 or context.length > 2

    return contexts
