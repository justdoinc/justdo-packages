# ON CREATED
Template.project_custom_state_item.onCreated ->
  tpl = @
  tpl.is_editing_label = new ReactiveVar false
  tpl.cur_proj = APP.modules.project_page.curProj()
  tpl.colors = [
    "#B3E5FC",
    "#4FC3F7",
    "#03A9F4",
    "#0288D1",
    "#F8BBD0",
    "#F06292",
    "#E91E63",
    "#C2185B",
    "#CFD8DC",
    "#90A4AE",
    "#607D8B",
    "#455A64",
    "#C8E6C9",
    "#81C784",
    "#4CAF50",
    "#388E3C",
    "#FFF9C4",
    "#FFF176",
    "#FFEB3B",
    "#FBC02D",
  ]

  # Update State Txt
  tpl.updateStateTxt = (state_id, txt) ->
    custom_states = tpl.cur_proj.getCustomStates()

    if txt == ""
      gc = APP.modules.project_page.gridControl()
      txt = gc?.getSchemaExtendedWithCustomFields()?.state?.grid_values?[state_id]?.txt

    for state in custom_states
      if state.state_id == state_id
        state.txt = txt

    tpl.cur_proj.setCustomStates custom_states

    return

  return

# ON RENDERED
Template.project_custom_state_item.onRendered ->
  tpl = @

  $(".active-states").sortable
    items: ".project-custom-state-item"
    handle: ".custom-state-handle"
    tolerance: "pointer"
    deactivate: (e, ui) ->
      custom_states = []
      states_dom = $(".active-states .project-custom-state-item")

      for state in states_dom
        custom_states.push Blaze.getData(state)

      $(".active-states").sortable "cancel"
      Deps.flush()
      tpl.cur_proj.setCustomStates custom_states


      return

  return

# HELPERS
Template.project_custom_state_item.helpers
  isEditingLabel: ->
    return Template.instance().is_editing_label.get()

  showDefaultLabel: ->
    state_id = @state_id
    gc = APP.modules.project_page.gridControl()
    state_label = gc?.getSchemaExtendedWithCustomFields()?.state?.grid_values?[state_id]?.txt

    return not (state_label == @txt)

  defaultLabel: ->
    state_id = @state_id
    gc = APP.modules.project_page.gridControl()
    state_label = gc?.getSchemaExtendedWithCustomFields()?.state?.grid_values?[state_id]?.txt

    return state_label

  hideableState: ->
    return _.indexOf(Projects.not_hideable_states, @state_id) < 0

  # to ensure no flicker after text update we need to isolate div.custom-state-label-text-active
  textActive: (txt) ->
    return """<div class="custom-state-label-text-active">#{txt}</div>"""

  colors: ->
    return Template.instance().colors

  activeColor: (color) ->
    bg_color = Template.instance().data.bg_color

    return color == bg_color


# EVENTS
Template.project_custom_state_item.events
  "click .custom-state-label-text-active": (e, tpl) ->
    tpl.is_editing_label.set true
    Meteor.defer ->
      tpl.$(".custom-state-label-input").focus()

    return

  "blur .custom-state-label-input": (e, tpl) ->
    txt = e.target.value
    state_id = tpl.data.state_id

    if not (txt == "")
      $(e.target).next().find(".custom-state-label-text-active").text txt

    tpl.updateStateTxt state_id, txt
    tpl.is_editing_label.set false

    return

  "keydown .custom-state-label-input": (e, tpl) ->
    if e.which == 13
      txt = e.target.value
      state_id = tpl.data.state_id

      if not (txt == "")
        $(e.target).next().find(".custom-state-label-text-active").text txt

      tpl.updateStateTxt state_id, txt
      tpl.is_editing_label.set false

    return

  "click .custom-state-hide": (e, tpl) ->
    cur_proj = APP.modules.project_page.curProj()
    state_id = tpl.data.state_id
    custom_states = cur_proj.getCustomStates()
    custom_states = _.filter custom_states, (state) -> state.state_id != state_id

    cur_proj.setCustomStates custom_states

    return

  "click .custom-state-show": (e, tpl) ->
    cur_proj = APP.modules.project_page.curProj()
    state = tpl.data
    custom_states = cur_proj.getCustomStates()
    custom_states.push state

    cur_proj.setCustomStates custom_states

    return

  "click .custom-state-style-color": (e, tpl) ->
    bg_color = @.substring()
    cur_proj = APP.modules.project_page.curProj()
    state_id = tpl.data.state_id
    custom_states = cur_proj.getCustomStates()

    for state in custom_states
      if state.state_id == state_id
        state.bg_color = bg_color

    cur_proj.setCustomStates custom_states

    return
