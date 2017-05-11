helpers = share.helpers

_.extend GridDataCom.prototype,
  _isPerformAsProvided: (perform_as) ->
    if not perform_as?
      throw @_error "missing-argument", "You must provide the perform_as field"

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

    return @collection.insert new_item

  addChild: (path, fields = {}, perform_as) ->
    check(path, String)
    check(fields, Object)

    @_isPerformAsProvided(perform_as)

    check(perform_as, String)

    if path == "/"
      return @addRootChild fields, perform_as

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    new_item = _.extend {}, fields, {parents: {}, users: item.users}
    new_item.parents[item._id] = {order: @collection.getNewChildOrder(item._id, fields)}

    @_runGridMethodMiddlewares "addChild", path, new_item, perform_as

    return @collection.insert new_item

  addSibling: (path, fields = {}, perform_as) ->
    check(path, String)
    check(fields, Object)

    @_isPerformAsProvided(perform_as)

    check(perform_as, String)

    if not (item = @collection.getItemByPathIfUserBelong path, perform_as)?
      throw @_error "unknown-path"

    parent_id = helpers.getPathParentId(path)
    if parent_id == "0"
      # item that is added to the top level is added with the adding user only
      users = [perform_as]
    else
      # non top-level item inherents its parent users
      parent_doc = @collection.getItemById(parent_id)
      users = parent_doc.users

    sibling_order = item.parents[parent_id].order + 1

    new_item = _.extend {}, fields, {parents: {}, users: users}
    new_item.parents[parent_id] = {order: sibling_order}

    @_runGridMethodMiddlewares "addSibling", path, new_item, perform_as

    @collection.incrementChildsOrderGte parent_id, sibling_order, item

    return @collection.insert new_item

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
        $unset:
          pending_owner_id: String # In reality we expect here only ""
      }
      {
        $unset:
          pending_owner_id: String # In reality we expect here only ""
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
    return @collection.update selector, modifier, {multi: true}
