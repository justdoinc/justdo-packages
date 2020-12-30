APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane_item_details_section.helpers module.template_helpers
  
  Template.task_pane_item_details_section.helpers
    hasPermissionToEditMemebers: ->
      if (item_id = JD.activeItemId())?
        return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.users",item_id)
      return false
  
  
  Template.task_pane_item_details_section.events
    "click .edit-members": (e, tpl) ->
      ProjectPageDialogs.members_management_dialog.open(module.activeItemObj({_id: 1})._id)

      return
    
    "click .description-task-pane-section": (e, tpl) ->
      task = JD.activeItem({"#{Projects.tasks_description_last_update_field_id}": 1})
      if task?[Projects.tasks_description_last_update_field_id]?
        APP.projects.updateTaskDescriptionReadDate task._id
      
      return

  ItemDetails = (options) ->
    module.TaskPaneSection.call @, options

    return @

  module.registerTaskPaneSection "ItemDetails", ItemDetails

  Util.inherits ItemDetails, module.TaskPaneSection
