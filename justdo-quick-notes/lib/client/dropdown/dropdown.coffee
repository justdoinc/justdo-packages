share.QuickNotesDropdown = JustdoHelpers.generateNewTemplateDropdown "quick-notes-dropdown", "justdo_quick_notes_dropdown",
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
          element.element.addClass "animate slideIn shadow-lg jd-p-075 bg-white"
          element.element.css
            top: new_position.top - 7
            left: new_position.left + 20

      $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

    return


# !!!!! Bug with MEMBERS DROPDOWN !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Template.justdo_quick_notes_dropdown.onCreated ->
  @quickNotes = [
    { title: "Seoul", completed: true },
    { title: "Berlin", completed: true },
    { title: "Moscow", completed: true },
    { title: "Hong Kong", completed: false },
    { title: "Paris", completed: false },
    { title: "Perth", completed: false },
    { title: "Kuala Lumpur", completed: true },
    { title: "New York", completed: false },
    { title: "London", completed: false },
    { title: "Rome", completed: false },
    { title: "Barselona", completed: true },
    { title: "Amsterdam", completed: false },
  ]

  return

Template.justdo_quick_notes_dropdown.helpers
  quckNotes: ->
    return Template.instance().quickNotes
