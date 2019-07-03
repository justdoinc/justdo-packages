textualFormat = (grid_control, path, field)->
  field_state =
    APP.justdo_checklist_field.getFieldValueForGridControlPath(grid_control, path, field)

  if _.isArray field_state
    if field_state[0] == field_state[1] == 0
      return "---"
    else
      return "#{field_state[1]}/#{field_state[0]}"

  if field_state == -1
    return "N/A"
  else if field_state == 0
    return ""
  else
    return "✓"

format = (grid_control, path, field)->
  field_state =
    APP.justdo_checklist_field.getFieldValueForGridControlPath(grid_control, path, field)

  if _.isArray field_state
    if field_state[0] == field_state[1] == 0
      return """<div class="grid-formatter">---</div>"""
    else
      percent = field_state[1] / field_state[0] * 100
      return """
          <div class="grid-formatter">
            <div class="progress" style="margin-bottom: 0px">
              <div class="progress-bar" role="progressbar" style="width: #{percent}%; color: #000000; background: #9aec9d" aria-valuenow="#{percent}" aria-valuemin="0" aria-valuemax="100">#{field_state[1]}/#{field_state[0]}</div>
            </div>
          </div>
        """

  cursor = "cursor: pointer"
  if field_state == -1
    html = "N/A"

    if not APP.modules.project_page?.curProj()?.isAdmin()
      cursor = ""
  else if field_state == 0
    html = """<i class="fa fa-square-o" aria-hidden="true"></i>"""
  else
    html = """<i class="fa fa-check-square-o" aria-hidden="true"></i>"""

  return """<div class="grid-formatter checklist-field-formatter" style="#{cursor}">#{html}</div>"""

allowNaOnCurrentProject = -> APP.modules.project_page?.curProj()?.isAdmin()

GridControl.installFormatter CustomJustdoCumulativeSelect.custom_field_formatter_id,
  invalidate_ancestors_on_change: "structure-and-content"

  slick_grid: ->
    {grid_control, field, path} = @getFriendlyArgs()

    return format grid_control, path, field

  slick_grid_jquery_events: [
    {
      args: ["click", ".checklist-field-formatter"]
      handler: (e) ->
        APP.justdo_checklist_field.toggleItemState(@, @getEventPath(e), @getEventFormatterDetails(e).field_name, allowNaOnCurrentProject())

        return
    }
  ]

  print: (doc, field, path) ->
    {grid_control, path, field} = @getFriendlyArgs()

    return textualFormat grid_control, path, field

# Read: Note regarding editor/formatter in the README for why we have an editor at all.
GridControl.installEditor CustomJustdoCumulativeSelect.custom_field_editor_id,
  init: ->
    @$input = $("""<div></div>""")
    @$input.appendTo @context.container

    @$input.bind "click", (e) =>
      APP.justdo_checklist_field.toggleItemState(@context.grid_control, @context.grid_control.current_path.get(), @context.field_name, allowNaOnCurrentProject())

      return

    return

  setInputValue: (val) ->
    @$input.html(format(@context.grid_control, @context.grid_control.current_path.get(), @context.field_name))

    return

  validator: (value) ->
    return undefined

  focus: ->
    return

  destroy: ->
    @$input.remove()
    return