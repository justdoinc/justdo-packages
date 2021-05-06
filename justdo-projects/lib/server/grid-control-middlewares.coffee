_.extend Projects.prototype,
  _setupGridControlMiddlewares: ->
    projects_object = @

    extendNewItemFields = (new_item_fields, project_doc, perform_as) ->
      new_item_fields.seqId =
        projects_object.allocateNewTaskSeqId project_doc._id

      new_item_fields.created_by_user_id = perform_as

      return

    new_item_middleware = (path, new_item_fields, perform_as) ->
      project_id = new_item_fields.project_id

      if not project_id?
        throw projects_object._error "missing-argument", "Task fields must include the project_id field"

      project_doc = projects_object.requireUserIsMemberOfProject(project_id, perform_as)

      extendNewItemFields new_item_fields, project_doc, perform_as

      return true

    @_grid_data_com.setGridMethodMiddleware "addChild", new_item_middleware

    @_grid_data_com.setGridMethodMiddleware "addSibling", new_item_middleware

    @_grid_data_com.setGridMethodMiddleware "removeParent", (path, perform_as, etc) ->
      if (update_op = etc.update_op)?
        # If the item is removed completly (last parent removed) update_op won't
        # be defined

        Meteor._ensure update_op, "$set"
        update_op.$set.updated_by = perform_as

      return true

    @_grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) ->
      update_op = etc.update_op
      Meteor._ensure update_op, "$set"
      update_op.$set.updated_by = perform_as

      return true

    @_grid_data_com.setGridMethodMiddleware "updateItem", (perform_as, etc) ->
      update_op = etc.update_op
      Meteor._ensure update_op, "$set"
      update_op.$set.updated_by = perform_as

      return true

    @_grid_data_com.setGridMethodMiddleware "movePath", (path, perform_as, etc) ->
      for update_op_field_name in ["remove_current_parent_update_op", "set_new_parent_update_op"]
        update_op = etc[update_op_field_name]
        Meteor._ensure update_op, "$set"
        update_op.$set.updated_by = perform_as

      return true

    # XXX All the following replacements for the original methods
    # created by grid-data-com are due to the lack of project
    # awarness in the grid-data-com level, once we'll introduce it
    # the following will be redundant. 
    @items_collection.getNewChildOrder = (parent_id, new_child_fields=null, options) ->
      # XXX read getNewChildOrder documentation at
      # grid-data-com-server.coffee

      query = {}
      sort = {}
      query["parents.#{parent_id}.order"] = {$gte: 0}
      if (project_id = new_child_fields?.project_id)?
        check project_id, String

        query["project_id"] = project_id
      else
        console.warn "getNewChildOrder: new_child_fields.project_id isn't available. This cause a substantial hit to getNewChildOrder performance"

      sort["parents.#{parent_id}.order"] = -1

      current_max_order_child = @findOne(query, {sort: sort})
      if current_max_order_child?
        new_order = current_max_order_child.parents[parent_id].order + 1
      else
        new_order = 0

      return new_order

    @items_collection.getChildrenCount = (item_id, item_doc=null) ->
      query = {}

      query["parents.#{item_id}.order"] = {$gte: 0}

      if item_id == "0" and (project_id = item_doc?.project_id)?
        check project_id, String

        query["project_id"] = project_id

      return @find(query).count()

    @items_collection.incrementChildsOrderGte = (parent_id, min_order_to_inc, item_doc=null) ->
      # note that this function replace grid-data-com-server.coffee's incrementChildsOrderGte

      query = {}

      if (project_id = item_doc?.project_id)?
        check project_id, String

        query["project_id"] = project_id

      query["parents.#{parent_id}.order"] = {$gte: min_order_to_inc}
      
      update_op = {$inc: {}}
      update_op["$inc"]["parents.#{parent_id}.order"] = 1

      update_op["$currentDate"] = {_raw_updated_date: true}

      performIncrementChildsOrderGte = (cb) =>
        # Use rawCollection here, skip collection2/hooks
        APP.justdo_analytics.logMongoRawConnectionOp(@_name, "update", update_op, {multi: true})
        return @rawCollection().update query, update_op, {multi: true}, Meteor.bindEnvironment (err) ->
          if err?
            console.error(err)

            cb(err)

            return

          cb()

          return

      Meteor.wrapAsync(performIncrementChildsOrderGte)()

      return

    @items_collection.getChildreOfOrder = (item_id, order, item_doc=null) ->
      query = {}
      query["parents.#{item_id}.order"] = order

      if item_id == "0" and (project_id = item_doc?.project_id)?
        check project_id, String

        query["project_id"] = project_id

      return @findOne(query)