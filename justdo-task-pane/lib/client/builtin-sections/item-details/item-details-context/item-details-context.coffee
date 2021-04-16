# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  current_dragula = null

  _ = lodash

  isDroppableHandle = (el) ->
    $el = $(el)

    gc = module.gridControl()

    if not $el.hasClass("slick-row")
      return

    {row} = gc._grid.getCellFromEvent({target: $el.find(".slick-cell").get(0)}) # fake event to use getCellFromEvent

    if gc._grid_data.getItemIsCollectionItem(row)
      return true

  getAllActiveItemPaths = ->
    gcm = module.getCurrentGcm()

    gc = gcm?.getAllTabs()?.main?.grid_control
    if not (gd = gc?._grid_data)?
      APP.logger.debug "Context: waiting for grid control to become ready"

      return false

    return gd.getAllCollectionItemIdPaths(module.activeItemId())

  activeItemPathsCount = ->
    return getAllActiveItemPaths()?.length or 0

  showCollapsed = (tpl) ->
    paths_count = activeItemPathsCount()

    return tpl.show_collapsed_rv.get() and paths_count > 1

  getSelectedObjectPaths = ->
    if not (id = module.activeItemObj({_id: 1})?._id)?
      return []

    gcm = module.getCurrentGcm()
    gc = gcm?.getAllTabs()?.main?.grid_control
    if not (gd = gc?._grid_data)?
      return []

    active_item_path = module.activeItemPath()
    paths = gd.getAllCollectionItemIdPaths(id)
    if not paths?
      # paths might not always be ready, in such case
      # just return empty array, reactivity will fix
      # the issue as soon as paths are ready
      return []

    # If the active item path is in paths show it first
    # Active item might not be in paths in views where we are not
    # using the natural tree view, due list for example
    if active_item_path in paths
      _.pull(paths, active_item_path)

      paths.unshift(active_item_path)

    return paths

  Template.task_pane_item_details_context.onCreated ->
    # Whether or not we show the context collapsed is determined by both this reactive var and whether
    # the current task has > 1 parents (for single parent we don't show).

    @show_collapsed_rv = new ReactiveVar true

    # Don't change user selection when changing tasks
    # @autorun =>
    #   @show_collapsed_rv.set true

    #   module.activeItemId() # on changes to the active item, reset the show_collapsed_rv

    #   return

    current_dragula = dragula
      isContainer: (el) ->
        $el = $(el)

        if $el.hasClass("idc-task-context-add-parent-container") or
           $el.hasClass("idc-context-item-moveable") or
           isDroppableHandle(el)
          return true

        return false

      accepts: (el, target, source, sibling) ->
        # Only the droppable handles can accept

        return isDroppableHandle(target)

      moves: (el, source, handle, sibling) ->
        # Droppable handles can't move

        # Allow moving moveable seqIds
        $el = $(el)
        if $el.hasClass("idc-task-seq-id") or $el.hasClass("idc-task-context-add-parent") 
          return true

        return false

      revertOnSpill: true

      noShadow: true

  Template.task_pane_item_details_context.onRendered ->
    gc = grid_data = null
    @autorun ->
      gc = module.gridControl()
      grid_data = gc?._grid_data

      return

    addNewParent = (new_parent_id, cb) ->
      if grid_data?
        gc?.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        current_item_id = module.activeItemId()

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.addParent current_item_id, {parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            cb?(err)
      else
        APP.logger.error "Context: couldn't retrieve grid_data object"

      return

    moveParent = (current_path, new_parent_path, cb) ->
      new_parent_path_array = GridData.helpers.getPathArray(new_parent_path)
      new_parent_id = new_parent_path_array[new_parent_path_array.length - 1]
      current_path_array = GridData.helpers.getPathArray(current_path)
      item_id = current_path_array[current_path_array.length - 1]
      new_path = GridData.helpers.joinPathArray(new_parent_path_array.concat(item_id))

      if grid_data?
        gc?.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.movePath current_path ,{parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            if module.activeItemPath() == current_path
              # If moving current item, activate new path
              grid_data._flushAndRebuild()

              gc.activatePath new_path

            cb?(err)
      else
        APP.logger.error "Context: couldn't retrieve grid_data object"

      return

    commonMethodsHandler = (err) =>
      if err?
        APP.logger.error err

      return

    current_dragula.on "drop", (el, target, source, sibling) ->
      index = $(target).index()

      task = grid_data.grid_tree[index]

      if (new_parent_id = task[0]._id)?
        if $(source).hasClass("idc-task-context-add-parent-container")
          addNewParent(new_parent_id, commonMethodsHandler)

        if $(source).hasClass("idc-context-item")
          new_parent_path = task[2]

          moveParent($(source).attr("path"), new_parent_path, commonMethodsHandler)

      @cancel(true)

      return

  Template.task_pane_item_details_context.helpers
    selectedObjectPaths: ->
      return getSelectedObjectPaths()

    showCollapsed: ->
      tpl = Template.instance()

      return showCollapsed(tpl)

    hasMoreThanOnePaths: ->
      return activeItemPathsCount() > 1

    sectionHeight: ->
      tpl = Template.instance()

      gcm = module.getCurrentGcm()

      if showCollapsed(tpl)
        # get the first path, that's the path we want to show in-full without the need to collapse
        first_path_in_context = getSelectedObjectPaths()[0]

        tasks_count = GridData.helpers.getPathLevel(first_path_in_context) + 1

        section_header_height = 33
        task_height = 21
        task_bottom_margin = 7
        last_task_bottom_margin = 0
        show_all_button_height = 27
        show_all_button_top_padding = 33
        height_to_hint_about_next_context_existence = 10

        context_box_vertical_padding_and_borders = (8 + 1) * 2
        context_box_bottom_margin = 8

        height = ((tasks_count - 1) * (task_height + task_bottom_margin)) + # all but last task
          context_box_vertical_padding_and_borders +
          context_box_bottom_margin +
          section_header_height +
          show_all_button_height +
          show_all_button_top_padding +
          height_to_hint_about_next_context_existence

        if tasks_count > 1
          height += (task_height + last_task_bottom_margin) # last task

        return "#{height}px"
      else
        return "auto"

  Template.task_pane_item_details_context.onDestroyed ->
    current_dragula.destroy()
    current_dragula = null

    return

  Template.task_pane_item_details_context.events
    "click .idc-task-context-delete": ->
      item_path = @valueOf() # valueOf returns the String primitive value attached to this

      if not (gc = module.mainGridControl())?
        APP.logger.warn "Couldn't find the main grid control"

      bootbox.confirm
        message: "<b>Are you sure you want to remove the task from this parent?</b>"
        callback: (result) =>
          if not result
            return

          gc._performLockingOperation (releaseOpsLock, timedout) =>
            gc._grid_data?.removeParent item_path, (err) =>
              releaseOpsLock()

              if err?
                APP.logger.error "Error: #{err}"

              return
              
            return

          return

      return

    "click .idc-expand-collapse-button": (e, tpl) ->
      tpl.show_collapsed_rv.set(not(tpl.show_collapsed_rv.get())) # toggle

      return

  operationsOnParentAllowed = (path) ->
    # Returns true, if operations on the path's direct parent are allowed
    path_array = GridData.helpers.getPathArray(path)

    if path_array.length == 1
      return true # root parent, ops allowed

    # Check whether the direct parent_path of the current path is known to us
    parent_path = path_array[path_array.length - 2]

    parent_is_known = APP.collections.Tasks.findOne(parent_path)?

    return parent_is_known

  Template.task_pane_item_details_context_per_path.helpers
    canDeletePath: ->
      current_path = @valueOf()

      gcm = module.getCurrentGcm()
      gc = gcm?.getAllTabs()?.main?.grid_control
      if not (gd = gc?._grid_data)?
        APP.logger.debug "Context: waiting for grid control to become ready"

        return false

      # We allow removing parents if:
      # * The current item has multiple parents
      #   * and the current item's parent is known to us (not under shared-with-me)
      #
      # Note that since we never allow removing the last parent, we don't need to worry
      # about whether the last item has children or not.

      current_path_array = GridData.helpers.getPathArray(current_path)
      current_item_id = current_path_array[current_path_array.length - 1]
      can_remove = (paths_count = gd.getAllCollectionItemIdPaths(current_item_id)?.length)? and
                    paths_count > 1 and
                    operationsOnParentAllowed(current_path)


      return can_remove

    canMoveCurrentPathItem: ->
      item_in_loop = @

      # An item can be moved if it is the last item and if operations on its parent
      # are allowed
      return item_in_loop.$last and operationsOnParentAllowed(item_in_loop.path)

    allParents: ->
      current_path = @valueOf()

      gcm = module.getCurrentGcm()
      gc = gcm?.getAllTabs()?.main?.grid_control

      if not gc?
        APP.logger.debug "Context: waiting for grid control to become ready"

        return

      all_sub_paths = GridData.helpers.getAllSubPaths(current_path)

      all_sub_paths = _.map all_sub_paths, (path, index) ->
        item_id = GridData.helpers.getPathItemId(path)

        item =
          APP.collections.Tasks.findOne(
            item_id, {fields: {_id: 1, title: 1, status: 1, seqId: 1}})

        ret = {path, index, margin_left: index * 10}

        if item?
          _.extend ret, item
        else if (path_obj = gc.getPathObjNonReactive(path))?
          # Note, we don't use gc.getPathObjNonReactive(path) to get object always since
          # it returns null if the path is in the collapsed tree.
          if (path_obj._type == "section-item")
            _.extend ret, {title: path_obj.title, section_header: true}

        return ret

      return all_sub_paths

  Template.task_pane_item_details_context_per_path.events
    "click .idc-context-item" : (e) ->
      if not APP.modules?.project_page?.gridControl()?.activatePath(@path)
        gcm = module.getCurrentGcm()
        gcm.activateTab("main")
        gc = gcm?.getAllTabs()?.main?.grid_control
        gc.activatePath(@path)