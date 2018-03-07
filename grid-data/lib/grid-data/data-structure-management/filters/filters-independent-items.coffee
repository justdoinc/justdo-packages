helpers = share.helpers

_.extend GridData.prototype,
  clearFilterIndependentItems: ->
    @filter_independent_items.set(null)

  addFilterIndependentItems: ->
    # The independent items to add should be provided as arguments to this functions
    # addFilterIndependentItems(item_id_1, item_id_2, ..., onReady)
    #
    # If last argument is a function it is parsed as an onReady
    #
    # If, *and only if* an onReady callback is provided, we will try to bring the effect of
    # the request to the grid by calling Tracker.flush() before calling onReady.
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      independent_items = []
    else
      # Copy, so reactive dict will be able to see difference
      independent_items = independent_items.slice()

    new_independent_items = _.toArray(arguments)

    if _.isFunction(_.last(new_independent_items))
      onReady = new_independent_items.pop()

    independent_items = independent_items.concat(new_independent_items)

    @filter_independent_items.set _.uniq(independent_items)

    if onReady?
      if not Tracker.currentComputation? and not Tracker.inFlush()
        Tracker.flush()

        onReady()
      else
        Meteor.defer ->
          try
            Tracker.flush()
          catch e
            # Don't know if we'll ever get here, just to be on the safe side Daniel C.
            true

          onReady()

    return

  removeFilterIndependentItems: ->
    independent_items = Tracker.nonreactive => @filter_independent_items.get()

    if not _.isArray independent_items
      return

    @filter_independent_items.set _.difference(independent_items, _.toArray(arguments))