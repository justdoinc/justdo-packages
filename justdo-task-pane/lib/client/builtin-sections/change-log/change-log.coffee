# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Template.task_pane_item_change_log_section.helpers project_page_module.template_helpers

  ItemChangeLog = (options) ->
    project_page_module.TaskPaneSection.call @, options

    return @

  project_page_module.registerTaskPaneSection "ItemChangeLog", ItemChangeLog

  Util.inherits ItemChangeLog, project_page_module.TaskPaneSection