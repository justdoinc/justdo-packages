Template.themes_selector.helpers
  webAppAvailableThemes: -> [
    {
      id: "default"
      label: "themes_selector_default"
    }
    # If you want to change the default:
    #
    # 1. Create a new entry for the existing default below (assuming existing theme is solid-dark-blue):
    #
    # {
    #   id: "solid-dark-blue"
    #   label: "themes_selector_solid_dark_blue"
    # }
    #
    # 2. Point the symbolic link of the default folder to the new default.
    # 3. If the default is selected from one of the existing themes - remove it.

    {
      id: "solid-blue"
      label: "themes_selector_solid_blue"
    }

    {
      id: "solid-dark"
      label: "themes_selector_solid_dark"
    }

    {
      id: "solid-dark-green"
      label: "themes_selector_solid_dark_green"
    }

    {
      id: "solid-purple"
      label: "themes_selector_solid_purple"
    }

    {
      id: "solid"
      label: "themes_selector_solid"
    }

    {
      id: "solid-orange"
      label: "themes_selector_solid_orange"
    }

    {
      id: "classic"
      label: "themes_selector_classic"
    }

    {
      id: "unicorn"
      label: "themes_selector_unicorn"
    }
  ]

  userSelectedTheme: -> APP.bootstrap_themes_manager.getLastUsedThemeName()

Template.themes_selector.events
  "change .themes-selector": (e) ->
    APP.bootstrap_themes_manager.setTheme($(e.target).val())

    return
