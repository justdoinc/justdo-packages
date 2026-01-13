loadSavedImportConfig = (tpl) ->
  saved_import_config = amplify.store tpl.data.import_config_local_storage_key
  if saved_import_config?
    # if ({rows} = saved_import_config)?
    #   for row_index in rows
    #     $(".import-row-checkbox[row-index=#{row_index}]").click()
    if ({cols} = saved_import_config)?
      $(".justdo-clipboard-import-input-selector").each (i) ->
        $(@).find("a[field-id='#{cols[i]}']").click()

        return
  return

# Unified parsing function using SheetJS XLSX library
# Supports CSV text, HTML strings, and binary spreadsheet data
# Uses chunked processing to avoid blocking the main thread
# Callback signature: (err, rows) - Node-style callback
parseSpreadsheetData = (data, options = {}, callback) ->
  # Options:
  #   type: "string" (for CSV/HTML text) or "array" (for binary XLSX/XLS)
  #   tpl: template instance (required for setting dialog_state on error)
  type = options.type or "string"
  tpl = options.tpl

  JustdoXlsx.requireXlsx (XLSX) ->
    try
      workbook = XLSX.read data, {type: type}

      # Get the first sheet
      first_sheet_name = workbook.SheetNames[0]
      worksheet = workbook.Sheets[first_sheet_name]

      if not worksheet?
        callback null, []
        return

      # Convert to 2D array with all values as strings
      rows = XLSX.utils.sheet_to_json worksheet, {header: 1, raw: false, defval: ""}

      # For small datasets, process synchronously
      if rows.length < 500
        filtered_rows = processRowsSync rows
        callback null, filtered_rows
        return

      # For large datasets, use chunked processing to avoid blocking UI
      processRowsChunked rows, (result) ->
        callback null, result
        return
    catch err
      tpl?.data.dialog_state.set "wait_for_paste"
      callback err, null
    return

  return

# Synchronous row processing for small datasets
processRowsSync = (rows) ->
  longest_row_length = 0
  filtered_rows = []
  for row in rows
    # Check if row has any non-empty cells
    has_content = false
    for cell in row
      if cell? and String(cell).trim().length > 0
        has_content = true
        break
    if has_content
      # Convert all cells to strings
      string_row = []
      for cell in row
        if cell?
          string_row.push String(cell)
        else
          string_row.push ""
      filtered_rows.push string_row
      if string_row.length > longest_row_length
        longest_row_length = string_row.length

  # Normalize row lengths
  for row in filtered_rows
    while row.length < longest_row_length
      row.push ""

  return filtered_rows

# Chunked row processing for large datasets
# Processes rows in batches, yielding to the main thread periodically
processRowsChunked = (rows, callback) ->
  chunk_size = 500
  current_index = 0
  longest_row_length = 0
  filtered_rows = []

  processChunk = ->
    end_index = Math.min(current_index + chunk_size, rows.length)

    while current_index < end_index
      row = rows[current_index]
      # Check if row has any non-empty cells
      has_content = false
      for cell in row
        if cell? and String(cell).trim().length > 0
          has_content = true
          break
      if has_content
        # Convert all cells to strings
        string_row = []
        for cell in row
          if cell?
            string_row.push String(cell)
          else
            string_row.push ""
        filtered_rows.push string_row
        if string_row.length > longest_row_length
          longest_row_length = string_row.length
      current_index += 1

    if current_index < rows.length
      # Yield to main thread before processing next chunk
      setTimeout processChunk, 0
    else
      # All rows processed, normalize lengths and return
      for row in filtered_rows
        while row.length < longest_row_length
          row.push ""
      callback filtered_rows
    return

  # Start processing first chunk
  processChunk()
  return

processFileData = (tpl, rows) ->
  if rows.length == 0
    tpl.data.dialog_state.set "wait_for_paste"
    JustdoSnackbar.show
      text: TAPi18n.__ "clipboard_import_file_empty"
    return

  if rows.length > JustdoClipboardImport.import_limit
    tpl.data.dialog_state.set "wait_for_paste"
    JustdoSnackbar.show
      text: TAPi18n.__ "clipboard_import_too_many_rows", {limit: JustdoClipboardImport.import_limit}
    return

  tpl.data.clipboard_data.set rows
  tpl.data.dialog_state.set "has_data"
  Tracker.afterFlush ->
    loadSavedImportConfig tpl
    return
  return

