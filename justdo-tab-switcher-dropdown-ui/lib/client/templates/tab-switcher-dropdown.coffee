APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.project_operations_tab_switcher_dropdown.helpers module.template_helpers

  Template.project_operations_tab_switcher_dropdown.helpers
    tab_switcher_manager: -> module.tab_switcher_manager
    tabAttributes: ->
      tab_attributes = {}

      for attribute_type, attribute_type_keys of @tab_sections_state
        for attribute_type_key, attribute_type_val of attribute_type_keys
          tab_attributes["data-sv-#{attribute_type}_#{attribute_type_key}"] = attribute_type_val

      return tab_attributes

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

      gcm.activateTabWithSectionsState(tab_id, sections_state)

      # Ensure the dropdown is closed.
      $(e.target).closest(".dropdown-menu").removeClass("show").closest(".dropdown").removeClass("show")

      return

    "change .views-search-input, keyup .views-search-input": (e) ->
      module.tab_switcher_manager.setSectionsItemsLabelFilter($(e.target).val())

      return