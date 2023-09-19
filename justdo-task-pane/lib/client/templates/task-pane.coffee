# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Template.task_pane.onCreated ->
    self = @

    self.autorun ->
      # Upon invalidation, reset the task pane sections
      project_page_module.destroyAndInitCurrentTaskPaneSections()

      active_grid_item_type = project_page_module.getActiveGridItemType()

      if not active_grid_item_type?
        project_page_module.logger.debug "task pane sections: no grid control/active item, skipping tabs init"

        return
      else
        # When the active grid item type changes, update the task pane
        # item type

        project_page_module.setTaskPaneItemType(active_grid_item_type)

      return

  Template.task_pane.helpers project_page_module.template_helpers

  Template.task_pane.helpers
    task_pane_section_id: -> project_page_module.getCurrentTaskPaneSectionId()

  Template.task_pane.events
    "click .task-pane-resize-token": (e, tmpl) ->
      e.preventDefault()
      toolbar_open = APP.modules.project_page.preferences.get()?.toolbar_open

      if toolbar_open
        APP.modules.project_page.updatePreferences({toolbar_open: false})
      else
        APP.modules.project_page.updatePreferences({toolbar_open: true})

  Template.task_pane.onDestroyed ->
    project_page_module.destroyAndInitCurrentTaskPaneSections()