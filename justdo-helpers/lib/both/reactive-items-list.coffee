setupPlaceholdersReactiveListRegistry = (target_object) ->
  regisrtry = new ReactiveItemsList()

  _.extend target_object,
    getPlaceholderItems: (domain, ignore_listing_condition) ->
      return regisrtry.getList(domain, ignore_listing_condition)

    registerPlaceholderItem: (item_id, item) ->
      return regisrtry.registerItem(item_id, item)

    unregisterPlaceholderItem: (item_id) ->
      return regisrtry.unregisterItem(item_id)

  return

ReactiveItemsList = ->
  @_items = {}

  @_items_dep = new Tracker.Dependency()

  # Global listing conditions are listing conditions that will apply for all items,
  # in addition to their specific listingCondition.
  @_global_listing_conditions_dep = new Tracker.Dependency()
  @_global_listing_conditions = {}

  @_listingConditionCustomArgsGenerator = undefined

  return @

_.extend ReactiveItemsList.prototype,
  registerGlobalListingCondition: (global_listing_condition_id, listing_condition) ->
    @_global_listing_conditions[global_listing_condition_id] = listing_condition
    @_global_listing_conditions_dep.changed()

    return

  unregisterGlobalListingCondition: (global_listing_condition_id) ->
    delete @_global_listing_conditions[global_listing_condition_id]

    @_global_listing_conditions_dep.changed()

    return

  registerListingConditionCustomArgsGenerator: (custom_args_generator) ->
    @_listingConditionCustomArgsGenerator = custom_args_generator

    return

  unregisterListingConditionCustomArgsGenerator: ->
    @_listingConditionCustomArgsGenerator = undefined

    return

  _isPassingSelfAndGlobalListingConditions: (item) ->
    listing_condition_args = [item]
    if _.isFunction @_listingConditionCustomArgsGenerator
      if (custom_args = @_listingConditionCustomArgsGenerator())?
        if not _.isArray(custom_args)
          custom_args = [custom_args]
        listing_condition_args = listing_condition_args.concat(custom_args)

    if (listingCondition = item.listingCondition)? and not listingCondition.apply(@, listing_condition_args)
      return false

    global_listing_conditions = _.values @_global_listing_conditions
    for globalListingCondition in global_listing_conditions
      if not globalListingCondition.apply(@, listing_condition_args)
        return false

    return true

  getList: (domain="default", ignore_listing_condition=false) ->
    @_global_listing_conditions_dep.depend()
    
    @_items_dep.depend()

    items = _.values @_items
    items = _.filter @_items, (item) -> item.domain == domain
    items = _.sortBy items, "position"

    if not ignore_listing_condition
      items = _.filter items, (item) => @_isPassingSelfAndGlobalListingConditions(item)

    items = _.map items, (item) -> _.extend {}, item.data, {id: item._id}

    return items

  getItem: (item_id, ignore_listing_condition=false) ->
    @_items_dep.depend()

    if item_id not of @_items
      return undefined

    item = @_items[item_id]

    if ignore_listing_condition
      return item

    if @_isPassingSelfAndGlobalListingConditions(item)
      return item

    return undefined

  registerItem: (item_id, item) ->
    # item_id, if an item with item_id already exists, it will be replaced.
    #
    # item structure:
    #
    # {
    #   listingCondition: Optional function, can be reactive resource, has to return
    #                      true for the item to be returned by @getList()
    #   domain: allow you to separate the items to different domains, if not set "default"
    #   will be used
    #   position: Optional integer, default 0
    #   data: the value to be returned when calling @getList()
    # }

    default_item_options = {
      listingCondition: -> return true
      domain: "default"
      position: 0
      data: {}
    }

    item = _.extend default_item_options, item

    # We do these setups after the _.extend, to prevent the user from being able to
    # set them in the item object
    item._id = item_id

    @_items[item_id] = item

    @_items_dep.changed()

    return

  unregisterItem: (item_id) ->
    delete @_items[item_id]

    @_items_dep.changed()

    return

  unregisterAllItems: ->
    @_items = {}

    @_items_dep.changed()

    return

JustdoHelpers.ReactiveItemsList = ReactiveItemsList
JustdoHelpers.setupPlaceholdersReactiveListRegistry = setupPlaceholdersReactiveListRegistry
