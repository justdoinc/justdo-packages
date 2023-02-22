# The order below will also serve as the ordering in the dropdown, sorted alphabetically
# The location of non_sorted_field_ids are fixed to top, the rest is sorted
non_sorted_field_ids = [
  "justdo_task_dependencies_mf" # Replace with JustdoPlanningUtilities.dependencies_mf_field_id after changing the load order of JustdoPlanningUtilities before this package
  "title"
  "start_date"
  "end_date"
  "due_date"
  "jpu:basket_start_date_formatter" # These two are relevant only when the Gantt is enabled, they are kept here just to have them high on the selection, they will clear out if the gantt is disabled
  "jpu:basket_end_date_formatter"
]
base_supported_fields_ids = [
  "owner_id"
  "status"
  "priority"
  "state"
  "description"
].sort (a, b) -> return a.localeCompare b # localeCompare is used instead simply sort() to ignore case differences

noneditable_importable_fields = [
  "owner_id"
]

base_supported_fields_ids = non_sorted_field_ids.concat base_supported_fields_ids

excluded_field_ids = [
  JustdoPlanningUtilities.task_duration_pseudo_field_id # XXX Duration is expected to be re-enabled in the future
]

custom_allowed_dates_formats = ["MMM DD YYYY", "DD MMMM YYYY", "Others"]

getLocalStorageKey = ->
  return "jci-last-selection::#{Meteor.userId()}"

getDefaultDateFormat = ->
  return JustdoHelpers.getUserPreferredDateFormat()

isDateFieldDef = (field_def) ->
  date_formatters = ["unicodeDateFormatter"]

  if field_def.grid_column_formatter in date_formatters
    return true

  if (original_extended_formatter_name = GridControl.Formatters[field_def.grid_column_formatter]?.original_extended_formatter_name)? and original_extended_formatter_name in date_formatters
    return true

  return false

showErrorInSnackbarAndRevertState = (options) ->
  options.dialog_state.set "has_data"
  $("#progressbar .ui-progressbar-value").css "background", "#e91e63"

  if not options.snackbar_duration?
    options.snackbar_duration = 5000

  JustdoSnackbar.show
    text: options.snackbar_message
    duration: options.snackbar_duration

  if options.problematic_row?
    scrollToAndHighlightProblematicRow options.problematic_row

  return

saveImportConfig = (selected_columns_definitions) ->
  storage_key = getLocalStorageKey()

  import_config =
    # rows: Array.from modal_data.rows_to_skip_set.get()
    cols: []

  for col_def in selected_columns_definitions
    import_config.cols.push col_def._id

  amplify.store storage_key, import_config
  return

setProgressbarValue = (processed_lines, total_lines) ->
  options =
    value: processed_lines
  if total_lines?
    options.max = total_lines
  $("#progressbar").progressbar options
  $("#progressbar").show()
  return

scrollToAndHighlightProblematicRow = (line_number) ->
  # The try-catch is here to ignore the error generated
  # by jQuerying elements that does not exist, to facilitate displaying error message in snackbar.
  # e.g. The modal is closed already when error occurs in importDependencies/importOwners
  try
    line_number = parseInt line_number, 10
    $problematic_row = $(".justdo-clipboard-import-table tr:nth-child(#{line_number + 1})")
    # problematic_row is a jQuery element, scrollIntoView() is native js method
    $problematic_row.get(0).scrollIntoView({behavior: "smooth", block: "center"})
    $problematic_row.effect("highlight", {}, 10000)
  catch
    return
  return

