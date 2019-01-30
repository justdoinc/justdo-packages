_.extend JustdoRowsStyling.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    @_registerSchema()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoRowsStyling.project_custom_feature_id,
        installer: =>
          @_installControllerStyler()
          @_installGcRowsMetadataGenerator()

          return

        destroyer: =>
          @_uninstallControllerStyler()
          @_uninstallGcRowsMetadataGenerator()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  _controller_styler_installer_computation: null
  _installControllerStyler: ->
    if @_controller_styler_installer_computation?
      # Already installed.

      return
    
    @_controller_styler_installer_computation = Tracker.autorun =>
      if (task = APP.modules.project_page.gridControl()?.getCurrentPathObj())?
        styles = ""

        if (sb = task['jrs:style'])?
          if sb.bold?
            styles += "font-weight:bold; "
          if sb.underline?
            styles += "text-decoration:underline; "
          if sb.italic?
            styles += "font-style:italic; "

        $('#change-row-style .fa-font').attr("style", styles)

      return

    return

  _uninstallControllerStyler: ->
    @_controller_styler_installer_computation?.stop()

    @_controller_styler_installer_computation = null

    return

  _gcMetadataGenerator: (item, item_meta_details, index) ->
    styles = {}
    if (sb = item["jrs:style"])?
      if sb.bold?
        styles["font-weight"] = "bold"
      if sb.underline?
        styles["text-decoration"] = "underline"
      if sb.italic?
        styles["font-style"] = "italic"

    return {style: styles}

  _gc_rows_metadata_generator_installer_computation: null
  _installGcRowsMetadataGenerator: ->
    if @_gc_rows_metadata_generator_installer_computation?
      # Already installed.

      return
    
    @_gc_rows_metadata_generator_installer_computation = Tracker.autorun =>
      if (gc = APP.modules.project_page.gridControl())?
        if not gc._justdo_rows_styling_installed?
          gc.registerMetadataGenerator @_gcMetadataGenerator

          gc._justdo_rows_styling_installed = true

      return

    return

  _uninstallGcRowsMetadataGenerator: ->
    @_gc_rows_metadata_generator_installer_computation?.stop()

    if (gcm = APP.modules.project_page.getGridControlMux())?
      _.each gcm.getAllTabsNonReactive(), (tab) =>
        if (gc = tab.grid_control)?
          gc.unregisterMetadataGenerator @_gcMetadataGenerator

          delete gc._justdo_rows_styling_installed

    @_gc_rows_metadata_generator_installer_computation = null

    return

  row_style_schema:
    StyleSchema = new SimpleSchema
      bold:
        type: Boolean
        optional: true
      italic:
        type: Boolean
        optional: true
      underline:
        type: Boolean
        optional: true

  _registerSchema: ->
    schema =
      'jrs:style':
        label: "Row Style"
        optional: true
        grid_effects_metadata_rendering: true
        type: @row_style_schema

    @tasks_collection.attachSchema schema

    return
