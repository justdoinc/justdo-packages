_.extend Projects.prototype,
  _setupGridControlMiddlewares: ->
    projects_object = @

    requireProjectIdProvided = (item_doc) ->
      if not (project_id = item_doc?.project_id)? or not _.isString(project_id) or project_id.trim() == ""
        throw projects_object._error "invalid-argument", "item_doc now must be provided with the project_id field set to a String", {item_doc}

      return project_id

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

    @_grid_data_com.setGridMethodMiddleware "beforeRemoveParent", (path, perform_as, etc) ->
      # IMPORTANT, note that etc.item.parents will not necessarily be synced with the current state of
      # the db. I.e a parent might be removed already. That will happen in the case of bulk remove of more
      # than one parent of the same item.
      
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

    @_grid_data_com.setGridMethodMiddleware "beforeMovePath", (path, perform_as, etc) ->
      for update_op_field_name in ["remove_current_parent_update_op", "set_new_parent_update_op"]
        if (update_op = etc[update_op_field_name])?
          Meteor._ensure update_op, "$set"
          update_op.$set.updated_by = perform_as

      return true

    # Counting - is expensive, we want to get a feel of the amount of documents in the
    # result set to decide on the best pagination strategy - fast.
    #
    # If we were to count 1m tasks of a user we might have to wait more than a second (!)
    # we want no more than few miliseconds of wait.
    #
    # If the result set is equal to the limit - we assume the user has access to most
    # of the tasks in the project (this only a heuristic based on a gut feeling...).
    #
    # If the result is less than 
    minimum_count_limit = 1000 # Takes single digit miliseconds
    max_documents_to_count_factor = 0.01 # For a JustDo with 1m tasks we'll count up to 10k tasks for example, that takes ~25ms to count on my machine.

    max_page_size = Projects.max_page_size # Above this number we run the risk that caching won't be used by browsers for the http results. For 1m tasks it means 40 pages.

    count_rounding_factor = Projects.page_count_rounding_factor
                                 # To ensure the cached http requests for pages are used, we want to avoid
                                 # changes in pages count/size for minor changes in items count.
                                 #
                                 # To do that we use count_rounding_factor, we will round the assumed items
                                 # count to the closest count_rounding_factor for example:
                                 #
                                 # If we'll find 1004 items, we will consider such result as if there are
                                 # only 1000 items, when deciding how to paginate (reminder: the last page
                                 # isn't bounded for the max seq id, to have another page in this example
                                 # just because of 4 extra task would be redundant).

    min_page_size = count_rounding_factor # The rounding factor is ideal for setting a simple minimum page size

    max_pages_as_long_as_max_page_size_didnt_reach = 5
    # With this we can draw the significant points for the pagination decision:
    #
    # assumed_count up to min_page_size:
    #   no pagination
    #
    # min_page_size < assumed_count <= min_page_size * max_pages_as_long_as_max_page_size_didnt_reach
    #   (assumed_count / min_page_size) pages, min_page_size per page
    #
    # As long as (assumed_count / max_pages_as_long_as_max_page_size_didnt_reach) <= max_page_size
    #   max_pages_as_long_as_max_page_size_didnt_reach, (assumed_count / max_pages_as_long_as_max_page_size_didnt_reach) per page
    #
    # Beyond that:
    #   assumed_count / max_page_size, max_page_size per page.
    assumedPagesToPaginationRecommendation = (presumed_total_count, max_count_requested, counted_items) =>
      # Come up with recommendation for how to paginate under: pagination_rec
      #
      # Structure:
      #
      # {
      #   use: true/false # if false - recommendation is to avoid pagination , no need for it, the other fields won't be added to the object in this case
      #   total_pages: X
      #   max_page_size: Y
      # }

      if max_count_requested > counted_items
        # If max limit requested > count - we got an exact number of tasks in this count.

        assumed_items_count = counted_items
      else
        assumed_items_count = presumed_total_count

      rounded_assumed_items_count = Math.round(assumed_items_count / count_rounding_factor) * count_rounding_factor

      pages_when_using_min_page_size = Math.ceil(rounded_assumed_items_count / min_page_size)

      if pages_when_using_min_page_size <= 1
        return {use: false}
      if pages_when_using_min_page_size <= max_pages_as_long_as_max_page_size_didnt_reach
        return {use: true, total_pages: pages_when_using_min_page_size, max_items_per_page: min_page_size}
      if (items_per_page = Math.ceil(rounded_assumed_items_count / max_pages_as_long_as_max_page_size_didnt_reach)) <= max_page_size
        return {use: true, total_pages: max_pages_as_long_as_max_page_size_didnt_reach, max_items_per_page: items_per_page}

      total_pages = Math.ceil(rounded_assumed_items_count / max_page_size)
      return {use: true, total_pages: total_pages, max_items_per_page: max_page_size}

    requestForceCacheRefreshRecommendation = (perform_as, project_id, max_age_in_use_seconds, last_loaded_sync_id) ->
      if JustdoHelpers.getDateTimestamp() - (max_age_in_use_seconds * 1000) > last_loaded_sync_id
        # Cahced init payload is too old anyways, can recommend to force_refresh, but it
        # is basically meaningless, since the browser should have done that anyways.
        return {force_cahce_refresh: true}

      # The cache (that might exist and might also not) is not too old
      # We'll count how many items changed for the user since, if more than
      # Projects.max_items_updates_to_force_cahce_refresh updated we'll recommend
      # forcing refresh.

      query = 
        project_id: project_id,
        _raw_updated_date: {$gte: new Date(last_loaded_sync_id)}
        $or: [
          {users: perform_as}
          {_raw_removed_users: perform_as}
        ]
      {err, count} = JustdoHelpers.pseudoBlockingRawCollectionCountInsideFiber(APP.collections.Tasks, query, {limit: Projects.max_items_updates_to_force_cahce_refresh})

      if err?
        console.trace()
        console.error err

        return # return nothing, recommend nothing

      if count == Projects.max_items_updates_to_force_cahce_refresh
        return {force_cahce_refresh: true}

      return

    @_grid_data_com.setGridMethodMiddleware "beforeCountItems", (perform_as, etc) =>
      if not (project_id = etc.method_options.project_id)? or not _.isString(project_id)
        throw @_error "invalid-options", "countItems: options.project_id must be a String"

        return

      project_doc = @requireUserIsMemberOfProject project_id, perform_as

      max_seq_id = project_doc.lastTaskSeqId

      etc.result.max_seq_id = project_doc.lastTaskSeqId

      etc.query.project_id = project_doc._id

      count_limit = Math.floor(Math.max(minimum_count_limit, max_seq_id * max_documents_to_count_factor))
      etc.count_options.limit = count_limit

      etc.result.count_limit = count_limit

      return true

    @_grid_data_com.setGridMethodMiddleware "afterCountItems", (perform_as, etc) =>
      _.extend etc.result, assumedPagesToPaginationRecommendation(etc.result.max_seq_id, etc.result.count_limit, etc.result.count)

      if (project_id = etc.method_options?.project_id)? and (max_age_in_use_seconds = etc.method_options?.max_age_in_use_seconds)? and (last_loaded_sync_id = etc.method_options?.last_loaded_sync_id)?
        if _.isNumber(max_age_in_use_seconds) and  _.isNumber(last_loaded_sync_id)
          _.extend etc.result, requestForceCacheRefreshRecommendation(perform_as, project_id, max_age_in_use_seconds, last_loaded_sync_id)

      return true

    # XXX All the following replacements for the original methods
    # created by grid-data-com are due to the lack of project
    # awarness in the grid-data-com level, once we'll introduce it
    # the following will be redundant. 
    @items_collection.getNewChildOrder = (parent_id, new_child_fields=null, options) ->
      # XXX read getNewChildOrder documentation at
      # grid-data-com-server.coffee

      project_id = requireProjectIdProvided(new_child_fields)

      query =
        "project_id": project_id
        "parents2.parent": parent_id

      sort =
        "parents.#{parent_id}.order": -1
      
      current_max_order_child = @findOne(query, {sort: sort})

      new_order = (current_max_order_child?.parents?[parent_id]?.order + 1) or 0

      return new_order

    @items_collection.getChildrenCount = (item_id, item_doc=null, query_options) ->
      if not item_doc?
        item_doc = @findOne(item_id, {project_id: 1})

      project_id = requireProjectIdProvided(item_doc)

      query =
        "project_id": project_id
        "parents2.parent": item_id

      query_options = _.extend {}, query_options, {fields: {_id: 1}}

      return @find(query, query_options).count()

    @items_collection.incrementChildsOrderGte = (parent_id, min_order_to_inc, item_doc=null, inc_count=1) ->
      # note that this function replace grid-data-com-server.coffee's incrementChildsOrderGte
      check parent_id, String
      check min_order_to_inc, Number
      check inc_count, Number

      project_id = requireProjectIdProvided(item_doc)

      query =
        project_id: project_id
        parents2:
          # During conversion period, parents2 may not exist for all tasks documents
          # We opportunistically attempt to update parents2 in this stage.
          $elemMatch:
            parent: parent_id
            order:
              $gte: min_order_to_inc

      update_op =
        $inc:
          "parents2.$.order": inc_count
          "parents.#{parent_id}.order": inc_count
        $currentDate:
          _raw_updated_date: true

      performIncrementChildsOrderGte = (cb) =>
        APP.justdo_analytics.logMongoRawConnectionOp(@_name, "update", query, update_op, {multi: true})
        @rawCollection().update query, update_op, {multi: true}, (err) ->
          if err?
            console.error(err)

            cb(err)

            return

          cb()

          return

        return

      Meteor.wrapAsync(performIncrementChildsOrderGte)()

      return

    @items_collection.getChildreOfOrder = (item_id, order, item_doc=null) ->
      project_id = requireProjectIdProvided(item_doc)

      query =
        "project_id": project_id
        "parents2":
          $elemMatch:
            parent: item_id
            order: order

      return @findOne(query)