getAvailableFieldTypes = ->
  # Reactive resource
  #
  # Returns an array whose
  #
  #  * First item is an object with the schema definition for the
  #  supported_fields_ids available in the current grid.
  #  * Second item is an array of schema definitions + _id field with the
  #  field id. Ordered according to supported_fields_ids order.

  gc = APP.modules.project_page.mainGridControl()

  supported_fields_ids = base_supported_fields_ids.slice()
  all_fields = gc.getSchemaExtendedWithCustomFields()

  supported_fields_ids = supported_fields_ids.filter (field_id) ->
    # Remove from base_supported_fields_ids all those fields that aren't editable any longer.
    # (E.g when the gantt is on we replace the built-in start_date/end_date with more sophisticated
    # fields, when we do that, we disable the start_date/end_date fields)

    if all_fields[field_id]?.grid_editable_column or field_id in noneditable_importable_fields
      return true

    return false

  custom_fields_supported_formatters = ["defaultFormatter", "unicodeDateFormatter", "keyValueFormatter", "calculatedFieldFormatter", JustdoPlanningUtilities.dependencies_formatter_id, "MultiSelectFormatter"]

  for field_id, field of all_fields
    if field_id not in supported_fields_ids and field_id not in excluded_field_ids
      if field.custom_field and field.grid_editable_column and field.grid_column_formatter in custom_fields_supported_formatters
        supported_fields_ids.push field_id

      else if (original_extended_formatter_name = GridControl.Formatters[field.grid_column_formatter]?.original_extended_formatter_name)? and original_extended_formatter_name in custom_fields_supported_formatters
        # If this is a formatter that extends one of the formatters that we are supporting, allow it to be available for selection
        supported_fields_ids.push field_id

  supported_fields_definitions_object =
    _.pick all_fields, supported_fields_ids

  supported_fields_definitions_array =
    _.map supported_fields_ids, (field_id) ->
      if (field_def = supported_fields_definitions_object[field_id])?
        return _.extend {}, field_def, {_id: field_id}
      return undefined

  supported_fields_definitions_array = _.filter(supported_fields_definitions_array)
  return [supported_fields_definitions_object, supported_fields_definitions_array]

getSelectedColumnsDefinitions = ->
  # This function returns an array of column definitions
  # If there is an error, it returns {
  #   err: {
  #     message: <String>
  #   }
  # }

  available_field_types = getAvailableFieldTypes()

  selected_columns_definitions = []

  field_id_existance = {}
  duplicated_field_id = null

  $(".justdo-clipboard-import-input-selector button[value]").each ->
    field_id = $(@).val()

    if field_id_existance[field_id]? and field_id != "clipboard-import-no-import"
      duplicated_field_id = field_id
    else
      field_id_existance[field_id] = true

    selected_columns_definitions.push(_.extend {}, available_field_types?[0]?[field_id], {_id: field_id})

    return

  if duplicated_field_id?
    col_def = available_field_types?[0]?[duplicated_field_id]
    ret_val =
      err:
        message: "More than 1 column is selected as #{if col_def? then col_def.label else duplicated_field_id}"
    return ret_val

  return selected_columns_definitions

