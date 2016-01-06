# Note: @ will be assigned as the grid_control object for both op and prereq

callCb = ->
  cb = arguments[0]
  args = _.toArray(arguments).slice(1)

  if cb? and _.isFunction(cb)
    cb.apply(@, args)

_.extend PACK.GridOperations,
  addItem:
    op: (path, fields, add_as_child = false, cb) ->
      if not fields?
        fields = {}

      op = "addSibling"
      if add_as_child
        op = "addChild"

      @_performLockingOperation (releaseOpsLock, timedout) =>
        @_grid_data[op] path, fields, (err, new_item_id, new_item_path) =>
          if err?
            @logger.error "addChild failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          @forceItemsPassCurrentFilter new_item_id

          if add_as_child
            # Mark parent as expanded (in case it isn't yet) before adding the child
            # to the tree - this will allow to show the result in one flush
            # instead of two (one for add, one for expand), and as a result
            # the UX will be much faster and smooth.

            # true means force expansion (path might have no children before flush,
            # so it's required)
            @_grid_data.expandPath path, true

          # Flush to make sure the item is in the tree DOM
          @_grid_data._flush()
          @editPathCell new_item_path, 1

          callCb cb, err, new_item_id, new_item_path

          # Release lock only after activation of new path to
          # avoid any chance of refering to previous path in
          # following operations
          releaseOpsLock()

    prereq: -> @_opreqUnlocked()

  newTopLevelItem:
    op: (fields, cb) -> @addItem "/", fields, true, cb
    prereq: -> @addItem.prereq()

  addSubItem:
    op: (fields, cb) -> @addItem @getActiveCellPath(), fields, true, cb
    prereq: -> @_opreqActivePath(@addItem.prereq())

  addSiblingItem:
    op: (fields, cb) -> @addItem @getActiveCellPath(), fields, false, cb
    prereq: -> @_opreqActivePath(@addItem.prereq())