ReactiveItemsList = ->
  @_items = {}

  @_items_dep = new Tracker.Dependency()

  return @

_.extend ReactiveItemsList.prototype,
  getList: ->
    @_items_dep.depend()

    items = _.values @_items
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
    #   position: Optional integer, default 0
    #   data: the value to be returned when calling @getList()
    # }

    default_item_options = {
      listingCondition: -> return true
      position: 0
      data: {}
    }

    item = _.extend default_item_options, item

    @_items[item_id] = item

    @_items_dep.changed()

    return

  unregisterItem: (item_id) ->
    delete @_items[item_id]

    @_items_dep.changed()

    return

JustdoHelpers.ReactiveItemsList = ReactiveItemsList
