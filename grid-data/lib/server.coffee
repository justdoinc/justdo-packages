helpers = share.helpers
exceptions = share.exceptions

initDefaultGridMethods = (collection) ->
  methods = {}

  methods[helpers.getCollectionMethodName(collection, "addChild")] = (path, fields = {}) ->
    if @userId?
      if path == "/"
        new_item = _.extend {}, fields,
          parents:
            "0":
              order:
                collection.getNewChildOrder("0")
          users: [@userId]

        return collection.insert new_item
    else
      throw exceptions.loginRequired()

    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      new_item = _.extend {}, fields, {parents: {}, users: item.users}
      new_item.parents[item._id] = {order: collection.getNewChildOrder(item._id)}
      return collection.insert new_item
    else
      throw exceptions.unkownPath()

  methods[helpers.getCollectionMethodName(collection, "addSibling")] = (path, fields = {}) ->
    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      parent_id = helpers.getPathParentId(path)
      sibling_order = item.parents[parent_id].order + 1
      
      collection.incrementChildsOrderGte parent_id, sibling_order

      new_item = _.extend {}, fields, {parents: {}, users: item.users}
      new_item.parents[parent_id] = {order: sibling_order}
      ret = collection.insert new_item
      return ret
    else
      throw exceptions.unkownPath()

  methods[helpers.getCollectionMethodName(collection, "removeParent")] = (path) ->
    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      parent_id = helpers.getPathParentId(path)

      if collection.getChildrenCount(item._id) > 0
        throw new Meteor.Error(500, 'Error: Can\'t remove: Item have childrens (you might not have the permission to see all childrens)')

      if (_.size item.parents) == 1
        collection.remove item._id, update_op
      else
        update_op = {$unset: {}}
        update_op.$unset["parents.#{parent_id}"] = ""
        collection.update item._id, update_op
    else
      throw exceptions.unkownPath()

  methods[helpers.getCollectionMethodName(collection, "movePath")] = (path, new_location) ->
    if (not _.isObject(new_location)) or
       (not (("order" of new_location) or ("parent" of new_location)))
        # if new_location doens't have information for new location
        throw new Meteor.Error("missing-argument", 'Error: Can\'t move path: new_location argument lack information for new location')

    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      parent_id = helpers.getPathParentId(path)

      if not ("parent" of new_location)
        # If parent is not provided in new_location we assume change of order under same item
        new_location.parent = parent_id

      if parent_id != new_location.parent
        if collection.isAncestor(new_location.parent, item._id)
          throw new Meteor.Error("infinite-loop", "Error: Can\'t move path: #{new_location.parent} ancestor of #{parent_id}")

      new_parent_item = collection.findOne(new_location.parent)
      if new_location.parent != "0" and not(new_parent_item? and collection.isUserBelongToItem(new_parent_item, @userId))
        throw new Meteor.Error("unkown-path", 'Error: Can\'t move path: new parent doesn\'t exist') # we don't indicate existance in case no permission

      if not ("order" of new_location)
        new_location.order = collection.getNewChildOrder new_location.parent

      # Check if an item exist already in new_location order
      item_in_new_location = collection.getChildreOfOrder(new_location.parent, new_location.order)

      if item_in_new_location?
        # if there's an item in new location already.
        if item_in_new_location._id == item._id
          # if same item, do nothing
          return
        else
          # Make space for the move
          collection.incrementChildsOrderGte new_location.parent, new_location.order

      # Remove current parent
      update_op = {$unset: {}}
      update_op.$unset["parents.#{parent_id}"] = ""
      collection.update item._id, update_op

      # Add to new parent
      update_op = {$set: {}}
      update_op.$set["parents.#{new_location.parent}"] = {order: new_location.order}
      collection.update item._id, update_op
    else
      throw exceptions.unkownPath()

  Meteor.methods methods

initDefaultGridAllowDenyRules = (collection) ->
  collection.allow
    update: (userId, doc, fieldNames, modifier) -> collection.isUserBelongToItem(doc, userId)

initDefaultIndeices = (collection) ->
  collection._ensureIndex {users: 1}

initDefaultCollectionMethods = (collection) ->
  _.extend collection,
    getItemByPath: (path) -> collection.findOne helpers.getPathItemId path

    getItemById: (item_id) -> collection.findOne item_id

    isUserBelongToItem: (item, userId) -> userId in item.users

    getItemByPathIfUserBelong: (path, userId) -> if (item = collection.getItemByPath(path))? and collection.isUserBelongToItem(item, userId) then item else null

    getChildrenCount: (item_id) ->
      query = {}
      query["parents.#{item_id}.order"] = {$gte: 0}
      collection.find(query).count()

    getNewChildOrder: (item_id) ->
      query = {}
      sort = {}
      query["parents.#{item_id}.order"] = {$gte: 0}
      sort["parents.#{item_id}.order"] = -1

      current_max_order_child = collection.findOne(query, {sort: sort})
      if current_max_order_child?
        new_order = current_max_order_child.parents[item_id].order + 1
      else
        new_order = 0

      new_order

    incrementChildsOrderGte: (parent_id, min_order_to_inc) ->
      query = {}
      query["parents.#{parent_id}.order"] = {$gte: min_order_to_inc}
      update_op = {$inc: {}}
      update_op["$inc"]["parents.#{parent_id}.order"] = 1
      collection.update query, update_op, {multi: true}

    getChildreOfOrder: (item_id, order) ->
      query = {}
      query["parents.#{item_id}.order"] = order
      collection.findOne(query)

    isAncestor: (item_id, potential_ancestor_id) ->
      # Returns true if potential_ancestor_id is ancesotr of item_id or the same item
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

initDefaultGridServerSideConf = (collection) ->
  initDefaultGridMethods collection
  initDefaultGridAllowDenyRules collection
  initDefaultIndeices collection
  initDefaultCollectionMethods collection

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
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

    Meteor.publish options.name, () ->
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