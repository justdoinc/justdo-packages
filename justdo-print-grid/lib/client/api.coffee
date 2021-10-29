_.extend JustdoPrintGrid.prototype,
  addPrintMode: ->
    #
    # Shortcuts
    #
    module = APP.modules.project_page

    gc = null   # Will be set to the current Grid Control object
    gcm = null  # upon entering to print mode.

    rows = []
    cols = []
    state_filter = []
    item_path = ""
    last_overflow = "hidden"

    #
    # Functions
    #
    getCurrentTaskPath = ->
      path = module.gridControl().getCurrentPath()
      return path

    getColumnsConfiguration = ->
      cols = []
      if $(".print-settings").length
        $(".print-settings li input:checked").each ->
          field = $(this).attr("field-name")
          cols.push "field": field
          return
      else
        cols = gc.getView()
      return cols

    resizePrintContent = ->
      $content = $(".print-content")
      $table = $(".print-content table")
      $print_grid = $(".print-grid-mode-overlay")

      if $table.width() > $content.width()
        $content.width $table.width()
      return

    createPrintHtml = (cols, rows) ->

      # Getting Max and Min levels of tasks
      max_level = 0
      min_level = 100000

      for i in [0...rows.length]
        if rows[i][0]._id?
          if rows[i][1] > max_level
            max_level = rows[i][1]
          if rows[i][1] < min_level
            min_level = rows[i][1]

      # if min_level > 0 tasks need level reduction
      if min_level > 0
        for i in [0...rows.length]
          rows[i][1] = rows[i][1] - min_level

        min_level = 0

      # Create Table header
      table_header = []
      for i in [0...cols.length]
        table_header.push
          "class": "table-header"
          "value": JustdoHelpers.xssGuard(gc.getSchemaExtendedWithCustomFields()[cols[i].field].label, {allow_html_parsing: true, enclosing_char: ''})
          "colspan": 1

      # Add class for first element in header
      table_header[0].class = "table-header-first"

      # At the minimum we need two columns to present the task id, each indentation level adds another column
      table_header[0].colspan = max_level + 2

      # Create Thead
      name = JustdoHelpers.xssGuard(JustdoHelpers.displayName(Meteor.user()))
      project_name = JustdoHelpers.xssGuard JD.activeJustdo({title: 1})?.title
      thead_colspan = cols.length + max_level + 1
      tab_title = JustdoHelpers.xssGuard gcm.getActiveTab().getTabTitle()

      thead = """
        <thead>
          <tr>
            <td colspan="#{thead_colspan}">
              <div class="thead-logo">
                <img src="/layout/logos-ext/justdo_logo_with_text_normal.png" alt="justDo">
              </div>
              <div class="thead-info">
                <p>#{project_name} :: <span>#{tab_title}</span></p>
                <p>Printed <span>#{moment().format("DD/MM/YYYY")}</span> by <span>#{name}</span></p>
              </div>
      """

      if state_filter.length
        thead += """<div class="thead-filters"><p>State: <span>#{state_filter.join(", ")}</span></p></div>"""

      thead += "</td><tr></thead>"

      if rows.length > 0
        # Getting all visible values from grid_tree
        matrix = []
        for i in [0...rows.length]
          cell = []
          item_obj = rows[i][0]
          path = rows[i][2]
          if item_obj._id?
            for j in [0...cols.length]

              field = cols[j].field
              val = item_obj[cols[j].field]
              format_value = formatWithPrintFormatter(item_obj._id, field, val, item_obj, path) or ""

              if field == "state"
                format_value = """<div class="d-flex">#{format_value}</div>"""

              cell.push
                "class": "text #{field}"
                "value": format_value
                "colspan": 1
          else
            cell.push
              "class": "section-title"
              "value": JustdoHelpers.nl2br(JustdoHelpers.xssGuard(item_obj.title) or "")
              "colspan": cols.length + max_level + 1

          matrix.push cell

        # Add td colspan, owner name, task seqId, blocks
        # Block it's a table cell which can contain hierarchy lines or be empty

        for i in [0...matrix.length]
          tr = matrix[i]

          if rows[i][0]._id?
            tr[0].colspan = max_level + 1 - (rows[i][1])
            user = Meteor.users.findOne(rows[i][0].owner_id)
            if user?
              tr[0].value += """<br><span class="task-info">#{JustdoHelpers.xssGuard(JustdoHelpers.displayName(user))}</span>"""

            tr[0].class = "task"

            number_cell =
              "class": "number"
              "value": rows[i][0].seqId || " "
              "level": rows[i][1]
              "colspan": 1

            if rows[i][3] > 0 and number_cell.value != " "
              number_cell.value += """<div class="yy-f"></div>"""

            if number_cell.value != " "
              tr.unshift number_cell
            else
              tr[0].colspan += 1
              tr[0].class += " no-number"

            for j in [0...rows[i][1]]
              tr.unshift
                "class": "block"
                "value": ""
                "colspan": 1

        # Create final table array and add tableHeader's
        # If rows[i] is section-item, add table_header after
        table = []

        for i in [0...matrix.length]
          if rows[i][0]._id?
            table.push matrix[i]
          else
            table.push matrix[i], table_header

        # Set lines
        for i in [0...table.length]
          for j in [0...table[i].length]
            if table[i][j].class == "number" and table[i][j].level > min_level and table[i - 1][j].class != "table-header"
              if table[i][j - 1]
                table[i][j - 1].value = """<div class="yx"></div>"""

              for k in [i - 1...0]
                if table[k][j - 1]?
                  if table[k][j - 1].class != "number" and table[k][j - 1].class != "task no-number"
                    if !table[k][j - 1].value
                      table[k][j - 1].value += """<div class="yy"></div>"""
                    else if table[k][j - 1].value == """<div class="yx"></div>"""
                      table[k][j - 1].value += """<div class="y"></div>"""
                  else
                    break

        # If the first row has id, add header to the top becouse it's tree view
        if rows[0][0]._id?
          table.unshift table_header

      else
        table = []
        no_task = [{
          "class": "no-tasks",
          "value": "No tasks to show"
          "colspan": cols.length + max_level + 1
        }]
        table.push no_task

      # Create and append HTML Table
      table_html = """<table>#{thead}"""
      for tr in table
        table_html += "<tr>"
        for td in tr
          table_html += """<td class="#{td.class}" colspan="#{td.colspan}" dir="auto">#{td.value}</td>"""
        table_html += "</tr>"
      table_html += "</table>"

      $(".print-content").html table_html

      return

    enterPrintMode = (options) ->
      {item_path, expand_only, filtered_tree} = options

      # Append div.print-content to body
      $("body").append """<div class="print-grid-mode-overlay"><div class="print-content"></div></div>"""

      # Add overflow - auto to <html> to make it scrollable
      last_overflow = $("html").css("overflow")
      $("html").css "overflow", "auto"

      # Getting grid control module
      if not (gc = module.gridControl())?
        module.logger.error "Can't find grid control"
        return

      # Getting current displayed GridControl
      if not (gcm = module.getCurrentGcm())?
        module.logger.error "Can't find current grid control"
        return

      # Getting cols from getView
      cols = gc.getView()

      # Function to get English state name
      states = gc.schema.state.grid_values

      getStateTxt = (val) ->
        if states[val]
          states[val].txt
        else
          "Unknown state"

      # Create array with visible tasks and section-items
      grid_tree_rows = []

      if item_path != '/'
        parent_object = gc.getPathObjNonReactive(item_path)
        parent_level = GridData.helpers.getPathLevel(item_path)
        grid_tree_rows.push [parent_object, parent_level, item_path]

      gc._grid_data.each item_path, {expand_only: expand_only, filtered_tree: filtered_tree}, (section, item_type, item_obj, path, expand_state) ->
        item_level = GridData.helpers.getPathLevel(path)
        item = [item_obj, item_level, path, expand_state, section, item_type]
        grid_tree_rows.push item
        return

      # Remove section-items without children and create new rows array
      rows = []

      for i in [0...grid_tree_rows.length]
        if grid_tree_rows[i][0]._id? or (grid_tree_rows[i + 1]? and grid_tree_rows[i + 1][0]._id?)
          rows.push grid_tree_rows[i] # push element which has id or children with id


      # Items under section-item need one level reduction
      section_item_trigger = false

      for i in [0...rows.length]
        if rows[i][5] == "section-item" or (rows[i][0]._type? and rows[i][0]._type == "section-item")
          section_item_trigger = true

        if section_item_trigger and rows[i][5] != "section-item"
          rows[i][1] = rows[i][1] - 1

      # Getting active filters names
      state_filter = []

      for i in [0...cols.length]
        if cols[i].field == "state" and cols[i].filter
          for state in cols[i].filter
            state_filter.push getStateTxt(state)

      # Create and append print content HTML
      createPrintHtml(cols, rows)
      resizePrintContent()

      # Add min-height for print-content equal to window height
      min_height = $(window).height()
      $(".print-content").css "min-height": min_height + "px"

      $("body").addClass "print-grid-mode"

      # Create print and close buttons
      print_modal_buttons = """
        <div class="print-modal-buttons">
          <div class="print-tasks">
            <svg class="jd-icon jd-c-pointer">
              <use xlink:href="/layout/icons-feather-sprite.svg#printer"></use>
              <title>Print</title>
            </svg>
          </div>
          <div class="separator"></div>
          <div class="export-tasks">
            <svg class="jd-icon jd-c-pointer">
              <use xlink:href="/layout/icons-feather-sprite.svg#download"></use>
              <title>Export CSV</title>
            </svg>
          </div>
          <div class="separator"></div>
          <div class="print-mode-settings">
            <svg class="jd-icon jd-c-pointer">
              <use xlink:href="/layout/icons-feather-sprite.svg#settings"></use>
              <title>Columns settings</title>
            </svg>
          </div>
          <div class="separator"></div>
          <div class="close-print-grid-mode">
            <svg class="jd-icon jd-c-pointer">
              <use xlink:href="/layout/icons-feather-sprite.svg#x"></use>
            </svg>
          </div>
        </div>
      """

      # Append print buttons
      $(".print-grid-mode-overlay").append print_modal_buttons

      # Create print settings popup
      print_settings = """
        <div class="print-settings jd-p-075 shadow-lg">
          <div class="modal-header d-flex align-items-center">
            <div class="modal-title">Columns options</div>
            <button class="bootbox-close-button close">×</button>
          </div>
          <ul></ul>
          <div class="modal-footer">
            <label class="print-settings-select-all"><input type="checkbox">Select all</label>
            <button class="btn btn-primary print-settings-apply">Apply</button>
          </div>
        </div>
      """

      $(".print-grid-mode-overlay").append print_settings

      # Function return checked status of column
      checkVisibility = (property) ->
        checked = ""
        for item in cols
          if item.field == property
            checked = "checked"
        return checked

      openPrintSettings = _.once(->
        li = ""

        schema = gc.getSchemaExtendedWithCustomFields()
        for property of schema
          if schema[property]?.grid_visible_column == true
            label = schema[property].label
            checked_attr = checkVisibility(property)
            li += """<li>
                      <span class="sortable-aria">
                        <svg class="jd-icon"><use xlink:href="/layout/icons-feather-sprite.svg#more-vertical-double"></use></svg>
                      </span>
                      <label class="sortable-item"><input type="checkbox" #{checked_attr} field-name="#{JustdoHelpers.xssGuard(property)}"><div class="sortable-item-text">#{JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ''})}</div></label>
                     </li>
                  """

        $(".print-settings ul").html li
        $(".print-settings ul li").first().addClass "locked"
        $(".print-settings ul li.locked input").attr "disabled", true
        $(".print-settings ul li.locked label").removeClass "sortable-item"

        # Create sortable ul and fix first element to the top
        $(".print-settings ul").sortable
          handle: ".sortable-aria"
          items: "li:not(.locked)"
          change: ->
            locked_item = $(this).find(".locked")
            $(this).prepend $(locked_item).detach()
            return
        return
      )

      closePrintSettngs = ->
        $(".print-settings").hide()
        return

      # Open print settings
      $(".print-mode-settings").on "click", ->
        openPrintSettings()
        $(".print-settings").toggle()
        return

      # Close print settings
      $(".print-settings .close").on "click", ->
        closePrintSettngs()
        return

      # Select all columns
      $(".print-settings-select-all").on "click", (e) ->
        checked_status = $(e.currentTarget).find("input").is(":checked")

        if checked_status
          $(".print-settings .sortable-item input").prop("checked", true)
        else
          $(".print-settings .sortable-item input").prop("checked", false)

        return

      # Apply print settings
      $(".print-settings-apply").on "click", ->
        getColumnsConfiguration()
        createPrintHtml(cols, rows)
        resizePrintContent()
        closePrintSettngs()
        return

      # Close print mode by click outside of print-content
      $(".print-grid-mode-overlay").on "click", (event) ->
        if event.target.className == "print-grid-mode-overlay"
          exitPrintMode()
        return

      # Close print mode on press ESC
      $(document).on "keydown", (event) ->
        if event.keyCode == 27
          exitPrintMode()
        return

      # Close print mode
      $(".close-print-grid-mode").on "click", ->
        exitPrintMode()

        return

      # Print tasks
      $(".print-tasks").on "click", ->
        closePrintSettngs()
        window.print()
        return

      # Export tasks CSV
      $(".export-tasks").on "click", ->
        exportCSV()
        return

      return

    exportCSV = ->
      # Create header row
      headers_rows_ids = ["seqId", "title", "owner_id"]

      schema = gc.getSchemaExtendedWithCustomFields()

      for i in [1...cols.length]
        field_id = cols[i].field
        headers_rows_ids.push field_id

      headers_rows_labels = []
      for header_row_id in headers_rows_ids
        if header_row_id == "seqId"
          field_label = "#"
        else
          field_label =
            if (label = schema[header_row_id]?.label)? then label else header_row_id

        headers_rows_labels.push field_label

      headers_rows_labels.push "Task Level", "Task Path"

      rowsCSV = [headers_rows_labels]

      # Add task rows
      for i in [0...rows.length]
        row = rows[i]
        if row[0]._id? # Task or workload-user-header
          if row[5] in ["workload-user-header", "workload-term-header"]
            user_name = row[0].title
            user_name = "----- " + user_name.toUpperCase() + " -----"
            rowCSV = [" ", user_name]
          else
            user = Meteor.users.findOne(row[0].owner_id)
            if user?
              display_name = JustdoHelpers.xssGuard(JustdoHelpers.displayName(user))
            else
              display_name = "Unknown user"

            rowCSV = [row[0].seqId, row[0].title, display_name]

            for i in [1...cols.length]

              item_id = row[0]._id
              field_name = cols[i].field
              val = row[0][field_name]
              item_doc = row[0]
              path = row[2]

              rowCSV.push formatWithPrintFormatter(item_id, field_name, val, item_doc, path, true) or ""

            rowCSV.push row[1]+1, row[2]

        else # Section title
          section_title = JustdoHelpers.xssGuard(row[0].title)
          section_title = "----- " + section_title.toUpperCase() + " -----"
          rowCSV = [" ", section_title]

        rowsCSV.push rowCSV

      csv_string = ""
      rowsCSV.forEach (rowArray) ->
        row = _.map(rowArray, (val) -> '"' + String(if not val? then "" else val).replace(/"/g, '""') + '"').join(',')

        csv_string += row + '\u000d\n'

        return

      # Create file name
      project_name = JD.activeJustdo({title: 1})?.title
      tab_title = gcm.getActiveTab().getTabTitle()
      file_name = project_name + " - " + tab_title

      # If child task print - add parent task seqId, or the item title if non-collection item
      if item_path != "/"
        task_data = gc.getPathObjNonReactive(item_path)
        if gc._grid_data.getItemIsCollectionItem(gc._grid_data.getPathGridTreeIndex(item_path))
          file_name += " - Task ##{task_data.seqId}"
        else
          file_name += " - #{task_data.title}"

      file_name += ".csv"

      # universalBOM needs to force Excel use UTF-8 for CSV
      universalBOM = "\uFEFF"
      csv_string = universalBOM + csv_string

      if window.Blob && window.navigator.msSaveOrOpenBlob
        csv_blob_obj = new Blob([csv_string])

        window.navigator.msSaveOrOpenBlob(csv_blob_obj, file_name)
      else
        # Create invisible link to set file name
        encoded_uri = "data:text/csv;charset=utf-8," + encodeURIComponent(csv_string)
        download_link = document.createElement("a")
        download_link.target = '_blank'
        download_link.href = encoded_uri
        download_link.download = file_name

        document.body.appendChild(download_link)
        download_link.click()
        document.body.removeChild(download_link)

      return

    exitPrintMode = ->
      $(".print-grid-mode-overlay").remove()
      $("body").removeClass("print-grid-mode")
      $("html").css "overflow", last_overflow

      return

    hidePrintButtons = ->
      $(".print-modal-buttons").hide()
      return

    showPrintButtons = ->
      $(".print-modal-buttons").show()
      return

    formatWithPrintFormatter = (item_id, field, val, item_doc, path, format_for_csv=false) ->
      if not (field_schema_def = gc.getSchemaExtendedWithCustomFields()[field])?
        module.logger.error "Failed to find print formatter to field #{field}"

        return val


      if not (formatter_id = field_schema_def.grid_column_formatter)?
        module.logger.error "Failed to find print formatter to field #{field}"

        return val

      printFormatter = gc._print_formatters[formatter_id]
      if not format_for_csv
        if printFormatter.html_output is true
          xssGuard_options =
            allow_html_parsing: true
            enclosing_char: ""
        else
          xssGuard_options = {}

        pre_nl2br_content = JustdoHelpers.xssGuard(printFormatter(item_doc, field, path), xssGuard_options)

        if printFormatter.html_output is true
          # For html content, let the formatter developer set <br>s where appropriate.
          return pre_nl2br_content
        else
          return JustdoHelpers.nl2br(pre_nl2br_content)

      else
        formatter_content = printFormatter(item_doc, field, path)
        if printFormatter.html_output is true
          # Html content, which in the context of a csv file, is meaningless.
          #
          # In such cases, we strip away all the html tags from the formatter output
          return formatter_content.replace(/(<([^>]+)>)/ig, "").trim()
        else
          return formatter_content

    #
    # Main
    #
    JD.registerPlaceholderItem "print-button",
      data:
        template: "print_menu_button"
        template_data: {}

      domain: "project-right-navbar"
      position: 350

    Template.print_menu_button.helpers
      printDropdownBottomItems: ->
        return JD.getPlaceholderItems("print-dropdown-bottom")

    Template.print_menu_button.events
      "click .print-dropdown": ->
        path = getCurrentTaskPath()
        if path?
          $(".selected-task-section").css "display", "block"
        else
          $(".selected-task-section").css "display", "none"
        return

      # Print visible tasks
      "click .print-dropdown .visible-tasks": ->
        item_path = "/"
        enterPrintMode
          item_path: item_path
          expand_only: true
          filtered_tree: true
        return

      # Print all tasks
      "click .print-dropdown .all-tasks": ->
        item_path = "/"
        enterPrintMode
          item_path: item_path
          expand_only: false
          filtered_tree: true
        return

      # Print visible sub-tasks
      "click .print-dropdown .visible-sub-tasks": ->
        if getCurrentTaskPath()?
          item_path = getCurrentTaskPath()
          enterPrintMode
            item_path: item_path
            expand_only: true
            filtered_tree: true
        return

      # Print all sub-tasks
      "click .print-dropdown .all-sub-tasks": ->
        if getCurrentTaskPath()?
          item_path = getCurrentTaskPath()
          enterPrintMode
            item_path: item_path
            expand_only: false
            filtered_tree: true
        return

      # Print visible sub-tasks
      "click .download-as-png": ->
        setup = ->
          $("body").append """<div class="download-grid-overlay">
            <div class="download-grid-title">
              #{JustdoHelpers.xssGuard(JD.activeJustdo({title: 1}).title)}
            </div>
          </div>"""

          $active_tab = $(".grid-control-tab.active")
          $cloned_tab = $active_tab.clone()

          # Critical to find the width before we hide the global-wrapper, otherwise
          # width will be 0
          grid_canvas_width = $active_tab.find(".grid-canvas").width()
          $cloned_tab.find(".slick-viewport").width grid_canvas_width
          $cloned_tab.find(".slick-header").width grid_canvas_width

          $("html").addClass "download-grid-on"
          $cloned_tab.appendTo ".download-grid-overlay"

          svg_elements = $cloned_tab.find("svg")

          for svg in svg_elements
            if not (svg_id = $(svg).find("use").attr("xlink:href")?.split("#")[1])?
              continue
            
            svg_icon = null

            if svg_id == "minus"
              svg_icon = """
              <div style="border: 1px solid; display: flex;">
                <svg style="border: none;" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-minus">
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
              </div>
              """

            if svg_id == "plus"
              svg_icon = """
              <div style="border: 1px solid; display: flex;">
                <svg style="border: none;" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-plus">
                  <line x1="12" y1="5" x2="12" y2="19"></line>
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                </div>
              """

            if svg_id == "arrow-right"
              svg_icon = """
              <div style="border: 1px solid; display: flex;">
                <svg style="border: none;" xmlns="http://www.w3.org/2000/svg" width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-arrow-right">
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                  <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
                </div>
              """

            if svg_id == "jd-alert"
              svg_icon = """
              <div style="border: 1px solid; display: flex;">
                <svg style="border: none;" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather">
                  <line x1="12" y1="4" x2="12" y2="12"></line><line x1="12" y1="20" x2="12" y2="20"></line>
                </svg>
                </div>
              """

            $(svg).replaceWith(svg_icon)

          user_avatars = $cloned_tab.find(".grid-tree-control-user")

          for avatar in user_avatars
            user_img = $(avatar).find(".grid-tree-control-user-img")

            # if image src has "http" it means user has uploaded avatar that we need to replace
            if user_img.attr("src").substring(0,4) == "http"
              initials_avatar = $(avatar).find("img").attr("alt").match(/\b(\w)/g).join("")

              user_img.replaceWith("""<div style="width: inherit;
                                                         height: inherit;
                                                         background-color: #03a9f4;
                                                         border-radius: 100%;
                                                         display: flex;
                                                         align-items: center;
                                                         justify-content: center;
                                                         line-height: 100%;
                                                         color: white;
                                                         font-size: 14px;">#{initials_avatar}</div>""")

          return

        destroy = ->
          $("html").removeClass "download-grid-on"

          $(".download-grid-overlay").remove()

          return

        setup()

        html2canvas($(".download-grid-overlay").get(0)).then (canvas) =>
          destroy()

          link = document.createElement('a')

          link.download = "justdo-export.png"
          link.href = canvas.toDataURL("image/png;base64")

          if document.createEvent
            e = document.createEvent("MouseEvents")
            e.initMouseEvent "click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null
            link.dispatchEvent e
          else if link.fireEvent
            link.fireEvent "onclick"

        return

    # Hide and Show print buttons. Detecting browser print event for Chrome 9+ (Safari 5+ ???)
    if window.matchMedia
      mediaQueryList = window.matchMedia("print")
      mediaQueryList.addListener (mql) ->
        if mql.matches
          hidePrintButtons()
        else
          showPrintButtons()
        return

    # Hide and Show print buttons. Detecting browser print event for IE 5+, Firefox 6+
    window.onbeforeprint = hidePrintButtons
    window.onafterprint = showPrintButtons

    # Close print dropdown on click outside - ?????
    $("#grid-control-main").on "click", ->
      $(".print-dropdown").removeClass "open"
      return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
