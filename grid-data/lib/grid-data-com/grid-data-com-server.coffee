Fiber = Npm.require "fibers"

helpers = share.helpers

# The communication layer between the server and the client
GridDataCom = (collection, private_data_collection) ->
  EventEmitter.call this
  JustdoHelpers.setupHandlersRegistry(@)

  @collection = collection

  @private_data_collection = private_data_collection

  @initDefaultCollectionMethods()

  @initDefaultGridMethods()

  @initDefaultIndeices()

  @setupGridCollectionHooks()
  @setupGridCollectionWritesProxies()
  @setupGridPrivateDataCollectionHooks()

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

  methods_definitions:
    # We need to know the perform_as argument position of each api method
    # we proxy through a Meteor Method, in order to force the perform_as
    # arg to the user doing the action.
    # If the position of the argument changes in any of the following api
    # methods below it *must* be updated here, otherwise it's a serious
    # security issue.
    addChild:
      perform_as_arg_position: 2
      unblock_method_invocation: false
    addSibling:
      perform_as_arg_position: 2
      unblock_method_invocation: false
    removeParent:
      perform_as_arg_position: 1
      unblock_method_invocation: false
    addParent:
      perform_as_arg_position: 2
      unblock_method_invocation: false
    updateItem:
      # Note, we aren't yet allow the client to call this Meteor Method
      # as we don't consider it secure enough (update_op validations required).
      perform_as_arg_position: 2 
      unblock_method_invocation: false
    movePath:
      perform_as_arg_position: 2
      unblock_method_invocation: false
    sortChildren:
      perform_as_arg_position: 3
      unblock_method_invocation: false
    bulkUpdate:
      perform_as_arg_position: 2
      unblock_method_invocation: false
    getContexts:
      perform_as_arg_position: 2
      unblock_method_invocation: false

  disabled_methods: ["updateItem"] 

  setupGridPublication: (options = {}) ->
    self = this

    default_options =
      unmerged_pub: false
      unmergedPublication_options: null
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
      # Should return an array of the form
      # [query, condition, pub_customization_safe_options, pub_customization_restricted_options]
      # with the new query and condition to use for the provided cursor, and potentially (can be null/undefined) safe_options
      # and restricted_options that will be passed to customizedCursorPublish.
      #
      # If returns false, we regard it as a blocked request for subscription,
      # we will return an empty publication.
      #
      # `this` context is same as the Meteor.publish's
      #
      # Example:
      # middleware: (collection, private_data_collection, options, sub_args, query, private_data_query, projection, private_data_projection) -> [query, projection]
      #
      #
      # IMPORTANT! at the moment, for cases where middleware_incharge is set to false, we aren't
      # executing the private_data_query, which means that, while we provide it, modifying it will
      # have no effect at all!
      #
      # If middleware_incharge option is true, we will just return the returned value
      # of the middleware to the main publication, which means that the middleware
      # is in charge of the final cursor provided to the subscription (if you chose to
      # return one...)
      #
      # Example:
      # middleware: (collection, private_data_collection, options, sub_args, query, private_data_query, projection, private_data_projection) -> collection.find query, projection

    if options.unmerged_pub and not options.unmergedPublication_options?
      throw @_error "missing-required-option", "For true options.unmerged_pub, you must provide options.unmergedPublication_options"

    options = _.extend default_options, options

    if options.unmerged_pub
      publishMethod = APP.justdo_ddp_extensions.unmergedPublication
      publishMethod_this = APP.justdo_ddp_extensions
    else
      publishMethod = Meteor.publish
      publishMethod_this = Meteor

    args = []

    args.push options.name
    args.push (subscription_options, pub_options) ->
      # `this` is the Publication context, use self for GridData instance 
      if options.require_login
        if not @userId?
          @ready()

          return

      if not pub_options?
        pub_options = {}

      query = {}
      private_data_query =
        user_id: @userId
        _raw_frozen: null # Exclude frozen fields (they are equivalent to removed, just recoverable).
      projection = {}
      private_data_projection = {}

      if options.require_login and not options.exposed_to_guests
        query.users = @userId

      if options.require_login and not options.exposed_to_guests
        query.users = @userId

      middleware = options.middleware
      pub_customization_safe_options = undefined
      pub_customization_restricted_options = undefined
      if middleware?
        if options.middleware_incharge
          return middleware.call @, self.collection, self.private_data_collection, options, _.toArray(arguments), query, private_data_query, projection, private_data_projection
        else
          result = middleware.call @, self.collection, self.private_data_collection, options, _.toArray(arguments), query, private_data_query, projection, private_data_projection

          if not result
            @ready()

            return
          else
            [query, projection, pub_customization_safe_options, pub_customization_restricted_options] = result

        if _.isObject(pub_customization_safe_options)
          # Since the middleware has access to the pub_options received as an argument
          # we give the its pub_customization_safe_options precdence over the user's
          # pub_options.
          pub_options = _.extend {}, pub_options, pub_customization_safe_options

      cursor = self.collection.find query, projection

      return JustdoHelpers.customizedCursorPublish(@, cursor, pub_options, pub_customization_restricted_options)

    if options.unmerged_pub
      args.push options.unmergedPublication_options

    return publishMethod.apply publishMethod_this, args

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
      isUserBelongToItem: (item, userId) -> userId in item.users

      getItemByPath: (path) -> collection.findOne helpers.getPathItemId path

      getItemByPathIfUserBelong: (path, userId) ->
        item = collection.getItemByPath(path)

        if item? and collection.isUserBelongToItem(item, userId)
          return item
        else
          return null

      getItemById: (item_id) -> collection.findOne item_id

      getItemByIdIfUserBelong: (item_id, userId) ->
        item = collection.getItemById(item_id)

        if item? and collection.isUserBelongToItem(item, userId)
          return item
        else
          return null

      getHasChildren: (item_id, item_doc=null, options) ->
        # Supported options:
        # * user_id (default: undefined) will limit the search only to items to which user_id
        #   has access to

        # item_doc serves the same purpose new_child_fields serves in
        # @getNewChildOrder, read comment there in its entirety
        # including XXX section

        options = options or {}

        query = {}
        query["parents.#{item_id}.order"] = {$gte: 0}

        if (user_id = options.user_id)?
          query.users = user_id

        return collection.findOne(query, {fields: {_id: 1}})?

      getChildrenCount: (item_id, item_doc=null) ->
        # item_doc serves the same purpose new_child_fields serves in
        # @getNewChildOrder, read comment there in its entirety
        # including XXX section
        query = {}
        query["parents.#{item_id}.order"] = {$gte: 0}
        return collection.find(query, {fields: {_id: 1}}).count()

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

        return collection.update query, update_op, {multi: true, bypassCollection2: true}

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


      findSubTree: (item_id, options, perform_as) ->
        # Finds all tasks of the sub-tree whose root is item_id.
        #
        # Returns an object with the found items ids in the form:
        #
        # {
        #   found_item_id: doc
        # }
        #
        # (item id itself will be part of the returned doc).
        #
        # doc will include a pseudo field called: _children that will be an array with all the
        # children id of doc.
        #
        # options:
        #
        #   fields: a mongo style positive fields projection (negative isn't supported!)
        #   max_level: if undefined we will go as deep as the sub-tree goes, otherwise we won't traverse
        #             items in levels higher than the level specified (0 is the root level).
        #   max_items: if undefined we will return as many items as we find for the sub-tree, otherwise
        #              we will return up to max_items items. (Since we are running in batches, the actual
        #              number can be slightly higher).
        #
        # perform_as:
        #
        #   If is set, we limit the sub-tree to items that perform_as is their user only.
        #
        # Notes:
        #
        #   * If item_id doesn't exist -> returns empty object
        #   * We impose hard limit of 20 to max_level
        #   * We impose hard limit of 1000 to max_items

        mandatory_fields = {_id: 1, parents: 1}
        if not (fields = options?.fields)?
          fields = {}
        fields = _.extend {}, fields, mandatory_fields

        max_level_hard_limit = 20
        if not (max_level = options?.max_level)? or not _.isNumber(max_level) or max_level > max_level_hard_limit or max_level < 0
          max_level = max_level_hard_limit

        max_items_hard_limit = 1000
        if not (max_items = options?.max_items)? or not _.isNumber max_items or max_items > max_items_hard_limit or max_items < 1
          max_items = max_items_hard_limit

        ret = {}
        items_found = 0
        addItemToRet = (doc) ->
          items_found += 1

          ret[doc._id] = doc

          doc._children = []

          for parent_id, p_def of doc.parents
            ret[parent_id]?._children.push doc._id

          return

        root_query = {_id: item_id}
        if perform_as?
          root_query.users = perform_as
        addItemToRet(@findOne(root_query, {fields: fields}))
        if items_found == max_items or _.isEmpty ret
          return ret

        last_level_items = [item_id]
        for level in [0...max_level]
          query = {}

          if perform_as?
            query.users = perform_as

          query.$or = _.map last_level_items, (item_id) -> {"parents.#{item_id}": {$exists: true}}

          last_level_items = []
          @find(query, {fields: fields}).forEach (doc) ->
            last_level_items.push doc._id

            addItemToRet(doc)

          # Note, we can't break the forEach loop above, therefore, the actual amount of items
          # returned might be slightly bigger.
          if items_found > max_items
            return ret

          if _.isEmpty last_level_items
            break

        return ret

  setGridMethodMiddleware: (method_name, middleware) ->
    # Assigned middlewares are called just before the default execution of the method
    # with the the GridDataCom object as their `this`, and with some additional arguments.
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
    # Notes:
    # * for all the grid methods the `this` var will be the GridDataCom object.
    # * In all the grid methods, the perform_as arg is the user that should be regarded
    # for security, access control and logging purposes as the one performing the action.
    #
    # addChild: (path, new_item_fields, perform_as)
    # path is the path to which the new item is about to be added.
    #
    # new_item_fields reference to the original object and is not a copy for the purpose of
    # allowing it to be customized by the middlewares.
    #
    # addSibling: (path, new_item_fields, perform_as)
    # path is the path to which the new item is going to be sibling of.
    #
    # new_item_fields reference to the original object and is not a copy for the purpose of
    # allowing it to be customized by the middlewares.
    #
    # removeParent: (path, perform_as, etc)
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
    # addParent: (perform_as, etc)
    #
    # etc is an object that contains the following keys:
    #
    #   etc.new_parent is a *copy* of the computed new_parent target based on
    #   the argument provided and defaults applied. Do not change this object. Changing it
    #   will have no effect on addParent execution and might result in bugs in following
    #   middlewares.
    #
    #   etc.item is the document of the item we're about to add to a new
    #   parent -> do not change this object without cloning it, it is passed
    #   by reference and will affect othe middlewares.
    #
    #   etc.new_parent_item is the document of the new parent. passed by reference.
    #
    #   etc.update_op, reference to the original object and is not a copy for the purpose of
    #   allowing it to be customized by the middlewares.
    #
    # updateItem: (perform_as, etc)
    #
    # etc is an object that contains the following keys:
    #
    #   etc.item is the document we're about to update -> do not change this object without
    #   cloning it, it is passed by reference and will affect othe middlewares.
    #   etc.update_op, reference to the original object and is not a copy for the purpose of
    #   allowing it to be customized by the middlewares.
    #
    # movePath: (path, perform_as, etc)
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
    #   etc.remove_current_parent_update_op, reference to the original object and is not a copy for the purpose of
    #   allowing it to be customized by the middlewares.
    #
    #   etc.set_new_parent_update_op, reference to the original object and is not a copy for the purpose of
    #   allowing it to be customized by the middlewares.
    #
    # sortChildren: ()
    # middlewares on sortChildren won't be called and has no effect on execution
    #
    # bulkUpdate: (selector, modifier, perform_as)
    # selector is a reference to the selector we are about to use in the update
    # operation. Isn't a copy for the purpose of allowing it to be customized by
    # the middlewares.
    # Note: users selector isn't editable and will be overriden to the original if changed.
    #
    # modifier is a reference to the modifier we are about to use in the update
    # operation. Isn't a copy for the purpose of allowing it to be customized by
    # the middlewares.
    #

    if method_name not of @methods_definitions
      throw @_error "unknown-method-name", "Unknown method name: #{method_name}, use one of: #{_.keys(@methods_definitions).join(", ")}"

    if not _.isFunction middleware
      throw @_error "wrong-type", "Middleware has to be a function"

    if not @_grid_methods_middlewares[method_name]?
      @_grid_methods_middlewares[method_name] = []

    @_grid_methods_middlewares[method_name].push middleware

  _getGridMethodMiddleware: (method_name) -> @_grid_methods_middlewares[method_name] or []

  _runGridMethodMiddlewares: (method_name, ...method_args) ->
    # _runGridMethodMiddlewares: (method_name, middleware_arg1, middleware_arg2, ...)
    # Method this should be the this variable of the calling grid method. Limitation of the js
    # lang don't allow this API to be nicer.
    # Important, you can rely only on @userId inside this

    for middleware in @_getGridMethodMiddleware(method_name)
      message = middleware.apply @, method_args

      if message == true
        # no issue continue to run the next middleware
        continue
      if message instanceof Error
        throw message
      throw @_error "grid-method-blocked", message

  initDefaultGridMethods: ->
    self = @

    # Methods to API proxy

    methods = {}
    for method_name, method_def of self.methods_definitions
      if method_name in self.disabled_methods
        continue
      
      do (method_name, method_def) ->
        methods[helpers.getCollectionMethodName(self.collection, method_name)] = (args...) ->
          if not @userId?
            throw self._error "login-required"

          # We force the perform_as argument of the API method to be the
          # current @userId (not doing that will allow the user to disguise
          # as another user)
          if args[method_def.perform_as_arg_position]?
            throw self._error "operation-blocked", "You are not allowed to set the argument in the #{method_def.perform_as_arg_position} position of this Meteor Method"
          args[method_def.perform_as_arg_position] = @userId

          if method_def.unblock_method_invocation
            @unblock()

          return self[method_name].apply(self, args)

    Meteor.methods methods

    return

# Add a shortcut to helpers
GridDataCom.helpers = helpers