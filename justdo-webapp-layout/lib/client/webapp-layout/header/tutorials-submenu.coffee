APP.executeAfterAppLibCode ->
  Template.tutorials_submenu_dropdown.helpers
    tutorials: -> JustdoTutorials.getRelevantTutorialsToState()

    zendeskEnabled: -> JustdoZendesk.enabled_rv.get()

    zendeskHost: ->
      host = JustdoZendesk.host # called only if zendeskEnabled returns true, so safe to assume existence
      return "https://#{host}/"

  Template.tutorials_submenu_dropdown.events
    "click .support-center": (e) ->
      zE.activate({hideOnClose: true})
      return

  Template.tutorials_submenu_dropdown_item.events
    "click .tutorial-item": (e) ->
      APP.justdo_tutorials.renderTutorial(@tutorial_id)
      return @
