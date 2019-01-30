_.extend JustdoAppHighContrast.prototype,
  _immediateInit: ->
    @_high_contrast_mode_dep = new Tracker.Dependency()

    return

  _deferredInit: ->
    if @destroyed
      return

    @setupUserConfigUi()
    @setupHighContrastModeClassSetter()

    return

  setupUserConfigUi: ->
    APP.executeAfterAppLibCode ->
      module = APP.modules.main

      module.user_config_ui.registerConfigSection "high-contrast-mode",
        title: "High Contrast Mode"
        priority: 800

      module.user_config_ui.registerConfigTemplate "high-contrast-mode-setter",
        section: "high-contrast-mode"
        template: "justdo_user_config_high_contrast_config"
        priority: 100

    return

  setupHighContrastModeClassSetter: ->
    @high_contrast_mode_tracker = Tracker.autorun =>
      if @isEnabledForThisDevice()
        $("body").addClass(JustdoAppHighContrast.high_contrast_mode_class)
      else
        $("body").removeClass(JustdoAppHighContrast.high_contrast_mode_class)

      return

    @onDestroy =>
      @high_contrast_mode_tracker.stop()
      $("body").removeClass(JustdoAppHighContrast.high_contrast_mode_class)

      return

    return

  isEnabledForThisDevice: ->
    @_high_contrast_mode_dep.depend()

    return amplify.store JustdoAppHighContrast.high_contrast_mode_local_storage_key

  toggleHighContrastMode: ->
    new_value = true

    if @isEnabledForThisDevice()
      new_value = false

    amplify.store JustdoAppHighContrast.high_contrast_mode_local_storage_key, new_value

    @_high_contrast_mode_dep.changed()

    return