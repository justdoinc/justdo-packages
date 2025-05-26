_.extend JustdoClipboardImport.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoClipboardImport.project_custom_feature_id,
        installer: =>
          JD.registerPlaceholderItem  "#{JustdoClipboardImport.project_custom_feature_id}:activation-icon", {
            domain: "settings-dropdown-bottom"
            position: 380
            listingCondition: () => return true
            data:
              template: "justdo_clipboard_import_activation_icon"
              template_data: {}
          }
          return

        destroyer: =>
          JD.unregisterPlaceholderItem "#{JustdoClipboardImport.project_custom_feature_id}:activation-icon"
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
