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

  # Normalize a string for comparison by removing special characters and converting to lowercase
  _normalizeStringForComparison: (str) ->
    if not str?
      return ""

    # Remove underscores, dashes, extra whitespace, and newlines; convert to lowercase
    normalized_str = String(str).toLowerCase()
      .replace(/[-_\n\r]+/g, " ")
      .replace(/\s+/g, " ")
      .trim()
    return normalized_str

  # Generate a signature from headers array for use in storage key
  # Uses normalized, lowercased headers joined together
  getHeaderSignature: (headers) ->
    if _.isEmpty headers
      return
    
    # Normalize each header: lowercase, remove special chars, trim
    signature_str = _.map(headers, (header) => @_normalizeStringForComparison(header)).join("|")

    return signature_str

  getLocalStorageKey: (headers) ->
    base_key = "jci-last-selection::#{Meteor.userId()}"
    if headers? and (signature = @getHeaderSignature(headers))?
      return "#{base_key}::#{signature}"
    return base_key

  saveImportFieldConfig: (selected_columns_definitions, headers) ->
    import_config =
      cols: []

    for col_def in selected_columns_definitions
      import_config.cols.push col_def._id

    if not _.isEmpty(headers)
      # Save with header-specific key
      key_with_headers = @getLocalStorageKey(headers)
      amplify.store key_with_headers, import_config

    key_without_headers = @getLocalStorageKey()
    amplify.store key_without_headers, import_config

    return

  getImportFieldConfig: (headers) ->
    key = @getLocalStorageKey(headers)
    return amplify.store key

