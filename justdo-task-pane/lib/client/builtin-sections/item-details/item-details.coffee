APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane_item_details_section.helpers module.template_helpers

  Template.task_pane_item_details_section.events
    "click .edit-members": (e, tpl) ->
      ProjectPageDialogs.members_management_dialog.open(module.activeItemObj({_id: 1})._id)

      return

  ItemDetails = (options) ->
    module.TaskPaneSection.call @, options

    return @

  module.registerTaskPaneSection "ItemDetails", ItemDetails

  Util.inherits ItemDetails, module.TaskPaneSection
