Template.justdo_system_updates_config.onCreated ->
  # @show_system_updates_dependency = new Tracker.Dependency()

Template.justdo_system_updates_config.helpers
  enabled: ->
    # Template.instance().show_system_updates_dependency.depend()
    APP.justdo_system_updates.isEnabled()

Template.justdo_system_updates_config.events
  "click .justdo-system-updates-config": (e, tpl) ->
    # tpl.show_system_updates_dependency.changed()
    APP.justdo_system_updates.toggleDisplayOption()

    return