testDataAndImport = (modal_data, selected_columns_definitions) ->
  modal_data.dialog_state.set "importing"
  modal_data.import_helper_message.set "Preparing..."
  saveImportConfig selected_columns_definitions
  # Check that all columns have the same number of cells
  cp_data = modal_data.clipboard_data.get()
  number_of_columns = cp_data[0].length
  project_id = JD.activeJustdo({_id: 1})._id
  line_number = 0
  base_indent = -1
  max_indent = -1
  last_indent = 0
  lines_to_add = {} # line_index:
                    #   task: task
                    #   indent_level: indent level

  row_index = 0

  temp_import_ids = []
  owner_id_to_temp_import_id_map = {}
  import_idx_to_temp_import_id_map = {}
  dependencies_strs = {}

  index_column = null
  for col_def, i in selected_columns_definitions
    if col_def._id == "clipboard-import-index"
      index_column = i
      break

  for row in cp_data
    task = {}
    line_number += 1
    if row.length != number_of_columns
      showErrorInSnackbarAndRevertState
        dialog_state: modal_data.dialog_state
        snackbar_message: "Mismatch in number of columns on different rows. Import aborted."
      return false

    task.project_id = project_id
    if not modal_data.rows_to_skip_set.get().has("#{row_index}")
      indent_level = 1

      temp_import_id = "#{Random.id()}_L#{line_number}"
      task["jci:temp_import_id"] = temp_import_id
      temp_import_ids.push temp_import_id

      if index_column?
        # Allways handle "clipboard-import-index" column first
        cell_val = row[index_column].trim()
        import_idx_to_temp_import_id_map[cell_val] = temp_import_id

      for column_num in [0..(number_of_columns - 1)]
        if (_.isString(cell_val = row[column_num]))
          cell_val = cell_val.replace(/[\u200B-\u200D\uFEFF]/g, "").trim() # 'replace' is used to remove zero-width white space
        else
          cell_val.import_value = cell_val.import_value.replace(/[\u200B-\u200D\uFEFF]/g, "").trim()

        field_def = selected_columns_definitions[column_num]

        if isDateFieldDef(field_def) and (underlying_field_id = field_def.grid_column_formatter_options?.underlying_field_id)?
          # For the unicode date fields (those that returns true for isDateFieldDef) we support the case
          # where underlying_field_id is defined in the formatter option.
          #
          # XXX A better solution would support the more general concept of grid_column_custom_storage_mechanism.
          # but since at the moment only the date fields are using this mechanism, we implement only that case.
          field_id = underlying_field_id
        else
          field_id = field_def._id

        if field_id == "clipboard-import-index" # Do nothing, "clipboard-import-index" is already handled above
        else if field_id == "owner_id"
          if (user_id = cell_val.import_value)?
            if (owner_id_to_temp_import_id_map[user_id])?
              owner_id_to_temp_import_id_map[user_id].push temp_import_id
            else
              owner_id_to_temp_import_id_map[user_id] = [temp_import_id]
        else if cell_val.length > 0 and field_id == "task-indent-level"
          indent_level = parseInt cell_val, 10
          if base_indent < 0
            base_indent = indent_level
            last_indent = indent_level
        else if field_id == JustdoPlanningUtilities.dependencies_mf_field_id
          if cell_val != ""
            dependencies_strs[task["jci:temp_import_id"]] = cell_val # XXX temp_import_id can be null
        else if field_id == JustdoPlanningUtilities.task_duration_pseudo_field_id
          duration_days_regex = /^(\d+)\s*(d|day|days)?$/ # Matches: 3/3d/3days/3day, int only for numeric part.
          if (match_reuslt = cell_val.match duration_days_regex)?
            task[field_id] = match_reuslt[1] # Sample match result: ['3 days', '3', 'days', index: 0, input: '3 days', groups: undefined]
          else
            showErrorInSnackbarAndRevertState
              dialog_state: modal_data.dialog_state
              snackbar_message: "#{JustdoPlanningUtilities.task_duration_pseudo_field_label} should be an integer. Import aborted."
              snackbar_duration: 15000
              problematic_row: line_number
            return false

        else if cell_val.length > 0 and field_id != "clipboard-import-no-import" and field_id != "task-indent-level"
          if field_def.type is String

            # Newlines in description will be converted into <br> to display correctly
            if field_id is "description"
              cell_val = JustdoHelpers.nl2br cell_val

            # Dealing with options fields
            if field_def.grid_column_formatter == "keyValueFormatter"
              val = null
              for key, defs of field_def.grid_values
                # we had cases when copy from Excel (even though it was not in the data) added \r\n  and double space... so clearing these out.
                if defs?.txt?.trim()?.replace(/(\r\n|\n|\r)/gm, "").replace(/\s\s+/g, " ").toLowerCase() == cell_val.trim().replace(/(\r\n|\n|\r)/gm, "").replace(/\s\s+/g, " ").toLowerCase()
                  val = key
                  break
              if val == null
                showErrorInSnackbarAndRevertState
                  dialog_state: modal_data.dialog_state
                  snackbar_message: "Invalid #{field_def.label} value #{cell_val} in line #{line_number} - not a valid option. Import aborted."
                  snackbar_duration: 15000
                  problematic_row: line_number

                return false
              task[field_id] = val
            else
              task[field_id] = cell_val

          if field_def.grid_column_formatter == "MultiSelectFormatter"
            values = cell_val.split(',')
            option_values = []
            for value in values
              value = value.trim().replace(/(\r\n|\n|\r)/gm, "").replace(/\s\s+/g, " ").toLowerCase()
              val = null
              for key, defs of field_def.grid_values
                # we had cases when copy from Excel (even though it was not in the data) added \r\n  and double space... so clearing these out.
                if defs?.txt?.trim()?.replace(/(\r\n|\n|\r)/gm, "").replace(/\s\s+/g, " ").toLowerCase() == value
                  val = key
                  break
              if val == null
                showErrorInSnackbarAndRevertState
                  dialog_state: modal_data.dialog_state
                  snackbar_message: "Invalid #{field_def.label} value #{value} in line #{line_number} - not a valid option. Import aborted."
                  snackbar_duration: 15000
                  problematic_row: line_number

                return false
              option_values.push val
            task[field_id] = option_values

          else if field_def.type is Number
            # TODO: Look for: '_available_field_types' under justdo-internal-packages/grid-control-custom-fields/lib/both/grid-control-custom-fields/grid-control-custom-fields.coffee
            # in the future, the information on whether we need to use parseFloat or parseInt() should be taken from the relevant definition.
            original_cell_val = cell_val # For displaying error message
            cell_val = parseFloat(cell_val.trim())

            if _.isNaN cell_val
                showErrorInSnackbarAndRevertState
                  dialog_state: modal_data.dialog_state
                  snackbar_message: "Invalid value \"#{original_cell_val}\" in line #{line_number} - should be a number. Import aborted."
                  snackbar_duration: 15000
                  problematic_row: line_number

                return false

            # Check valid range
            out_of_range = false
            if field_def.min?
              if cell_val < field_def.min
                out_of_range = true

            if field_def.max?
              if cell_val > field_def.max
                out_of_range = true

            if out_of_range
              showErrorInSnackbarAndRevertState
                dialog_state: modal_data.dialog_state
                snackbar_message: "Invalid #{field_def.label} value #{cell_val} in line #{line_number} (must be between #{field_def.min} and #{field_def.max}). Import aborted."
                problematic_row: line_number
              return false

            if field_id == "priority" && cell_val % 1 isnt 0
              cell_val = Math.round cell_val

            task[field_id] = cell_val

          # If we have a date field, check that the date is formatted properly, and transform to internal format
          else if isDateFieldDef(field_def)
            date_fields_date_format = modal_data.date_fields_date_format.get()
            if date_fields_date_format == "Others" # By not passing date format we let moment.js guess the date format (it's usually correct)
              moment_date = moment.utc cell_val
            else
              moment_date = moment.utc cell_val, date_fields_date_format
            if not moment_date.isValid()
              showErrorInSnackbarAndRevertState
                dialog_state: modal_data.dialog_state
                snackbar_message: "Invalid date format in line #{line_number}. Import aborted."
                problematic_row: line_number

              modal_data.date_fields_date_format.set null

              return false
            task[field_id] = moment_date.format("YYYY-MM-DD")

      if max_indent < indent_level
        max_indent = indent_level

      # Indent can't jump more than 1 indent level at once
      # and can't start with anything but 1
      if indent_level > last_indent + 1 or indent_level <= 0 or (last_indent == -1 and indent_level != 1) or indent_level < base_indent
        showErrorInSnackbarAndRevertState
          dialog_state: modal_data.dialog_state
          snackbar_message: "Invalid indentation at line #{line_number} - inconsistent indentation."
          snackbar_duration: 15000
          problematic_row: line_number

        return false

      last_indent = indent_level
      lines_to_add[row_index] =
        task: task
        indent_level: indent_level

    if task[JustdoPlanningUtilities.is_milestone_pseudo_field_id] == "true"
      if task.start_date? and task.end_date? and task.start_date != task.end_date
        showErrorInSnackbarAndRevertState
          dialog_state: modal_data.dialog_state
          snackbar_message: "Task #{task.title} at line #{line_number} is a milestone, it can only have the same Start Date and End Date."
          snackbar_duration: 15000
          problematic_row: line_number
        return false

      else if task.start_date? and not task.end_date?
        task.end_date = task.start_date

      else if task.end_date? and not task.start_date?
        task.start_date = task.end_date

    row_index += 1

  if not APP.justdo_clipboard_import.middlewares_queue_sync.run("pre-import", lines_to_add)
    return false

  gc = APP.modules.project_page.mainGridControl()
  task_paths_added = []
  import_progress = 0

  importLevel = (indent_level_to_import, mapSeriesCb) ->
    parent_id = modal_data.parent_task_id or "0"
    batches = {}  # parent_id: [tasks]
    for line_index, line of lines_to_add
      if line.indent_level == indent_level_to_import - 1
        parent_id = line.task_id

      if line.indent_level == indent_level_to_import
        if not batches[parent_id]?
          batches[parent_id] = []
        batches[parent_id].push line.task

    async_calls = []

    for parent_id, batch of batches
      do (parent_id, batch) ->
        async_calls.push (callback) ->
          if parent_id is "0"
            path_to_insert = "/"
          else
            path_to_insert = "/#{parent_id}/"

          gc._grid_data.bulkAddChild path_to_insert, batch, (err, result) ->
            import_progress += batch.length
            setProgressbarValue import_progress, line_number
            modal_data.import_helper_message.set "#{import_progress}/#{line_number}"
            if err?
              APP.collections.Tasks.find
                "jci:temp_import_id":
                  $in: _.map batch, (task) -> task["jci:temp_import_id"]
              ,
                fields:
                  _id: 1
              .forEach (task) ->
                task_paths_added.push path_to_insert + task._id
                return
            else
              # For undo if failure
              for item in result
                task_paths_added.push item[1] # item[1] is the path of added task
            callback err, result

            return

          return
        return

    async.parallelLimit async_calls, 5, (err, results) ->
      if not err?
        result_num = 0
        all_results = []
        for batch_result in results
          for item in batch_result
            all_results.push item[0]

        for index, line of lines_to_add
          if line.indent_level == indent_level_to_import
            line.task_id = all_results[result_num]
            result_num += 1

      mapSeriesCb(err, results)
      return

    return

  import_idx_to_task_id = (import_idx) ->
    if not import_idx_to_temp_import_id_map[import_idx]?
      return null

    return APP.collections.Tasks.findOne(
      "jci:temp_import_id": import_idx_to_temp_import_id_map[import_idx]
    ,
      fields:
        _id: 1
    )?._id

  temp_import_id_task_id = (temp_import_id) ->
    if _.isString temp_import_id
      return APP.collections.Tasks.findOne(
        "jci:temp_import_id": temp_import_id
      ,
        fields:
          _id: 1
      )?._id

    if _.isArray temp_import_id
      task_ids = APP.collections.Tasks.find(
        "jci:temp_import_id":
          $in: temp_import_id
      ,
        fields:
          _id: 1
      ).fetch()

      task_ids = _.map task_ids, (task) -> task._id

      return task_ids

  importDependencies = ->
    modal_data.import_helper_message.set "Importing dependencies..."
    custom_bulk_update_payload = {}
    for temp_import_id, deps_str of dependencies_strs
      if not (deps = APP.justdo_planning_utilities.parseDependenciesStr deps_str, project_id, import_idx_to_task_id)?
        line_number = temp_import_id.split("_L")[1]
        scrollToAndHighlightProblematicRow line_number
        throw new Meteor.Error "invalid dependency", "Invalid dependency (#{deps_str}) found in line #{line_number}"

      deps_payload = []
      for dep in deps
        dep_payload = [dep.task_id, dep.type]
        if dep.lag?
          dep_payload.push(dep.lag)
        deps_payload.push(dep_payload)

      custom_bulk_update_payload[temp_import_id_task_id(temp_import_id)] = deps_payload

    APP.justdo_planning_utilities.dependent_tasks_update_hook_enabled = false
    APP.modules.project_page.curProj().customCompoundBulkUpdate("deps-update", custom_bulk_update_payload, ->
      APP.justdo_planning_utilities.dependent_tasks_update_hook_enabled = true
    )

    return true

  importOwners = ->
    modal_data.import_helper_message.set "Importing Owners..."
    if _.isEmpty owner_id_to_temp_import_id_map
      return

    for user_id, temp_task_ids of owner_id_to_temp_import_id_map
      task_ids = temp_import_id_task_id temp_task_ids
      transfer_owner_modifier =
        $set:
          owner_id: user_id
          pending_owner_id: null
      APP.modules.project_page.curProj().bulkUpdate(task_ids, transfer_owner_modifier)

    return

  cleanUpDuplicatedManualValue = ->
    imported_columns_ids = _.map selected_columns_definitions, (col_def) -> col_def._id
    
    # First pick: get cols with grid dependency fields
    # Second pick: get cols that were imported
    schema_columns_with_auto_field_obj = _.pick gc.getSchemaExtendedWithCustomFields(), (col_schema) -> col_schema.grid_column_manual_and_auto_values_getter?
    schema_columns_with_auto_field_obj = _.pick schema_columns_with_auto_field_obj, imported_columns_ids
    # If imported cols doesn't include cols with grid dependency fields, simply return

    if _.isEmpty schema_columns_with_auto_field_obj
      return

    imported_tasks_with_auto_value_fields_query = 
      "jci:temp_import_id":
        $in: temp_import_ids
    auto_value_fields_and_dependencies = {}
    for col_id, col_schema of schema_columns_with_auto_field_obj
      _.extend auto_value_fields_and_dependencies, JustdoHelpers.fieldsArrayToInclusiveFieldsProjection col_schema.grid_dependencies_fields

    imported_task_ids = APP.collections.Tasks.find(imported_tasks_with_auto_value_fields_query, {fields: {_id: 1}}).map (task_doc) -> return task_doc._id

    # We observed that without the flush the planning utilities, for example, might not yet process the newly created
    # tasks to add the auto values to them, and, therefore the grid_column_manual_and_auto_values_getter might not return
    # the correct value.
    #
    # We force flush here before the grid data core's flush manager flushes (to avoid the wait to it).
    gc._grid_data._grid_data_core.flush()

    imported_tasks_with_auto_value_fields_and_dependencies = APP.collections.Tasks.find({_id: {$in: imported_task_ids}}, {fields: auto_value_fields_and_dependencies}).fetch()
    for col_id, col_schema of schema_columns_with_auto_field_obj
      tasks_with_same_manual_val_and_auto_val = []

      for imported_task in imported_tasks_with_auto_value_fields_and_dependencies
        {manual_value, auto_value} = col_schema.grid_column_manual_and_auto_values_getter imported_task
        if manual_value? and manual_value is auto_value
          tasks_with_same_manual_val_and_auto_val.push imported_task._id

      field_to_clear = if col_schema.grid_column_substitue_field? then col_schema.grid_column_substitue_field else col_id

      Meteor.call "cleanUpDuplicatedManualValue", tasks_with_same_manual_val_and_auto_val, field_to_clear


    return

  clearupTempImportId = (cb) ->
    Meteor.call "clearupTempImportId", temp_import_ids, cb

    return true

  undoImport = (trials = 0, show_err=false) ->
    # task_paths_added is reversed as we need to remove the tasks in the deepest level first

    paths_to_remove = new Set()

    for path_added in task_paths_added
      if paths_to_remove.has path_added
        continue

      paths_to_remove.add path_added
      
      # By TY -  The next 2 lines of code looks redundant to me and causes #11141, not sure if it is here for another reason, thus, commenting it out now
      # APP.modules.project_page.mainGridControl()._grid_data.each path_added, (section, item_type, item_obj, path) ->
      #   paths_to_remove.add path

    paths_to_remove = Array.from(paths_to_remove).reverse()

    APP.justdo_clipboard_import.middlewares_queue_sync.run "pre-undo-import", paths_to_remove

    APP.modules.project_page.gridControl()._grid_data.bulkRemoveParents paths_to_remove, (err) ->
      if err? and err.error != "unknown-path"
        if trials == 0
          undoImport 1  # Try again just in case the client database are not updated fast enough
        else if show_err
          error_text = "Undo failed."
          if err.reason?
            error_text = "#{err.reason}. #{error_text}"
          JustdoSnackbar.show
            text: error_text
            duration: 15000

      return

    return

  modal_data.import_helper_message.set "Importing..."
  async.mapSeries [1..max_indent], (n, callback) ->
    importLevel(n, callback)
  , (err, results) ->
    if err?
      showErrorInSnackbarAndRevertState
        dialog_state: modal_data.dialog_state
        snackbar_message: "#{err?.reason or "Incorrect dependenc(ies) found."}. Import aborted."
        snackbar_duration: 15000

      undoImport()

      return false

    try
      importDependencies()
      importOwners()
      cleanUpDuplicatedManualValue()
    catch err
      showErrorInSnackbarAndRevertState
        dialog_state: modal_data.dialog_state
        snackbar_message: "#{err.reason}. Import aborted."
        snackbar_duration: 15000

      undoImport()

      return false
    finally
      clearupTempImportId ->
        APP.justdo_planning_utilities.initTaskIdToInfo()
        return

    bootbox.hideAll()
    JustdoSnackbar.show
      text: "#{task_paths_added.length} task#{if task_paths_added.length > 1 then "s" else ""} imported."
      duration: 1000 * 60 * 2 # 2 mins
      actionText: "Undo"
      showDismissButton: true
      onActionClick: =>
        undoImport(0, true)
        JustdoSnackbar.close()
        return # end of onActionClick

    return # end of mapSeries call back

  return true

