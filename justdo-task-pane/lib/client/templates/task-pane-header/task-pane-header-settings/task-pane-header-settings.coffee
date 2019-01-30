# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  #
  # Setup the dropdown
  #
  TaskPaneSettingsDropdown = JustdoHelpers.generateNewTemplateDropdown "task-pane-settings", "task_pane_settings",
    custom_dropdown_class: "dropdown-menu"
    custom_bound_element_options:
      close_button_html: null
    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "right top"
          at: "right bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            element.element.css
              top: new_position.top
              left: new_position.left - 1

  task_pane_settings_dropdown = null
  Template.task_pane_header.onRendered ->
    task_pane_settings_dropdown =
      new TaskPaneSettingsDropdown(".task-pane-settings-btn")

  Template.task_pane_header.onDestroyed ->
    if task_pane_settings_dropdown?
      task_pane_settings_dropdown.destroy()
      task_pane_settings_dropdown = null

  #
  # task_pane_settings_dock_to
  #
  available_positions = ["right", "left"]
  Template.task_pane_settings_dock_to.helpers
    available_positions: -> _.without available_positions, module.preferences.get().toolbar_position

  Template.task_pane_settings_dock_to.events
    "click .dock-to-setting-option": (e) ->
      module.updatePreferences({toolbar_position: $(e.target).attr("target-position")})
      task_pane_settings_dropdown.$dropdown.data("close")()