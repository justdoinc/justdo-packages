loadSavedImportConfig = (tpl) ->
  saved_import_config = amplify.store tpl.data.import_config_local_storage_key
  if saved_import_config?
    # if ({rows} = saved_import_config)?
    #   for row_index in rows
    #     $(".import-row-checkbox[row-index=#{row_index}]").click()
    if ({cols} = saved_import_config)?
      $(".justdo-clipboard-import-input-selector").each (i) ->
        $(this).find("a[field-id=#{cols[i]}]").click()
  return

bindTargetToPaste = (tpl)->
  $(".justdo-clipboard-import-paste-target").bind "paste", (e) ->
    e.stopPropagation()
    e.preventDefault()
    clipboard_data = e.originalEvent.clipboardData
    if ("text/html" in clipboard_data.types)
      data = clipboard_data.getData("text/html")
      data_text = clipboard_data.getData("text/plain").split("\r\n").map (row) -> row.split "\t"

      # Info about why we use [^\x05] can be found on: https://bugzilla.mozilla.org/show_bug.cgi?id=1579867
      tr_reg_exp = /<\s*tr[^>]*>([^\x05]*?)<\s*\/\s*tr>/g
      td_reg_exp = /<\s*td[^>]*>([^\x05]*?)<\s*\/\s*td>/g
      longest_row_length = 0
      rows = []
      processing_row_number = 0
      while ((tr = tr_reg_exp.exec(data)) != null)
        cells = []
        row_length = 0
        all_cells_are_empty = true
        processing_row_number += 1
        processing_column_number = 0
        while ((td = td_reg_exp.exec(tr[1])) != null)
          processing_column_number += 1
          cell = td[1]

          cell = cell.replace /\r\n/g, ""
          cell = cell.replace /<br\/?>/g, "\n"
          cell = cell.replace /&quot;/g , '"'
          cell = cell.replace /&#39;/g, "'"
          cell = cell.replace /&nbsp;/g, " "
          cell = cell.replace /&amp;/g, "&"

          # catch all html tags
          cell = cell.replace(/<span[^\x05]+?style=['"]mso-spacerun:yes['"]>[^\x05]+?<\/span>/g, "")
          cell = cell.replace /<[^>]+>/g, ""

          cell = cell.replace /&lt;/g, "<"
          cell = cell.replace /&gt;/g, ">"

          all_hashes_regexp = /#+$/

          if (all_hashes_regexp.test cell)
            # Copying cell value from Excel with very short cell length might yield "#####"
            # We'll use the value from text (instead of from html) for the actual value in those cases
            cell_from_text = data_text[processing_row_number-1][processing_column_number-1]
            if (cell isnt cell_from_text)
              cell = cell_from_text

          cells.push cell

          if cell.trim().length > 0
            all_cells_are_empty = false
            row_length = processing_column_number

          if (colspan = $(td[0]).attr("colspan"))?
            colspan = parseInt colspan, 10
            colspan -= 2
            for i in [0..colspan]
              cells.push ""
              processing_column_number += 1

        if not all_cells_are_empty
          rows.push cells
          if longest_row_length < row_length
            longest_row_length = row_length

      #limit max number of rows to import
      if rows.length > JustdoClipboardImport.import_limit
        JustdoSnackbar.show
          text: "Too many rows, you may copy up to #{JustdoClipboardImport.import_limit} rows."
        return

      #trim all rows according to the longest row. This handles cases where the entire row is copied to
      #the clipboard
      for row_number of rows
        rows[row_number] = rows[row_number].slice 0, longest_row_length

      if rows.length > 0
        tpl.data.clipboard_data.set rows
        tpl.data.dialog_state.set "has_data"
        $(".justdo-clipboard-import-main-button").html("Import")
        Tracker.afterFlush ->
          loadSavedImportConfig tpl
          return
      else
        JustdoSnackbar.show
          text: "Couldn't find tabular information in the clipboard."

    return

  return

Template.justdo_clipboard_import_input.onCreated ->
  self = @

  @getAvailableFieldTypes = @data.getAvailableFieldTypes

  Meteor.defer ->
    self.data.dialog_state.set "wait_for_paste"

    return

  @autorun =>
    state = Template.instance().data.dialog_state.get()

    if state == "wait_for_paste"
      $(".justdo-clipboard-import-paste-target").css("display", "")
      $(".justdo-clipboard-import-table").css("display", "none")

      Meteor.defer ->
        bindTargetToPaste self

        return

    else if state == "has_data"
      $(".justdo-clipboard-import-paste-target").css("display", "none")
      $(".justdo-clipboard-import-table").css("display", "")
    else
      $(".justdo-clipboard-import-paste-target").css("display", "none")
      $(".justdo-clipboard-import-table").css("display", "none")
    return
  return

Template.justdo_clipboard_import_input.helpers
  rows: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []

    return Template.instance().data.clipboard_data.get()

  numberOfColumns: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []

    return [1..Template.instance().data.clipboard_data.get()[0].length]

  importRow: (index) ->
    rows_to_skip = Template.instance().data.rows_to_skip_set.get()
    if rows_to_skip.has "#{index}"
      return false
    return true

  importLimit: -> JustdoClipboardImport.import_limit

  isUserObject: (cell_data) -> _.isObject(cell_data) and cell_data.user_obj?

Template.justdo_clipboard_import_input.events
  "keyup .justdo-clipboard-import-paste-target": (e, tpl)->
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

    return
