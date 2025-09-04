Template.print_menu_button.helpers
  taskIsSelectedNotInMultiSelectMode: ->
    if not (gc = APP.modules.project_page.gridControl())?
      return false

    return not gc.isMultiSelectMode() and gc.getCurrentPath()

  printDropdownBottomItems: ->
    return JD.getPlaceholderItems("print-dropdown-bottom")

Template.print_menu_button.events
  # Print visible tasks
  "click .print-dropdown .visible-tasks": (e, tpl) ->
    item_path = "/"
    tpl.data.enterPrintMode
      item_path: item_path
      expand_only: true
      filtered_tree: true
    return

  # Print all tasks
  "click .print-dropdown .all-tasks": (e, tpl) ->
    item_path = "/"
    tpl.data.enterPrintMode
      item_path: item_path
      expand_only: false
      filtered_tree: true
    return

  # Print visible sub-tasks
  "click .print-dropdown .visible-sub-tasks": (e, tpl) ->
    if tpl.data.getCurrentTaskPath()?
      item_path = tpl.data.getCurrentTaskPath()
      tpl.data.enterPrintMode
        item_path: item_path
        expand_only: true
        filtered_tree: true
    return

  # Print all sub-tasks
  "click .print-dropdown .all-sub-tasks": (e, tpl) ->
    if tpl.data.getCurrentTaskPath()?
      item_path = tpl.data.getCurrentTaskPath()
      tpl.data.enterPrintMode
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
