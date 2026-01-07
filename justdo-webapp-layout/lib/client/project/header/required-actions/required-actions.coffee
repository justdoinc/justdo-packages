APP.executeAfterAppLibCode ->
  shared_helpers = 
    requiredActionsCount: -> APP.projects.modules.required_actions.getCursor({sort: undefined, fields: {_id: 1}}).count()

  Template.required_actions_bell.helpers shared_helpers
  Template.required_actions_bell.helpers
    shouldCreateDropdown: ->
      tpl = Template.instance()
      if tpl.data?.skip_dropdown_creation
        return false

      return true

  Template.required_actions_bell_icon.helpers shared_helpers

  return