setupPlaceholdersReactiveListRegistry = (target_object) ->
  regisrtry = new ReactiveItemsList()

  _.extend target_object,
    getPlaceholderItems: (domain) ->
      return regisrtry.getList(domain)

    registerPlaceholderItem: (item_id, item) ->
      return regisrtry.registerItem(item_id, item)

    unregisterPlaceholderItem: (item_id) ->
      return regisrtry.unregisterItem(item_id)

  return

ReactiveItemsList = ->
  @_items = {}

  @_items_dep = new Tracker.Dependency()

  return @

_.extend ReactiveItemsList.prototype,
  getList: (domain="default") ->
    @_items_dep.depend()

    items = _.values @_items
    items = _.filter @_items, (item) -> item.domain == domain
    items = _.sortBy items, "position"

    items = _.filter items, (item) ->
      if not (listingCondition = item.listingCondition)?
        return true
      else
        return listingCondition()

    items = _.map items, (item) -> item.data

    return items

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

JustdoHelpers.ReactiveItemsList = ReactiveItemsList
JustdoHelpers.setupPlaceholdersReactiveListRegistry = setupPlaceholdersReactiveListRegistry
