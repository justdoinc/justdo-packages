
_.extend JustdoChecklist.prototype,

  all_checklists: new Set

  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    # maintain a cashed list of tasks that are marked as checklists for all projects
    # note - in this code, I intentionally ignore the specific project the user is on. since it's all client side,
    # it's fine and more efficient to monitor all the checklists that the user is aware of.
    @checlists_observer = APP.collections.Tasks.find({'p:checklist:is_checklist':true}).observeChanges
      added: (id, doc) =>
        @all_checklists.add id
        @refreshChangedItemDescendants id
        return

      # changed is n/a

      removed: (id) =>
        @all_checklists.delete id
        @refreshChangedItemDescendants id
        return

    return


  refreshChangedItemDescendants: (changed_item) ->

    gcm = APP.modules.project_page.grid_control_mux.get()
    tabs = gcm.getAllTabs()
    for tab_id, tab_state of tabs
      if tab_state.state == "ready"
        if (gc = tabs[tab_id].grid_control)?
          active_row = -1
          if(active_cell = gc._grid.getActiveCell())?
            if (gc._grid.getEditorLock().isActive())
              active_row = active_cell.row
          rerender = false
          for item, row in gc._grid_data.grid_tree
            if item[2].indexOf(changed_item) > -1 and row != active_row
              gc._grid.invalidateRow(row)
              rerender = true
          if rerender
            gc._grid.render()

    return

  htmlMark: (task,path) ->
    ancenstor_is_checklist = path.split('/').find (id)->
      if APP.justdo_checklist.all_checklists.has(id)
        return true
      return false

    if !ancenstor_is_checklist
      return ""

    f="\"Meteor.call('flipCheckItemSwitch', '#{task._id}')\""

    # if checked
    if task['p:checklist:is_checked']
      return "<i class='fa fa-check slick-prevent-edit' aria-hidden='true' style='color:green' onclick=#{f}></i>"

    # if implied as checked
    if task['p:checklist:total_count'] and (task['p:checklist:total_count'] == task['p:checklist:checked_count'])
      return "<i class='fa fa-check-square slick-prevent-edit' aria-hidden='true' style='color:green' onclick=#{f}></i>"

    # if implied as partially checked
    if (task['p:checklist:checked_count'] and task['p:checklist:checked_count'] > 0) or task['p:checklist:has_partial'] == true
      return "<i class='fa fa-check-square slick-prevent-edit p-jd-checklist' aria-hidden='true' style='color:silver' onclick=#{f}></i>"

    # else empty square
    return "<i class='fa fa-square-o slick-prevent-edit p-jd-checklist' aria-hidden='true' onclick=#{f}></i>"


  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoChecklist.project_custom_feature_id,

      installer: =>
        console.log "HERE INSTALLER"

        return

      destroyer: =>
        console.log "HERE DESTROYER"

        return

    @onDestroy =>
      custom_feature_maintainer.stop()
      @checlists_observer.stop()

      return

    return


