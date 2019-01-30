# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

# ALL THE TEMPLATE HELPERS ARE AVAILABLE BOTH ON:
# module.template_helpers and on module.helpers

# XXX IMPORTANT! there's a serious terminology confusion that one day should be fixed
# "sections" should be used for the registered templates "tabs" are for the
# current active available sections together with other meta-data (such as title)

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Meteor._ensure(module, "template_helpers")

  _.extend module.template_helpers,
    #
    # Toolbar details
    #
    toolbar_position: ->
      if not (toolbar_position = module.preferences.get().toolbar_position)? or
              toolbar_position not in ["right", "left"] # allowed values
        # the default position, if you change this, update also the default we
        # set in 015-project-page-wireframe-manager.coffee
        return "right"
      else
        return toolbar_position

    isToolbarOpen: ->
      if not (toolbar_open = module.preferences.get().toolbar_open)?
        # the default open/closed state, if you change this, update also the default we
        # set in 015-project-page-wireframe-manager.coffee
        return true
      else
        return toolbar_open

    toolbar_sections_count: -> module.current_task_pane_tabs.get()?.length or 0

    toolbar_sections: -> module.current_task_pane_tabs.get()

    toolbar_selected_section_id: -> module.getCurrentTaskPaneSectionId()

    toolbar_section_obj: -> module.getCurrentTaskPaneSectionObj()

    toolbar_section_template: -> module.getCurrentTaskPaneSectionTemplate()

  # template_helpers is a sub-set of helpers
  # Make all template helpers module helpers
  _.extend module.helpers, module.template_helpers
