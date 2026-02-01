APP.executeAfterAppLibCode ->
  Template.tutorials_submenu.onRendered ->
    # For unknown reason the below hook has trouble with Template.tutorials_submenu.events
    # so it has to be setup like this
    if APP.justdo_google_analytics?
      $(".nav-tutorials > .dropdown-toggle").on "click", (e) ->
        APP.justdo_google_analytics.sendEvent "tutorial-dropdown-clicked"
        return
    @$(".nav-tutorials").on "hide.bs.dropdown", -> APP.justdo_tutorials.is_tutorial_dropdown_allowed_to_close
    return

  Template.tutorials_submenu.helpers
    showHelpDropdown: ->
      if (ui_customizations = APP.env_rv.get()?.UI_CUSTOMIZATIONS)?
        return ui_customizations.indexOf("no-help") == -1

      return true
  
  Template.tutorials_submenu.events
    "click .dropdown-menu": -> 
      APP.justdo_tutorials.force_tutorial_dropdown_open_hook?.off?()
      return

  Template.tutorials_submenu_dropdown.helpers
    tutorials: -> [] # JustdoTutorials.getRelevantTutorialsToState()

    supportCenterUrl: ->
      landing_app_root_url = env.LANDING_APP_ROOT_URL or "https://justdo.com"
      return new URL("/support", landing_app_root_url)

  Template.tutorials_submenu_dropdown.events
    "click .support-center": (e) ->
      zE.activate({hideOnClose: true})
      return

    "click .show-recent-updates": -> APP.justdo_system_updates.displayUpdatePopup {skip_mark_as_read: true}

  Template.tutorials_submenu_dropdown_item.events
    "click .tutorial-item": (e) ->
      APP.justdo_tutorials.renderTutorial(@tutorial_id)
      return @
