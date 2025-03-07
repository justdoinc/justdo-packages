APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  share.TabSwitcherDropdown = JustdoHelpers.generateNewTemplateDropdown "tab-switcher-dropdown", "project_operations_tab_switcher_dropdown",
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
            element.element.addClass "animate slideIn shadow-lg"
            element.element.css
              top: new_position.top - 10
              left: new_position.left + 6

        $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

      return

  Template.project_operations_tab_switcher_dropdown.helpers project_page_module.template_helpers

  Template.project_operations_tab_switcher_dropdown.helpers
    tab_switcher_manager: -> project_page_module.tab_switcher_manager
    tabAttributes: ->
      tab_attributes = {}

      for attribute_type, attribute_type_keys of @tab_sections_state
        for attribute_type_key, attribute_type_val of attribute_type_keys
          tab_attributes["data-sv-#{attribute_type}_#{attribute_type_key}"] = attribute_type_val

      return tab_attributes

    itemsSource: ->
      return @itemsSource(project_page_module.tab_switcher_manager)

  sections_vars_attributes_prefix = "data-sv-"
  Template.project_operations_tab_switcher_dropdown.events
    "click a": (e) ->
      e.preventDefault()

      tab_switcher = e.currentTarget
      $tab_switcher = $(tab_switcher)

      tab_id = $tab_switcher.attr("data-tab-id")

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

      gcm = project_page_module.getCurrentGcm()

      gcm.activateTabWithSectionsState(tab_id, sections_state)

      # Ensure the dropdown is closed.
      $(e.target).closest(".tab-switcher-dropdown").removeClass("open")

      return

    "change .views-search-input, keyup .views-search-input": (e) ->
      project_page_module.tab_switcher_manager.setSectionsItemsLabelFilter($(e.target).val())

      return

    "keydown .tab-switcher-dropdown-wrapper": (e) ->
      $dropdown_item = $(e.target).closest(".views-search-wrapper,.dropdown-item")

      if e.keyCode == 38 # Up
        e.preventDefault()
        
        if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
          $prev_item.focus()
        else
          $(".views-search-input", $dropdown_item.closest(".tab-switcher-dropdown-wrapper")).focus()

      if e.keyCode == 40 # Down
        e.preventDefault()
        
        $dropdown_item.nextAll(".dropdown-item").first().focus()

      return
