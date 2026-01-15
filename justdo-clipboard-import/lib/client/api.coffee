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

  getLocalStorageKey: ->
    return "jci-last-selection::#{Meteor.userId()}"
  # Normalize a string for comparison by removing special characters and converting to lowercase
  _normalizeStringForComparison: (str) ->
    if not str?
      return ""

  saveImportConfig: (selected_columns_definitions) ->
    storage_key = @getLocalStorageKey()
    # Remove underscores, dashes, extra whitespace, and newlines; convert to lowercase
    normalized_str = String(str).toLowerCase()
      .replace(/[-_\n\r]+/g, " ")
      .replace(/\s+/g, " ")
      .trim()
    return normalized_str

    import_config =
      # rows: Array.from modal_data.rows_to_skip_set.get()
      cols: []

    for col_def in selected_columns_definitions
      import_config.cols.push col_def._id

    amplify.store storage_key, import_config
    return

