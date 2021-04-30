APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj
  projects = APP.projects

  Template.required_actions_dropdown.helpers
    requiredActions: -> projects.modules.required_actions.getCursor({allow_undefined_fields: true, sort: {date: -1}}).fetch()

    requiredActionsCount: -> projects.modules.required_actions.getCursor({fields: {_id: 1}}).count()

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

  Template.required_actions_dropdown.events
    "click .required-actions-card": (e, tpl) ->
      e.stopPropagation() # need to avoit close dropdown on click

      return
