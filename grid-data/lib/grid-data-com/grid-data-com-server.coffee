helpers = share.helpers

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  @initDefaultCollectionMethods()

  @initDefaultGridMethods()

  @initDefaultIndeices()

  # Note: to avoid obfuscating critical security consideration that
  # should be made by the app developer, we don't init the grid allow/deny
  # rules on init
  # @initDefaultGridAllowDenyRules()

  @_grid_methods_middlewares = {}

  return @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
  logger: Logger.get("grid-data")

  _error: JustdoHelpers.constructor_error

  setupGridPublication: (options = {}) ->
    self = this

    default_options =
      name: helpers.getCollectionPubSubName(@collection)
      require_login: true
      exposed_to_guests: false
      # If true, logged in users will see items that don't have them in the users field.
      # If require_login is true exposed_to_guest option will be ignored and regarded as true.
      middleware_incharge: false # Have no effect if middleware is null, see docs for middleware option
      middleware: null
      # A method that gets the collection and options provied to setGridPublication
      # along subscription arguments and references (copy or create a new before changing)
      # to the current query and condition.
      #
      # Should return an array of the form [query, condition] with the new query and
      # condition to use for the provided cursor.
      #
      # If returns false, we regard it as a blocked request for subscription,
      # we will return an empty publication. 
      #
      # `this` context is same as the Meteor.publish's
      #
      # Example:
      # middleware: (collection, options, sub_args, query, projection) -> [query, projection]
      #
      # If middleware_incharge option is true, we will just return the returned value
      # of the middleware to the main publication, which means that the middleware
      # is in charge of the final cursor provided to the subscription (if you chose to
      # return one...)
      #
      # Example:
      # middleware: (collection, options, sub_args, query, projection) -> collection.find query, projection

    options = _.extend default_options, options

    Meteor.publish options.name, (subscription_options) ->
      # `this` is the Publication context, use self for GridData instance 
      if options.require_login
        if not @userId?
          @ready()

          return

      query = {}
      projection = {}

      if options.require_login and not options.exposed_to_guests
        query.users = @userId

      middleware = options.middleware
      if middleware?
        if options.middleware_incharge
          return middleware.call @, self.collection, options, _.toArray(arguments), query, projection
        else
          result = middleware.call @, self.collection, options, _.toArray(arguments), query, projection

          if not result
            @ready()

            return
          else
            [query, projection] = result

            return self.collection.find query, projection
      else
        return self.collection.find query, projection

  initDefaultIndeices: ->
    @collection._ensureIndex {users: 1}

  initDefaultGridAllowDenyRules: ->
    collection = @collection

    collection.allow
      update: (userId, doc, fieldNames, modifier) ->
        # Keep the following for testing, helps to test
        # behavior on update failure
        # return false
        collection.isUserBelongToItem(doc, userId)

  initDefaultCollectionMethods: ->
    collection = @collection

    _.extend collection,
      getItemByPath: (path) -> collection.findOne helpers.getPathItemId path

      getItemById: (item_id) -> collection.findOne item_id

      isUserBelongToItem: (item, userId) -> userId in item.users

      getItemByPathIfUserBelong: (path, userId) -> if (item = collection.getItemByPath(path))? and collection.isUserBelongToItem(item, userId) then item else null

      getChildrenCount: (item_id, item_doc=null) ->
        # item_doc serves the same purpose new_child_fields serves in
        # @getNewChildOrder, read comment there in its entirety
        # including XXX section
        query = {}
        query["parents.#{item_id}.order"] = {$gte: 0}
        return collection.find(query).count()

      getNewChildOrder: (parent_id, new_child_fields=null) ->
        # Note: this @getNewChildOrder() does nothing with new_child_fields
        # but, custom methods that will replace it might need information
        # about the new_child_fields.
        #
        # Example: in one of grid-data-com usecases, root-items belongs to projects,
        # hence, if an item is under the root, i.e. parent_id="0", the order
        # should be project specific and not general to all projects, we need
        # therefore the project_id to which the new child belongs to.
        #
        # XXX in the future, in order to allow root item to be under multiple
        # projects roots, the same way an item can be under multiple parents.
        # Instead of using "0" as root, a format such as "root:#{project_id}"
        # should be used. And the concept of Trees, that is, the generalization
        # of project_id concept, should introduce to grid-data.
        # Following such implementation the new_child_fields argument above
        # will become redundant and should be removed.
        query = {}
        sort = {}
        query["parents.#{parent_id}.order"] = {$gte: 0}
        sort["parents.#{parent_id}.order"] = -1

        current_max_order_child = collection.findOne(query, {sort: sort})
        if current_max_order_child?
          new_order = current_max_order_child.parents[parent_id].order + 1
        else
          new_order = 0

        return new_order

      incrementChildsOrderGte: (parent_id, min_order_to_inc, item_doc=null) ->
        # item_doc serves the same purpose new_child_fields serves in
        # @getNewChildOrder, read comment there in its entirety
        # including XXX section
        query = {}
        query["parents.#{parent_id}.order"] = {$gte: min_order_to_inc}
        update_op = {$inc: {}}
        update_op["$inc"]["parents.#{parent_id}.order"] = 1

        return collection.update query, update_op, {multi: true}

      getChildreOfOrder: (item_id, order, item_doc=null) ->
        # item_doc serves the same purpose new_child_fields serves in
        # @getNewChildOrder, read comment there in its entirety
        # including XXX section
        query = {}
        query["parents.#{item_id}.order"] = order
        
        return collection.findOne(query)

      isAncestor: (item_id, potential_ancestor_id) ->
        # Returns true if potential_ancestor_id is ancestor of item_id or the same item
        if potential_ancestor_id == item_id
          return true

        if item_id == "0"
          # Root reached
          return false

        item = collection.getItemById(item_id)

        if not item?
          # XXX We avoid dealing with broken chains for now
          return false

        parents_situation = false
        for parent_id, parent_info of item.parents
          parents_situation ||= collection.isAncestor(parent_id, potential_ancestor_id)

        return parents_situation

  setGridMethodMiddleware: (method_name, middleware) ->
    # Assigned middlewares are called just before the default execution of the method
    # with the calling Meteor Method `this` variable as their `this`, and with some
    # additional arguments.
    #
    # Middleware allows rejecting the execution and can be used to perform additional
    # operations.
    #
    # There can be more than one middleware for a given grid method, middlewares will
    # run by the order in which they were defined.
    #
    # Any value other than `true` returned from a middleware will be regarded as a block
    # message. If the message is an instance of Error we will throw it. If it isn't we will
    # use it as the message for a new Meteor.Error of type "grid-method-blocked" and throw
    # it.
    #
    # Each grid method provides different arguments to its middlewares as follows:
    #
    # Note: for all the grid methods the `this` var will be the same as the Meteor
    # Method's this.
    #
    # addChild: (path, new_item_fields)
    # path is the path to which the new item is about to be added.
    #
    # new_item_fields reference to the original object and is not a copy for the purpose of
    # allowing it to be customized by the middlewares.
    #
    # addSibling: (path, new_item_fields)
    # path is the path to which the new item is going to be sibling of.
    #
    # new_item_fields reference to the original object and is not a copy for the purpose of
    # allowing it to be customized by the middlewares.
    #
    # removeParent: (path, etc)
    # path is the path we are going to remove.
    #
    # etc is an object that contains the following keys:
    #
    #   etc.item is the document of the item we're about to remove -> do not change this object
    #   without cloning it to avoid bugs in following middlewares.
    #
    #   etc.parent_id is provided to ease getting it.
    # 
    #   etc.no_more_parents, if etc.no_more_parents is true, it means that the item is about to be completely removed.
    #   if no_more_parents is false, there are more parents to the item, and we will just
    #   remove the requested parent with an update command.
    #
    #   etc.update_op, reference to the original object and is not a copy for the purpose of
    #   allowing it to be customized by the middlewares. update_op will be provided only
    #   when no_more_parents is false, will be undefined otherwise.
    #
    # movePath: (path, etc)
    # path is the path we are going to move.
    #
    # etc is an object that contains the following keys:
    #
    #   etc.new_location is a *copy* of the computed new_location target based on
    #   the argument provided and defaults applied. Do not change this object. Changing it
    #   will have no effect on movePath execution and might result in bugs in following
    #   middlewares.
    #
    #   etc.item is the document of the item we are moving
    #
    #   etc.current_parent_id, the id of the parent we are moving this item from
    #
    #   etc.new_parent_item, the document of the new parent
    #
    # sortChildren: ()
    # middlewares on sortChildren won't be called and has no effect on execution
    #
    # bulkUpdate: (selector, modifier)
    # selector is a reference to the selector we are about to use in the update
    # operation. Isn't a copy for the purpose of allowing it to be customized by
    # the middlewares.
    # Note: users selector isn't editable and will be overriden to the original if changed.
    #
    # modifier is a reference to the modifier we are about to use in the update
    # operation. Isn't a copy for the purpose of allowing it to be customized by
    # the middlewares.
    #
    methods_names = ["addChild", "addSibling", "removeParent", "movePath", "sortChildren", "bulkUpdate"]

    if method_name not in methods_names
      throw @_error "unknown-method-name", "Unknown method name: #{method_name}, use one of: #{methods_names.join(", ")}"

    if not _.isFunction middleware
      throw @_error "wrong-type", "Middleware has to be a function"

    if not @_grid_methods_middlewares[method_name]?
      @_grid_methods_middlewares[method_name] = []

    @_grid_methods_middlewares[method_name].push middleware

  _getGridMethodMiddleware: (method_name) -> @_grid_methods_middlewares[method_name] or []

  _runGridMethodMiddlewares: (method_this, method_name) ->
    # _runGridMethodMiddlewares: (method_this, method_name, middleware_arg1, middleware_arg2, ...)
    # Method this should be the this variable of the calling grid method. Limitation of the js
    # lang don't allow this API to be nicer.
    # Important, you can rely only on @userId inside this
    method_args = _.toArray(arguments).slice(2)

    for middleware in @_getGridMethodMiddleware(method_name)
      message = middleware.apply method_this, method_args

      if message == true
        # no issue continue to run the next middleware
        continue
      if message instanceof Error
        throw message
      throw @_error "grid-method-blocked", message

  initDefaultGridMethods: ->
    self = @

    methods = {}

    collection = @collection

    # Allow adding root child without going through the addChild method
    # to allow adding a root child to a specific non-logged-in user 
    self.addRootChild = (first_user_id, fields) ->
      new_item = _.extend {}, fields,
        parents:
          "0":
            order:
              collection.getNewChildOrder("0", fields)
        users: [first_user_id]

      self._runGridMethodMiddlewares {userId: first_user_id}, "addChild", "/", new_item

      return collection.insert new_item

    methods[helpers.getCollectionMethodName(collection, "addChild")] = (path, fields = {}) ->
      check(path, String)
      check(fields, Object)

      if not @userId?
        throw self._error "login-required"

      if path == "/"
        return self.addRootChild(@userId, fields)

      if not (item = collection.getItemByPathIfUserBelong path, @userId)?
        throw self._error "unknown-path"

      new_item = _.extend {}, fields, {parents: {}, users: item.users}
      new_item.parents[item._id] = {order: collection.getNewChildOrder(item._id, fields)}

      self._runGridMethodMiddlewares @, "addChild", path, new_item

      return collection.insert new_item

    methods[helpers.getCollectionMethodName(collection, "addSibling")] = (path, fields = {}) ->
      check(path, String)
      check(fields, Object)

      if not (item = collection.getItemByPathIfUserBelong path, @userId)?
        throw self._error "unknown-path"

      parent_id = helpers.getPathParentId(path)
      if parent_id == "0"
        # item that is added to the top level is added with the adding user only
        users = [@userId]
      else
        # non top-level item inherents its parent users
        parent_doc = collection.getItemById(parent_id)
        users = parent_doc.users

      sibling_order = item.parents[parent_id].order + 1

      new_item = _.extend {}, fields, {parents: {}, users: users}
      new_item.parents[parent_id] = {order: sibling_order}

      self._runGridMethodMiddlewares @, "addSibling", path, new_item

      collection.incrementChildsOrderGte parent_id, sibling_order, item

      return collection.insert new_item

    methods[helpers.getCollectionMethodName(collection, "removeParent")] = (path) ->
      check(path, String)
      if not (item = collection.getItemByPathIfUserBelong path, @userId)?
        throw self._error "unknown-path"

      parent_id = helpers.getPathParentId(path)

      if not (parent_id of item.parents)
        throw self._error "unknown-parent", "#{parent_id} isn't a parent of #{item._id}"

      # Perform removal
      if _.size(item.parents) == 1
        # Remove last parent, and the item itself.
        # We don't allow removing an item with children

        if collection.getChildrenCount(item._id, item) > 0
          throw self._error "operation-blocked", 'Can\'t remove the last parent of an item that has sub-items. (You might not see sub-items you aren\'t member of)'

        self._runGridMethodMiddlewares @, "removeParent", path,
          # the etc obj
          item: item 
          parent_id: parent_id,
          no_more_parents: true
          update_op: undefined

        collection.remove item._id
      else
        # Remove parent
        update_op = {$unset: {}}
        update_op.$unset["parents.#{parent_id}"] = ""

        self._runGridMethodMiddlewares @, "removeParent", path,
          # the etc obj
          item: item 
          parent_id: parent_id,
          no_more_parents: false
          update_op: update_op

        collection.update item._id, update_op

    methods[helpers.getCollectionMethodName(collection, "movePath")] = (path, new_location) ->
      check(path, String)
      check(new_location, {
        parent: Match.Maybe(String)
        order: Match.Maybe(Number)
      })

      if (not _.isObject(new_location)) or
         (not (("order" of new_location) or ("parent" of new_location)))
          # if new_location doens't have information for new location
          throw self._error "missing-argument", 'Error: Can\'t move path: new_location argument lack information for new location'

      if not (item = collection.getItemByPathIfUserBelong path, @userId)?
        throw self._error "unknown-path"

      current_parent_id = helpers.getPathParentId(path)

      if not ("parent" of new_location)
        # If parent is not provided in new_location we assume change of order under same item
        new_location.parent = current_parent_id

      if current_parent_id != new_location.parent
        if collection.isAncestor(new_location.parent, item._id)
          throw self._error "infinite-loop", "Error: Can\'t move path: #{item._id} is an ancestor of #{new_location.parent}"

      new_parent_item = null
      if new_location.parent != "0"
        new_parent_item = collection.findOne(new_location.parent)
        if not(new_parent_item? and collection.isUserBelongToItem(new_parent_item, @userId))
          throw self._error "unknown-path", 'Error: Can\'t move path: new parent doesn\'t exist' # we don't indicate existance in case no permission

      if not ("order" of new_location)
        new_location.order = collection.getNewChildOrder(new_location.parent, item)

      # Remove current parent op prepeation
      remove_current_parent_update_op = {$unset: {}}
      remove_current_parent_update_op.$unset["parents.#{current_parent_id}"] = ""

      # Add to new parent op prepeation
      set_new_parent_update_op = {$set: {}}
      set_new_parent_update_op.$set["parents.#{new_location.parent}"] = {order: new_location.order}

      # Check if an item exist already in new_location order
      item_in_new_location = collection.getChildreOfOrder(new_location.parent, new_location.order, item)
      if item_in_new_location? and item_in_new_location._id == item._id
        # There's already an item in the new location, the same item..., nothing to do.
        return

      self._runGridMethodMiddlewares @, "movePath", path,
        # the etc obj
        new_location: _.extend {}, new_location
        item: item
        current_parent_id: current_parent_id
        new_parent_item: new_parent_item

      if item_in_new_location?
        # if there's an item in the new location.
        # Note we check above that it isn't the same item. We don't use sub if since
        # we want to run the middlewares only when we are sure the operation is ready
        # to be performed. 
        collection.incrementChildsOrderGte new_location.parent, new_location.order, item

      # Remove current parent
      collection.update item._id, remove_current_parent_update_op

      # Add to new parent
      collection.update item._id, set_new_parent_update_op

    methods[helpers.getCollectionMethodName(collection, "sortChildren")] = (path, field, sort_order) ->
      check(path, String)
      check(field, String)
      check(sort_order, Match.Maybe(Number))

      if path == "/"
        throw self._error "cant-perform-on-root"

      if not (parent = collection.getItemByPathIfUserBelong path, @userId)?
        throw self._error "unknown-path"

      query = {}
      query["parents.#{parent._id}"] = {$exists: true}

      sort = {}
      sort[field] = 1
      if sort_order != 1
        sort[field] = -1

      order = 0
      collection.find(query, {sort: sort}).forEach (child) ->
        set = {$set: {}}
        set.$set["parents.#{parent._id}.order"] = order
        collection.update child._id, set, (err) ->
          if err?
            self.logger.error "sortChildren: failed to change item order #{JSON.stringify(err)}"
        order += 1

    methods[helpers.getCollectionMethodName(collection, "bulkUpdate")] = (items_ids, modifier) ->
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

      #
      # Exec
      #

      # Returns the count of changed items
      selector = 
        _id:
          $in: items_ids
        users: @userId

      self._runGridMethodMiddlewares @, "bulkUpdate", selector, modifier

      # We make sure that the middleware don't change this condition, too risky.
      selector.users = @userId

      # XXX in terms of security we rely on the fact that the user belongs to
      # the requested items (see selector query) to let him/her do basically
      # whatever action they like (worst case... he destory his own data.
      # perhaps in the future we'd like to apply some more checks here.
      return collection.update selector, modifier, {multi: true}

    Meteor.methods methods
