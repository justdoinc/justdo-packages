Template.themes_selector.helpers
  webAppAvailableThemes: -> [
    {
      id: "default"
      label: "Solid Dark Blue (default)"
    }
    # If you want to change the default:
    #
    # 1. Create a new entry for the existing default below (assuming existing theme is solid-dark-blue):
    #
    # {
    #   id: "solid-dark-blue"
    #   label: "Solid Dark Blue"
    # }
    #
    # 2. Point the symbolic link of the default folder to the new default.
    # 3. If the default is selected from one of the existing themes - remove it.
    
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

    {
      id: "solid"
      label: "Solid Green"
    }

    {
      id: "classic"
      label: "Classic"
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
