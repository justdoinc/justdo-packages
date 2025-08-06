clicked_since_mouse_enter = false

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  project_page_module.setNullaryOperation "changeRowStyle",
    human_description: "Change Font Style"

    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#jd-a"/></svg>"""

    op: (gc) ->
      task = gc.getCurrentPathObj()

      style = {}

      if task["jrs:style"]?
        style = task["jrs:style"]

      # first click after mouseenter - clean style if exists.
      if (clicked_since_mouse_enter and (style.bold? == true or style.underline? == true or style.italic? == true))
        style = {}
      else
        if not style.bold? or style.bold == false
          style.bold = true
        else
          delete style.bold
          if not style.underline? or style.underline == false
            style.underline = true
          else
            delete style.underline
            if not style.italic? or style.italic == false
              style.italic = true
            else
              delete style.italic

      clicked_since_mouse_enter = false

      APP.justdo_rows_styling.tasks_collection.update(task._id, {$set: {"jrs:style": style}})

      return

    prereq: (gc) ->
      return gc._opreqActivePathIsCollectionItem(gc._opreqNotMultiSelectMode(gc._opreqUnlocked(gc._opreqGridReady())))

  Template.rows_styling_control.helpers
    showSection: ->
      cur_project = project_page_module.curProj()

      if not cur_project?
        return false

      return cur_project.isCustomFeatureEnabled JustdoRowsStyling.project_custom_feature_id

  Template.project_operations_change_row_style.events
    mouseenter: ->
      clicked_since_mouse_enter = true

      return
