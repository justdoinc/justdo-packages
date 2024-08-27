# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

# ALL THE TEMPLATE HELPERS ARE AVAILABLE BOTH ON:
# project_page_module.template_helpers and on project_page_module.helpers

# XXX IMPORTANT! there's a serious terminology confusion that one day should be fixed
# "sections" should be used for the registered templates "tabs" are for the
# current active available sections together with other meta-data (such as title)

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Meteor._ensure(project_page_module, "template_helpers")

  _.extend project_page_module.template_helpers,
    #
    # Toolbar details
    #
    toolbar_position: ->
      if not (toolbar_position = project_page_module.preferences.get().toolbar_position)? or
              toolbar_position not in ["right", "left"] # allowed values
        # the default position, if you change this, update also the default we
        # set in 015-project-page-wireframe-manager.coffee
        return APP.justdo_i18n.getRtlAwareDirection "right" # Only the default position should be RTL aware
      else
        return toolbar_position

    isToolbarOpen: ->
      if not (toolbar_open = project_page_module.preferences.get().toolbar_open)?
        # the default open/closed state, if you change this, update also the default we
        # set in 015-project-page-wireframe-manager.coffee
        return true
      else
        return toolbar_open

    toolbar_sections_count: -> project_page_module.current_task_pane_tabs.get()?.length or 0

    toolbar_sections: -> project_page_module.current_task_pane_tabs.get()

    toolbar_selected_section_id: -> project_page_module.getCurrentTaskPaneSectionId()

    toolbar_section_obj: -> project_page_module.getCurrentTaskPaneSectionObj()

    toolbar_section_template: -> project_page_module.getCurrentTaskPaneSectionTemplate()

  # template_helpers is a sub-set of helpers
  # Make all template helpers project_page_module helpers
  _.extend project_page_module.helpers, project_page_module.template_helpers
