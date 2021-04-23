APP.executeAfterAppLibCode ->
  Template.required_actions_bell.helpers
    requiredActionsCount: -> APP.projects.modules.required_actions.getCursor({sort: undefined, fields: {_id: 1}}).count()