# # Do not use this package as example for how packages in
# # JustDo should look like, refer to README.md to read more

# APP.executeAfterAppLibCode ->
#   module = APP.modules.project_page

#   ItemSettings = (options) ->
#     module.TaskPaneSection.call @, options

#     return @

#   module.registerTaskPaneSection "ItemSettings", ItemSettings

#   Util.inherits ItemSettings, module.TaskPaneSection

#   _.extend ItemSettings.prototype,
#     getSettingsSections: ->
#       basic_sections = [
#         {
#           title: "Tickets Queue"
#           template: "task_pane_item_settings_tq"
#         }
#       ]

#       custom_sections = []

#       if module.curProj()?.isCustomFeatureEnabled("parents-management")
#         custom_sections.push
#           title: "Parent Tasks Management:"
#           template: "task_pane_item_parent_tasks"

#       return basic_sections.concat(custom_sections) 

#   Template.task_pane_item_settings_section.helpers module.template_helpers

#   Template.task_pane_item_settings_section.helpers
#     sections: ->
#       if not (getSettingsSections = module.getCurrentTaskPaneSectionObj()?.section_manager?.getSettingsSections)?
#         return []

#       return getSettingsSections()