JustdoHelpers.hooks_barriers.runCbAfterBarriers "post-justdo-pwa-init", ->
  APP.justdo_pwa.registerMobileTab "task-pane",
    label: "task_pane_label"
    order: 500
    icon: "sidebar"
    listingCondition: =>
      # Require active item
      return JD.activeItemId()?
    onActivate: ->
      APP.modules.project_page.updatePreferences({toolbar_open: true})
      return
    onDeactivate: ->
      APP.modules.project_page.updatePreferences({toolbar_open: false})
      return

  return
