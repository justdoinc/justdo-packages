APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  gridControl = -> module.gridControl(false) # false means we'll get the gridControl even if it isn't init

  module.setNullaryOperation "addSubTask", 
    human_description: "New Child Task"
    keyboard_shortcut: "alt+shift+enter"
    alternative_shortcuts: ["alt+\\"]
    template:
      font_awesome_icon: "level-down"
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

    gcm = module.grid_control_mux.get()
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

  module.setNullaryOperation "addSiblingTask", 
    human_description: "New Task"
    keyboard_shortcut: "alt+enter"
    alternative_shortcuts: ["alt+plus"]
    template:
      font_awesome_icon: "plus"
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

      # New task should derive priority from current task,
      # if current task has priority
      current_task_obj = gc.getCurrentPathObj()
      if (priority = current_task_obj?.priority)?
        new_task_custom_fields.priority = priority

      gridControl().addSiblingItem(new_task_custom_fields)

    prereq: ->
      if isActiveItemSectionHeaderUnderMainTab()
        return {} # add new task is allowed in such a case

      return gridControl().addSiblingItem.prereq()

  module.setNullaryOperation "removeTask", 
    human_description: "Remove Task"
    keyboard_shortcut: "alt+-"
    template:
      font_awesome_icon: "trash-o"
    op: ->
      gc = gridControl()

      current_task_obj = gc.getCurrentPathObj()

      performAction = -> gridControl().removeActivePath()

      # If the task has no title and subject, created by me in the last 5 mins -
      # don't ask for confirmation before remove
      if (not current_task_obj.title? or current_task_obj.title == "") and
         (not current_task_obj.status? or current_task_obj.status == "") and
         (not current_task_obj.created_by_user_id? or current_task_obj.created_by_user_id == Meteor.userId()) and
         (not current_task_obj.createdAt? or (current_task_obj.createdAt) > new Date(TimeSync.getServerTime(null) - (5 * 60 * 1000)))
        performAction()
      else
        bootbox.confirm
          className: "bootbox-new-design"
          closeButton: false
          message: """<div class="modal-alert-message">Are you sure you want to remove task <i>##{current_task_obj.seqId}: #{JustdoHelpers.ellipsis(current_task_obj.title, 80)}</i>?</div>"""
          callback: (result) =>
            if result
              performAction()

      return

    prereq: -> gridControl().removeActivePath.prereq()

  module.setNullaryOperation "moveDown", 
    human_description: "Move Down"
    keyboard_shortcut: "alt+down"
    template:
      font_awesome_icon: "arrow-down"
    op: -> gridControl().moveActivePathDown()
    prereq: -> gridControl().moveActivePathDown.prereq()

  module.setNullaryOperation "moveUp", 
    human_description: "Move Up"
    keyboard_shortcut: "alt+up"
    template:
      font_awesome_icon: "arrow-up"
    op: -> gridControl().moveActivePathUp()
    prereq: -> gridControl().moveActivePathUp.prereq()

  module.setNullaryOperation "moveLeft", 
    human_description: "Outdent"
    keyboard_shortcut: "alt+left"
    template:
      font_awesome_icon: "outdent"
    op: -> gridControl().moveActivePathLeft()
    prereq: -> gridControl().moveActivePathLeft.prereq()

  module.setNullaryOperation "moveRight", 
    human_description: "Indent"
    keyboard_shortcut: "alt+right"
    template:
      font_awesome_icon: "indent"
    op: -> gridControl().moveActivePathRight()
    prereq: -> gridControl().moveActivePathRight.prereq()

  module.setNullaryOperation "sortByPriority", 
    human_description: "Sort by priority"
    template:
      font_awesome_icon: "sort-amount-desc"
    op: -> gridControl().sortActivePathByPriorityDesc()
    prereq: -> gridControl().sortActivePathByPriorityDesc.prereq()
