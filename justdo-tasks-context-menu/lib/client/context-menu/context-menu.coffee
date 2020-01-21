Template.tasks_context_menu.helpers
  isAddSiblingAllowed: ->
    return _.isEmpty(APP.modules.project_page.getUnfulfilledOpReq("addSiblingTask"))

  updatedByOrCreatedBy: ->
    if not item_obj?
      return false

    item_obj = @controller.getContextItemObj()
    
    return item_obj.updated_by or item_obj.created_by_user_id

Template.tasks_context_menu.events
  "click .new-task": ->
    APP.modules.project_page.performOp("addSiblingTask")

    return

  "click .new-child-task": ->
    APP.modules.project_page.performOp("addSubTask")

    return

  "click .zoom-in": ->
    APP.modules.project_page.performOp("zoomIn")

    return