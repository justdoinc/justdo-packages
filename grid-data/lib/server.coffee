helpers = share.helpers
exceptions = share.exceptions

initDefaultGridMethods = (collection) ->
  methods = {}

  methods[helpers.getCollectionMethodName(collection, "addChild")] = (path) ->
    # returns child_id or null if failed
    if path == "/" and @userId?
      new_item =
        parents:
          "0":
            order:
              collection.getNewChildOrder("0")
        users: [@userId]

      return collection.insert new_item
    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      new_item = {parents: {}, users: item.users}
      new_item.parents[item._id] = {order: collection.getNewChildOrder(item._id)}
      return collection.insert new_item
    else
      throw exceptions.unkownPath()

  methods[helpers.getCollectionMethodName(collection, "addSibling")] = (path) ->
    if (item = collection.getItemByPathIfUserBelong path, @userId)?
      parent_id = helpers.getPathParentId(path)
      sibling_order = item.parents[parent_id].order + 1
      
      collection.incrementChildsOrderGte parent_id, sibling_order

      new_item = {parents: {}, users: item.users}
      new_item.parents[parent_id] = {order: sibling_order}
      return collection.insert new_item
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

  Meteor.methods methods

initDefaultGridAllowDenyRules = (collection) ->
  collection.allow
    update: (userId, doc, fieldNames, modifier) -> collection.isUserBelongToItem(doc, userId)

initDefaultGridPubSub = (collection) ->
  Meteor.publish helpers.getCollectionPubSubName(collection), ->
    if not @userId?
      @ready()

      return

    collection.find {users: {$elemMatch: {$eq: @userId}}}

initDefaultIndeices = (collection) ->
  collection._ensureIndex {users: 1}

initDefaultCollectionMethods = (collection) ->
  _.extend collection,
    getItemByPath: (path) -> collection.findOne helpers.getPathItemId path

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

initDefaultGridServerSideConf = (collection) ->
  initDefaultGridMethods collection
  initDefaultGridAllowDenyRules collection
  initDefaultGridPubSub collection
  initDefaultIndeices collection
  initDefaultCollectionMethods collection
