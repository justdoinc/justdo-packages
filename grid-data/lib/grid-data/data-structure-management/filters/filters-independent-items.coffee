helpers = share.helpers

_.extend GridData.prototype,
  clearFilterIndependentItems: ->
    @filter_independent_items.set(null)

  addFilterIndependentItems: ->
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      independent_items = []
    else
      # Copy, so reactive dict will be able to see difference
      independent_items = independent_items.slice()

    independent_items = independent_items.concat(_.toArray(arguments))

    @filter_independent_items.set _.uniq(independent_items)

  removeFilterIndependentItems: ->
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      return

    @filter_independent_items.set _.difference(independent_items, _.toArray(arguments))