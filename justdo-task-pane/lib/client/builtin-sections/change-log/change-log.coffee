# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane_item_change_log_section.helpers module.template_helpers

  ItemChangeLog = (options) ->
    module.TaskPaneSection.call @, options

    return @

  module.registerTaskPaneSection "ItemChangeLog", ItemChangeLog

  Util.inherits ItemChangeLog, module.TaskPaneSection