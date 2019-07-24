APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.TabSwitcherDropdown = JustdoHelpers.generateNewTemplateDropdown "tab-switcher", "project_operations_tab_switcher_dropdown",
    custom_dropdown_class: "dropdown-menu px-3 animate slideIn shadow-lg border-0"
    custom_bound_element_options:
      container: ".project-container" # So we can use the .project-admin and other state classes bound to .project-container
      close_button_html: null
    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "left top"
          at: "left bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            element.element.css
              top: new_position.top + 2
              left: new_position.left - 3

  Template.project_operations_tab_switcher_dropdown.helpers module.template_helpers

  Template.project_operations_tab_switcher_dropdown.helpers
    userId: -> Meteor.userId()
    ticketsQueuesExists: -> APP.collections.TicketsQueues.find().count() > 0

  sections_vars_attributes_prefix = "data-sv-"
  Template.project_operations_tab_switcher_dropdown.events
    "click a": (e) ->
      e.preventDefault()

      tab_switcher = e.currentTarget
      $tab_switcher = $(tab_switcher)

      tab_id = $tab_switcher.data("tab-id")

      tab_switcher_attributes = _.map tab_switcher.attributes, (attr) -> attr.name

      sections_vars_attributes = _.filter tab_switcher_attributes, (attr) ->
        if typeof attr != "string"
          # Fixes an issue found on Safari, in which a null attribute got appended to the attr list
          return false

        return attr.substr(0, sections_vars_attributes_prefix.length) == sections_vars_attributes_prefix

      sections_state = {}

      for attr in sections_vars_attributes
        [section_id, var_name] = attr.substr(sections_vars_attributes_prefix.length).split("_")

        Meteor._ensure sections_state, section_id

        sections_state[section_id][var_name] = $tab_switcher.attr(attr)

      gcm = module.getCurrentGcm()

      gcm.activateTab(tab_id)
      Tracker.flush() # Run post-tab-change procedures immeidately
                      # Will prevent buttons that depends on tab
                      # state (e.g. print) from delay disable/enable
                      # mode update until flush.

      gcm.setActiveGridControlSectionsState(sections_state, true) # true is to replace any existing section state vars

      # Close the dropdown
      $tab_switcher.closest(".tab-switcher").data("close")()
