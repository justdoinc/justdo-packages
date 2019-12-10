Template.themes_selector.helpers
  webAppAvailableThemes: -> [
    {
      id: "default"
      label: "Default"
    }

    {
      id: "minty"
      label: "Minty"
    }

    {
      id: "cerulean"
      label: "Cerulean"
    }

    {
      id: "sandstone"
      label: "Sandstone"
    }

    {
      id: "sketchy"
      label: "Sketchy"
    }

    # {
    #   id: "superhero"
    #   label: "Superhero (Experimental Dark)"
    # }
  ]

  userSelectedTheme: -> APP.bootstrap_themes_manager.getLastUsedThemeName()

Template.themes_selector.events
  "change .themes-selector": (e) ->
    APP.bootstrap_themes_manager.setTheme($(e.target).val())

    return