handleFileUpload = (tpl, file) ->
  if not file?
    return

  file_name = file.name.toLowerCase()
  file_extension = file_name.split(".").pop()

  if file_extension not in ["csv", "xlsx", "xls"]
    JustdoSnackbar.show
      text: TAPi18n.__ "clipboard_import_unsupported_file_type"
    return

  # Show parsing state immediately to provide user feedback
  tpl.data.dialog_state.set "parsing"

  reader = new FileReader()

  reader.onerror = ->
    tpl.data.dialog_state.set "wait_for_paste"
    JustdoSnackbar.show
      text: TAPi18n.__ "clipboard_import_file_read_error"
    return

  # XLSX/XLS files are read as binary array
  reader.onload = (e) ->
    # Defer parsing to allow UI to update with loading state
    setTimeout ->
      array_buffer = e.target.result
      parseSpreadsheetData new Uint8Array(array_buffer), {type: "array", tpl: tpl}, (err, rows) ->
        if err
          console.error "File parsing error:", err
          JustdoSnackbar.show
            text: TAPi18n.__ "clipboard_import_file_parse_error"
          return
        processFileData tpl, rows
        return
      return
    , 0
    return
  reader.readAsArrayBuffer file

  return

bindTargetToPaste = (tpl) ->
  $(".justdo-clipboard-import-dialog").bind "paste", (e) ->
    e.stopPropagation()
    e.preventDefault()
    clipboard_data = e.originalEvent.clipboardData

    # Show parsing state immediately
    tpl.data.dialog_state.set "parsing"

    # Get clipboard data before deferring
    html_data = if "text/html" in clipboard_data.types then clipboard_data.getData("text/html") else null
    text_data = if "text/plain" in clipboard_data.types then clipboard_data.getData("text/plain") else null

    # Defer processing to allow UI to update
    setTimeout ->
      handleClipboardParsing tpl, html_data, text_data
      return
    , 0

    return

  return

# Handle clipboard data parsing with async support
handleClipboardParsing = (tpl, html_data, text_data) ->
  parseAndProcess = (data, fallback_data) ->
    parseSpreadsheetData data, {type: "string", tpl: tpl}, (err, rows) ->
      if err
        console.error "Clipboard parsing error:", err
        if fallback_data?
          parseAndProcess fallback_data, null
        else
          JustdoSnackbar.show
            text: TAPi18n.__ "clipboard_import_cant_find_tabular_data"
        return

      if rows.length == 0 and fallback_data?
        # Try fallback data
        parseAndProcess fallback_data, null
        return

      if rows.length == 0
        tpl.data.dialog_state.set "wait_for_paste"
        JustdoSnackbar.show
          text: TAPi18n.__ "clipboard_import_cant_find_tabular_data"
        return

      # Limit max number of rows to import
      if rows.length > JustdoClipboardImport.import_limit
        tpl.data.dialog_state.set "wait_for_paste"
        JustdoSnackbar.show
          text: TAPi18n.__ "clipboard_import_too_many_rows", {limit: JustdoClipboardImport.import_limit}
        return

      tpl.data.clipboard_data.set rows
      tpl.data.dialog_state.set "has_data"
      Tracker.afterFlush ->
        loadSavedImportConfig tpl
        return
      return
    return

  # Try HTML first (best for Excel/Google Sheets), then fall back to plain text
  if html_data?
    parseAndProcess html_data, text_data
  else if text_data?
    parseAndProcess text_data, null
  else
    tpl.data.dialog_state.set "wait_for_paste"
    JustdoSnackbar.show
      text: TAPi18n.__ "clipboard_import_cant_find_tabular_data"
  return

