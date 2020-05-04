_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  setupCoreMenuSections: ->
    @registerMainSection "main",
      position: 100
    @registerSectionItem "main", "new-task",
      position: 100
      data:
        label: "New Task"
        op: ->
          APP.modules.project_page.performOp("addSiblingTask")

          return
        icon_type: "feather"
        icon_val: "plus"

      listingCondition: -> _.isEmpty(APP.modules.project_page.getUnfulfilledOpReq("addSiblingTask"))

    @registerSectionItem "main", "new-child-task",
      position: 200
      data:
        label: "New Child Task"
        op: ->
          APP.modules.project_page.performOp("addSubTask")

          return
        icon_type: "feather"
        icon_val: "corner-down-right"
    
    @registerSectionItem "main", "zoon-in",
      position: 300
      data:
        label: "Zoom in"
        op: ->
          APP.modules.project_page.performOp("zoomIn")

          return
        icon_type: "feather"
        icon_val: "zoom-in"
    
    return