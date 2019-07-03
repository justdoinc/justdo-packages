_.extend CustomJustdoCumulativeSelect.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(CustomJustdoCumulativeSelect.project_custom_feature_id, project_doc)

  setupCustomFeatureMaintainer: ->
    prereq_installer_comp = null

    beforeEditHandler = (e, args) =>
      # Read: Note regarding editor/formatter in the README
      if not args.row?
        # We are in the More info section, allow the editor to appear
        return true

      if args.formatter_name == CustomJustdoCumulativeSelect.custom_field_formatter_id
        return false

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage CustomJustdoCumulativeSelect.project_custom_feature_id,
        installer: =>
          prereq_installer_comp = Tracker.autorun =>
            if (gc = APP.modules.project_page.gridControl())?
              gc.register "BeforeEditCell", beforeEditHandler

            return

          @installCustomField()

          return

        destroyer: =>
          prereq_installer_comp?.stop()
          prereq_installer_comp = null

          for tab_id, tab_def of all_tabs
            tab_def.grid_control?.unregister "BeforeEditCell", beforeEditHandler

          @uninstallCustomField()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  installCustomField: ->
    GridControlCustomFields.registerCustomFieldsTypes CustomJustdoCumulativeSelect.custom_field_type_id, 
      label: CustomJustdoCumulativeSelect.custom_field_label
      type_id: "number"

      custom_field_options:
        formatter: CustomJustdoCumulativeSelect.custom_field_formatter_id
        editor: CustomJustdoCumulativeSelect.custom_field_editor_id
        defaultValue: 0
        decimal: false

    return

  uninstallCustomField: ->
    GridControlCustomFields.unregisterCustomFieldsTypes CustomJustdoCumulativeSelect.custom_field_type_id

    return

  normalizeChecklistVal: (val) ->
    if not val?
      return 0

    if val not in [-1, 0, 1]
      return 0

    return val

  getFieldValueForGridControlPath: (grid_control, path, field) ->
    # If path has children in the grid control (filter state ignored): Returns an
    # array of the form [x, y] that represents that x out of y sub-tasks that aren't
    # -1 (x) are 1s (y)

    item_id = GridData.helpers.getPathItemId(path)

    if not (doc = grid_control._grid_data._grid_data_core.items_by_id[item_id])?
      return ""

    # If doc doesn't have children return the normalized state
    has_children = not _.isEmpty(grid_control._grid_data.tree_structure[doc._id])

    if not has_children
      # The simple case
      return @normalizeChecklistVal(doc[field])

    each_options =
      expand_only: false
      filtered_tree: false

    total_checks = 0
    total_checked = 0
    grid_control._grid_data.each path, each_options, (section, item_type, item_obj, item_path) =>
      item_state = @getFieldValueForGridControlPath(grid_control, item_path, field)
      if _.isArray(item_state)
        total_checks += item_state[0]
        total_checked += item_state[1]

        return -1 # don't step into the item, we know its results

      if item_state != -1
        total_checks += 1

      if item_state == 1
        total_checked += 1

      return

    return [total_checks, total_checked]

  toggleItemState: (grid_control, path, field, allow_na) ->
    # If not allow_na:
    #
    # We won't allow the state to change to allow_na
    # If state is na, we won't allow changing it.
    item_id = GridData.helpers.getPathItemId(path)

    val = @getFieldValueForGridControlPath(grid_control, path, field)

    if _.isArray val
      # Array, value is irrelevant, don't toggle.
      return

    if not allow_na and val == -1
      # We don't allow changing na when allow_na is false
      return

    if val != 1
      val += 1
    else if val == 1 and allow_na
      val = -1
    else
      val = 0

    @tasks_collection.update(item_id, {$set: {"#{field}": val}})

    return

