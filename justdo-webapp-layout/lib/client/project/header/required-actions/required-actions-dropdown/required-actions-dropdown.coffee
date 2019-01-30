APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  module.RequiredActionsDropdown = JustdoHelpers.generateNewTemplateDropdown "required-actions-dropdown", "required_actions_dropdown",
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
              top: new_position.top + 11
              left: new_position.left + 20

  projects = APP.projects

  Template.required_actions_dropdown.helpers
    required_actions: ->
      projects.modules.required_actions.getCursor(curProj()?.getProjectDoc()?._id).fetch()

  # XXX in the future will be defined as part
  # of each required action definition
  required_actions_titles_map =
    "transfer_request": "Ownership Transfer"
    "ownership_transfer_rejected": "Ownership Transfer Rejected"

  Template.required_action_card.helpers
    negativeDateOrNow: -> JustdoHelpers.negativeDateOrNow(@date)

    getTypeTemplate: -> "required_action_card_#{@type}"

    typeTemplateData: ->
      data = _.extend {}, @,
        projects_obj: APP.projects
        project_obj: -> curProj()
        gridControl: -> module.gridControl(false)
        getGridControlMux: -> module.getGridControlMux()

      return data

    required_action_type_title: ->
      required_actions_titles_map[@type]
