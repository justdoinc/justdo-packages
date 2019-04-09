_.extend JustdoChecklist.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @_checklists_observer = null
    @_all_checklists = {}

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  refreshActiveGcmAllActiveTabsChangedItemDescendants: (changed_item) ->
    gcm = APP.modules.project_page.grid_control_mux.get()

    if not gcm?
      return
    
    tabs = gcm.getAllTabs()
    for tab_id, tab_state of tabs
      if tab_state.state == "ready"
        if (gc = tabs[tab_id].grid_control)?
          active_row = -1
          if (active_cell = gc._grid.getActiveCell())?
            if gc._grid.getEditorLock().isActive()
              active_row = active_cell.row

          rerender = false
          for item, row in gc._grid_data.grid_tree
            if item[2].indexOf(changed_item) > -1 and row != active_row
              gc._grid.invalidateRow(row)
              rerender = true

          if rerender
            gc._grid.render()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoChecklist.project_custom_feature_id,

      installer: =>
        # maintain a cashed list of tasks that are marked as checklists for all projects
        # note - in this code, I intentionally ignore the specific project the user is on. since it's all client side,
        # it's fine and more efficient to monitor all the checklists that the user is aware of.
        @_checklists_observer = @tasks_collection.find({"p:checklist:is_checklist": true, project_id: APP.modules.project_page.curProj()?.id}, {fields: {_id: 1}}).observeChanges
          added: (id, doc) =>
            @_all_checklists[id] = true

            @refreshActiveGcmAllActiveTabsChangedItemDescendants id

            return

          removed: (id) =>
            delete @_all_checklists[id]

            @refreshActiveGcmAllActiveTabsChangedItemDescendants id

            return

        return

      destroyer: =>
        @_checklists_observer?.stop()
        @_all_checklists = {}

        return

    return