Template.justdo_clipboard_import_input.onCreated ->
  self = @

  @getAvailableFieldTypes = @data.getAvailableFieldTypes
  @isDragging = new ReactiveVar false

  Meteor.defer ->
    self.data.dialog_state.set "wait_for_paste"

    return

  @autorun =>
    # All buttons should be enabled by default.
    $(".justdo-clipboard-import-main-button, .justdo-import-clipboard-data-reset-button, .col-def-selector, .import-row-checkbox, .justdo-clipboard-import-dialog .close").prop "disabled", false
    state = Template.instance().data.dialog_state.get()

    if state == "wait_for_paste"
      $(".justdo-clipboard-import-main-button").html TAPi18n.__("cancel")
      $("#progressbar").hide()
      Meteor.defer =>
        bindTargetToPaste self
        return
    else if state == "parsing"
      # Disable buttons while parsing to prevent user interaction
      $(".justdo-clipboard-import-main-button, .justdo-import-clipboard-data-reset-button, .col-def-selector, .import-row-checkbox, .justdo-clipboard-import-dialog .close").prop "disabled", true
      $(".justdo-clipboard-import-main-button").html TAPi18n.__("cancel")
      $("#progressbar").hide()
    else if state == "has_data"
      $(".justdo-clipboard-import-main-button").html TAPi18n.__("import")
    else if state == "importing"
      $(".justdo-clipboard-import-main-button, .justdo-import-clipboard-data-reset-button, .col-def-selector, .import-row-checkbox, .justdo-clipboard-import-dialog .close").prop "disabled", true
      $(".justdo-clipboard-import-main-button").prop "disabled", true
    else
      $(".justdo-clipboard-import-main-button").html TAPi18n.__("cancel")
      $("#progressbar").hide()
    return

  return

Template.justdo_clipboard_import_input.helpers
  waitingForPaste: -> Template.instance().data.dialog_state.get() is "wait_for_paste"

  isParsing: -> Template.instance().data.dialog_state.get() is "parsing"

  pasteTargetPlaceholder: -> "clipboard_import_placeholder_msg"

  isDragging: -> Template.instance().isDragging.get()

  hasData: -> Template.instance().data.dialog_state.get() in ["has_data", "importing"]

  importing: -> Template.instance().data.dialog_state.get() is "importing"

  importHelperMessage: -> Template.instance().data.import_helper_message.get()

  rows: ->
    return Template.instance().data.clipboard_data.get()

  numberOfColumns: ->
    return [1..Template.instance().data.clipboard_data.get()[0].length]

  importRow: (index) ->
    rows_to_skip = Template.instance().data.rows_to_skip_set.get()
    if rows_to_skip.has "#{index}"
      return false
    return true

  importLimit: -> JustdoClipboardImport.import_limit

  isUserObject: (cell_data) -> _.isObject(cell_data) and cell_data.user_obj?

Template.justdo_clipboard_import_input.events
  "keyup .justdo-clipboard-import-paste-target": (e, tpl) ->
    $(".justdo-clipboard-import-paste-target").val("")

    return false

  "change .import-row-checkbox": (e, tpl) ->
    rows_to_skip = tpl.data.rows_to_skip_set.get()

    if e.target.checked
      rows_to_skip.delete e.target.getAttribute("row-index")
    else
      rows_to_skip.add e.target.getAttribute("row-index")

    tpl.data.rows_to_skip_set.set rows_to_skip

    return

  "dragenter .justdo-clipboard-import-drop-zone": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    tpl.isDragging.set true
    return

  "dragover .justdo-clipboard-import-drop-zone": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    tpl.isDragging.set true
    return

  "dragleave .justdo-clipboard-import-drop-zone": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    # Only set dragging to false if we're leaving the drop zone entirely
    # Check if the related target is inside the drop zone
    related_target = e.relatedTarget
    drop_zone = e.currentTarget
    if not drop_zone.contains(related_target)
      tpl.isDragging.set false
    return

  "drop .justdo-clipboard-import-drop-zone": (e, tpl) ->
    e.stopPropagation()
    e.preventDefault()
    tpl.isDragging.set false

    files = e.originalEvent.dataTransfer.files
    if files.length > 0
      handleFileUpload tpl, files[0]

    return

  "change .justdo-clipboard-import-file-input": (e, tpl) ->
    files = e.target.files
    if files.length > 0
      handleFileUpload tpl, files[0]
    # Reset the input so the same file can be selected again
    e.target.value = ""
    return
