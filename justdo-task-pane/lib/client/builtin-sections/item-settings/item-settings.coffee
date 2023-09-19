# # Do not use this package as example for how packages in
# # JustDo should look like, refer to README.md to read more

# APP.executeAfterAppLibCode ->
#   project_page_module = APP.modules.project_page

#   ItemSettings = (options) ->
#     project_page_module.TaskPaneSection.call @, options

#     return @

#   project_page_module.registerTaskPaneSection "ItemSettings", ItemSettings

#   Util.inherits ItemSettings, project_page_module.TaskPaneSection

#   _.extend ItemSettings.prototype,
#     getSettingsSections: ->
#       basic_sections = [
#         {
#           title: "Tickets Queue"
#           template: "task_pane_item_settings_tq"
#         }
#       ]

#       custom_sections = []

#       if project_page_module.curProj()?.isCustomFeatureEnabled("parents-management")
#         custom_sections.push
#           title: "Parent Tasks Management:"
#           template: "task_pane_item_parent_tasks"

#       return basic_sections.concat(custom_sections) 

#   Template.task_pane_item_settings_section.helpers project_page_module.template_helpers

#   Template.task_pane_item_settings_section.helpers
#     sections: ->
#       if not (getSettingsSections = project_page_module.getCurrentTaskPaneSectionObj()?.section_manager?.getSettingsSections)?
#         return []

#       return getSettingsSections()