APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page
  curProj = project_page_module.helpers.curProj

  gridControl = -> project_page_module.gridControl(false) # false means we'll get the gridControl even if it isn't init

  project_page_module.setNullaryOperation "addSubTask",
    human_description: "New Child Task"
    human_description_i18n: "new_child_task_label"
    keyboard_shortcut: "alt+shift+enter"
    alternative_shortcuts: ["alt+\\"]
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#corner-down-#{APP.justdo_i18n.getRtlAwareDirection "right"}"/></svg>"""
    op: ->
      gc = gridControl()

      gc.saveAndExitActiveEditor()

      gc.addSubItem({project_id: curProj().id})

    prereq: -> gridControl().addSubItem.prereq()

  isActiveItemSectionHeaderUnderMainTab = ->
    # Returns true only if all the following are true:
    # * User is under the main tab
    # * There is an active item
    # * Active item is a section header

    gcm = project_page_module.grid_control_mux.get()
    if not gcm?
      APP.logger.debug "GCM is not ready yet"

      return false

    active_tab = gcm.getActiveTab()
    if active_tab.tab_id != "main"
      return false

    gc = gcm.getActiveGridControl(true)

    if not gc?
      APP.logger.debug "Tab's grid control is not ready"

      return false

    gd = gc._grid_data

    current_row = gc.getCurrentRow()
    if current_row? and gd.getItemType(current_row) == "section-item"
      return true

    return false

  project_page_module.setNullaryOperation "addSiblingTask",
    human_description: "New Sibling Task"
    human_description_i18n: "new_sibling_task_label"
    keyboard_shortcut: "alt+enter"
    alternative_shortcuts: ["alt+plus"]
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#plus"/></svg>"""
    op: ->
      gc = gridControl()

      gc.saveAndExitActiveEditor()

      new_task_custom_fields = {project_id: curProj().id}

      # If we are under the main tab and the active item
      # is section header, simply add another item to the
      # root
      if isActiveItemSectionHeaderUnderMainTab()
        gc.addItem("/", new_task_custom_fields, true)

        return

      gridControl().addSiblingItem(new_task_custom_fields)

    prereq: ->
      if not gridControl().isMultiSelectMode() and isActiveItemSectionHeaderUnderMainTab()
        return {} # add new task is allowed in such a case, otherwise, if someone sees only the Shared With Me he won't be able to add tasks to the root once it is activated

      return gridControl().addSiblingItem.prereq()

  project_page_module.setNullaryOperation "removeTask",
    human_description: "Remove Task"
    human_description_i18n: "remove_task_label"
    keyboard_shortcut: "alt+-"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#trash"/></svg>"""
    op: ->
      gc = gridControl()

      current_task_obj = gc.getCurrentPathObj()

      performAction = -> gridControl().removeActivePath()

      # If the task has no title and subject, created by me in the last 5 mins -
      # don't ask for confirmation before remove
      if (not current_task_obj.title? or current_task_obj.title == "") and
         (not current_task_obj.status? or current_task_obj.status == "") and
         (not current_task_obj.createdAt? or (current_task_obj.createdAt) > new Date(TimeSync.getServerTime(null) - (5 * 60 * 1000)))
        performAction()
      else
        if not gc.isMultiSelectMode()
          message = """<div class="modal-alert-message">Are you sure you want to remove task <i>##{current_task_obj.seqId}: #{JustdoHelpers.xssGuard(JustdoHelpers.ellipsis(current_task_obj.title, 80))}</i>?</div>"""
        else
          message = """<div class="modal-alert-message">Are you sure you want to remove these tasks?</div>"""
        bootbox.confirm
          className: "bootbox-new-design"
          closeButton: false
          message: message
          callback: (result) =>
            if result
              performAction()

      return

    prereq: -> gridControl().removeActivePath.prereq()

  project_page_module.setNullaryOperation "moveDown",
    human_description: "Move Down"
    human_description_i18n: "move_down_label"
    keyboard_shortcut: "alt+down"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#arrow-down"/></svg>"""
    op: -> gridControl().moveActivePathDown()
    prereq: -> gridControl().moveActivePathDown.prereq()

  project_page_module.setNullaryOperation "moveUp",
    human_description: "Move Up"
    human_description_i18n: "move_up_label"
    keyboard_shortcut: "alt+up"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#arrow-up"/></svg>"""
    op: -> gridControl().moveActivePathUp()
    prereq: -> gridControl().moveActivePathUp.prereq()

  project_page_module.setNullaryOperation "moveLeft",
    human_description: "Outdent"
    human_description_i18n: "move_left_label"
    keyboard_shortcut: "alt+left"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#arrow-#{APP.justdo_i18n.getRtlAwareDirection "left"}"/></svg>"""
    op: -> gridControl().moveActivePathLeft()
    prereq: -> gridControl().moveActivePathLeft.prereq()

  project_page_module.setNullaryOperation "moveRight",
    human_description: "Indent"
    human_description_i18n: "move_right_label"
    keyboard_shortcut: "alt+right"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#arrow-#{APP.justdo_i18n.getRtlAwareDirection "right"}"/></svg>"""
    op: -> gridControl().moveActivePathRight()
    prereq: -> gridControl().moveActivePathRight.prereq()

  project_page_module.setNullaryOperation "sortByPriority",
    human_description: "Sort by priority"
    human_description_i18n: "sort_by_priority_label"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#jd-sort"/></svg>"""
    op: -> gridControl().sortActivePathByPriorityDesc()
    prereq: -> gridControl().sortActivePathByPriorityDesc.prereq()

  project_page_module.setNullaryOperation "zoomIn",
    human_description: "Zoom in"
    human_description_i18n: "zoom_in_label"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#zoom-in"/></svg>"""
    op: ->
      gcm = project_page_module.getCurrentGcm()
      active_item_id = project_page_module.activeItemId()

      tab_id = "sub-tree"

      gcm.activateTabWithSectionsState(tab_id, {global: {"root-item": active_item_id}})

      gcm.setPath([tab_id, "/#{active_item_id}/"])
    prereq: ->
      gc = gridControl()

      return gc._opreqActivePathIsCollectionItem(gc._opreqGridReady())

  project_page_module.setNullaryOperation "addToFavorites",
    human_description: "Add to Favorites"
    human_description_i18n: "add_to_favorites_label"
    op: ->
      active_item_id = project_page_module.activeItemId()

      JD.collections.Tasks.update(active_item_id, {$set: {"priv:favorite": new Date(TimeSync.getServerTime())}})

      return
    prereq: ->
      gc = gridControl()

      return gc._opreqActivePathIsCollectionItem(gc._opreqGridReady())

  project_page_module.setNullaryOperation "removeFromFavorites",
    human_description: "Remove from Favorites"
    human_description_i18n: "remove_from_favorites_label"
    op: ->
      active_item_id = project_page_module.activeItemId()

      JD.collections.Tasks.update(active_item_id, {$set: {"priv:favorite": null}})

      return
    prereq: ->
      gc = gridControl()

      return gc._opreqActivePathIsCollectionItem(gc._opreqGridReady())
