APP.executeAfterAppLibCode ->
  share.GridViewsDropdown = JustdoHelpers.generateNewTemplateDropdown "grid-views-dropdown-menu", "grid_views_dropdown_menu",
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
              top: new_position.top - 11
              left: new_position.left

        $(".dropdown-menu.show").removeClass("show")

      return

  Template.grid_views_dropdown_menu.onRendered ->
    $(".grid-views-search-input").focus()

    return

  Template.grid_views_dropdown_menu.helpers
    gridViews: ->
      return APP.collections.GridViews.find().fetch()


  return
