APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Template.task_pane_item_details_section.helpers project_page_module.template_helpers
  
  Template.task_pane_item_details_section.helpers
    inboundEmailEnabled: -> APP.justdo_inbound_emails?

    hasPermissionToEditMemebers: ->
      if (item_id = JD.activeItemId())?
        return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.users", item_id)
      return false

    activeItemNotNull: ->
      if not (active_item_id = JD.activeItemId())?
        return false
      
      return APP.collections.Tasks.findOne(active_item_id,
        fields: 
          _id: 1
      )?
  
  Template.task_pane_item_details_section.events
    "click .edit-members": (e, tpl) ->
      ProjectPageDialogs.members_management_dialog.open(project_page_module.activeItemObj({_id: 1})._id)

      return
    
    "click .description-task-pane-section": (e, tpl) ->
      task = JD.activeItem({"#{Projects.tasks_description_last_update_field_id}": 1})
      if task?[Projects.tasks_description_last_update_field_id]?
        APP.projects.updateTaskDescriptionReadDate task._id
      
      return

  ItemDetails = (options) ->
    project_page_module.TaskPaneSection.call @, options

    return @

  project_page_module.registerTaskPaneSection "ItemDetails", ItemDetails

  Util.inherits ItemDetails, project_page_module.TaskPaneSection
