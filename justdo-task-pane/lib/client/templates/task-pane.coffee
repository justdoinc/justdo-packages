# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane.onCreated ->
    self = @

    self.autorun ->
      # Upon invalidation, reset the task pane sections
      module.destroyAndInitCurrentTaskPaneSections()

      active_grid_item_type = module.getActiveGridItemType()

      if not active_grid_item_type?
        module.logger.debug "task pane sections: no grid control/active item, skipping tabs init"

        return
      else
        # When the active grid item type changes, update the task pane
        # item type

        module.setTaskPaneItemType(active_grid_item_type)

      return

  Template.task_pane.helpers module.template_helpers

  Template.task_pane.helpers
    task_pane_section_id: -> module.getCurrentTaskPaneSectionId()

  Template.task_pane.events
    "click .task-pane-resize-token": (e, tmpl) ->
      e.preventDefault()
      toolbar_open = APP.modules.project_page.preferences.get()?.toolbar_open

      if toolbar_open
        APP.modules.project_page.updatePreferences({toolbar_open: false})
      else
        APP.modules.project_page.updatePreferences({toolbar_open: true})

  Template.task_pane.onDestroyed ->
    module.destroyAndInitCurrentTaskPaneSections()