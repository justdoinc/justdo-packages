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

    {
      id: "unicorn"
      label: "Unicorn"
    }

    {
      id: "solid"
      label: "Solid"
    }

    {
      id: "solid-blue"
      label: "Solid Blue"
    }

    {
      id: "solid-dark"
      label: "Solid Dark"
    }

    {
      id: "solid-dark-green"
      label: "Solid Dark Green"
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