Template.justdo_clipboard_import_activation_icon.events
  "click .justdo-clipboard-import-activation": (e, tpl) ->
    # Exit multi-select mode if we are in one
    gc = APP.modules.project_page.gridControl()
    gc.exitMultiSelectMode()

    parent_task_id = JD.activeItemId()
    modal_data =
      dialog_state: new ReactiveVar ""
      clipboard_data: new ReactiveVar []
      parent_task_id: parent_task_id
      rows_to_skip_set: new ReactiveVar(new Set())
      getAvailableFieldTypes: getAvailableFieldTypes
      date_fields_date_format: new ReactiveVar(null)
      import_config_local_storage_key: getLocalStorageKey()
      import_helper_message: new ReactiveVar "Preparing..."

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_clipboard_import_input, modal_data)

    # Use task name if a task is selected; Use project name if isn't
    if parent_task_id?
      task_or_project_name = JustdoHelpers.taskCommonName(JD.activeItem(undefined, {allow_undefined_fields: true}), 80)
    else
      task_or_project_name = "#{JD.activeJustdo({title: 1})?.title}"

    dialog = bootbox.dialog
      title: """Import spreadsheet data as child tasks to <i>#{task_or_project_name}</i><div id="progressbar"></div>"""
      message: message_template.node
      animate: true
      scrollable: true
      className: "bootbox-new-design justdo-clipboard-import-dialog"

      onEscape: =>
        if modal_data.dialog_state.get() == "importing"
          JustdoSnackbar.show
            text: "Import in progress..."
            duration: 1000 * 20 # 20 secs
          return false

        return true

      buttons:
        Reset:
          label: "Reset"
          className: "btn-default justdo-import-clipboard-data-reset-button"
          callback: =>
            modal_data.dialog_state.set "wait_for_paste"
            modal_data.clipboard_data.set []
            modal_data.rows_to_skip_set.set(new Set())

            Meteor.defer ->
              $(".justdo-clipboard-import-paste-target").focus()

            return false

        Import:
          label: "Cancel"
          className: "btn-primary justdo-clipboard-import-main-button"
          callback: =>
            cp_data = modal_data.clipboard_data.get()
            if cp_data.length == 0
              return true
            number_of_columns = cp_data[0].length
            # This should not happen, but just in case
            if number_of_columns == 0
              return true

            result = getSelectedColumnsDefinitions()

            if (err = result.err)?
              JustdoSnackbar.show
                text: err.message
              return false

            selected_columns_definitions = result

            # Check that all columns are selected and return false if not the case
            if selected_columns_definitions.length < (number_of_columns)
              JustdoSnackbar.show
                text: "Please select all columns fields."
              return false

            # Manage dates - ask for input format
            date_column_found = false
            for column_def in selected_columns_definitions
              if isDateFieldDef(column_def)
                date_column_found = true
                break

            if date_column_found and not modal_data.date_fields_date_format.get()?
              options = JustdoHelpers.getAllowedDateFormatsWithExample({custom_date_formats: custom_allowed_dates_formats})

              bootbox.prompt
                title: "Please select source date format"
                animate: true
                className: "bootbox-new-design"
                inputType: "select"
                inputOptions: options
                value: getDefaultDateFormat()
                callback: (date_format) =>
                  if date_format?
                    modal_data.date_fields_date_format.set(date_format)
                    testDataAndImport modal_data, selected_columns_definitions

                    return true
            else
              testDataAndImport modal_data, selected_columns_definitions

            return false

    dialog.on "shown.bs.modal", (e) ->
      $(".justdo-clipboard-import-paste-target").focus()
      return
    return
