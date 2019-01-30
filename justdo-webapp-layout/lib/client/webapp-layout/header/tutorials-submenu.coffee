APP.executeAfterAppLibCode ->
  #
  # Setup the dropdown
  #
  TutorialsMenuDropdown = JustdoHelpers.generateNewTemplateDropdown "tutorials-menu", "tutorials_submenu_dropdown",
    custom_dropdown_content_class: "open"
    dropdown_template_containing_node_tag: "ul"
    dropdown_template_containing_node_class: "dropdown-menu"
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
              top: new_position.top - 3
              left: new_position.left + 10

  tutorials_menu_dropdown = null
  Template.tutorials_submenu.onRendered ->
    tutorials_menu_dropdown =
      new TutorialsMenuDropdown(".tutorials-dropdown")

    $(".tutorials-dropdown .dropdown-toggle").click (e) ->
      e.preventDefault()

      return

  Template.tutorials_submenu.onDestroyed ->
    if tutorials_menu_dropdown?
      tutorials_menu_dropdown.destroy()
      tutorials_menu_dropdown = null

  Template.tutorials_submenu_dropdown.helpers
    tutorials: -> JustdoTutorials.getRelevantTutorialsToState()

    zendeskEnabled: -> JustdoZendesk.enabled_rv.get()

    zendeskHost: ->
      host = JustdoZendesk.host # called only if zendeskEnabled returns true, so safe to assume existence

      return "https://#{host}/"

  Template.tutorials_submenu_dropdown.events
    "click .support-center": (e) ->
      e.preventDefault()

      tutorials_menu_dropdown.closeDropdown()

      zE.activate({hideOnClose: true})

      return

  Template.tutorials_submenu_dropdown_item.events
    "click .tutorial-item": (e) ->
      e.preventDefault()

      tutorials_menu_dropdown.closeDropdown()

      APP.justdo_tutorials.renderTutorial(@tutorial_id)

      return @
