default_option_color = "00000000"

generatePickerDropdown = (selected_color) ->
  return new JustdoColorPickerDropdownController
    label: "Pick a background color"
    opener_custom_class: "custom-fields-justdo-color-picker-opener"
    default_color: selected_color

# ON CREATED
Template.project_custom_state_item.onCreated ->
  tpl = @
  tpl.is_editing_label = new ReactiveVar false
  tpl.cur_proj = APP.modules.project_page.curProj()

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

  @autorun =>
    tpl_data = Template.currentData()
    tpl.new_option_color_picker_dropdown_controller = generatePickerDropdown(tpl_data.bg_color)
    if tpl.color_picker_change_autorun?
      tpl.color_picker_change_autorun.stop()
    Tracker.nonreactive =>
      tpl.color_picker_change_autorun = Tracker.autorun =>
        selected_color = tpl.new_option_color_picker_dropdown_controller._selected_color_rv.get()
        if tpl_data.bg_color != selected_color
          cur_proj = APP.modules.project_page.curProj()
          state_id = tpl_data.state_id
          custom_states = cur_proj.getCustomStates()

          for state in custom_states
            if state.state_id == state_id
              state.bg_color = selected_color

          cur_proj.setCustomStates custom_states
        return
      return

    custom_state_style_node = tpl.find ".custom-state-style"

    $(custom_state_style_node).data("color_picker_controller", tpl.new_option_color_picker_dropdown_controller)

    color_picker_dropdown_node =
      APP.helpers.renderTemplateInNewNode("justdo_color_picker_dropdown", {color_picker_controller: tpl.new_option_color_picker_dropdown_controller})

    $(custom_state_style_node).html color_picker_dropdown_node.node 

    return

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

getDefaultTextLabelForState = (state_id) ->
  return APP.collections.Tasks.simpleSchema()._schema.state.grid_values[state_id]?.txt

# HELPERS
Template.project_custom_state_item.helpers
  isEditingLabel: ->
    return Template.instance().is_editing_label.get()

  showDefaultLabel: ->
    default_state_txt_label = getDefaultTextLabelForState(@state_id)

    return default_state_txt_label? and default_state_txt_label != @txt

  defaultLabel: -> getDefaultTextLabelForState(@state_id) or ""

  isCoreState: ->
    return APP.collections.Tasks.simpleSchema()._schema.state.grid_values[@state_id]?.core_state == true

  hideableState: ->
    return _.indexOf(Projects.not_hideable_states, @state_id) < 0

  isHiddenState: ->
    return APP.collections.Tasks.simpleSchema()._schema.state.grid_values[@state_id]?.core_state == true and 
      _.find(APP.modules.project_page.curProj().getRemovedCustomStates(), (s) => s.state_id == @state_id)?

  getCoreState: ->
    return JustdoHelpers.getCoreState(@state_id)
    
  # to ensure no flicker after text update we need to isolate div.custom-state-label-text-active
  textActive: ->
    return """<div class="custom-state-label-text-active">#{@txt}</div>"""

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
  
  "click .create-extended-state": (e, tpl) ->
    state = tpl.data
    APP.modules.project_page.curProj().addCustomState({
      core_state: state.state_id
      txt: "#{state.txt} - extended"
    })
    return

  "click .remove-extended-state": (e, tpl) ->
    state = tpl.data
    APP.modules.project_page.curProj().removeCustomState(state.state_id)
    return
  
  "click .restore-extended-state": (e, tpl) ->
    state = tpl.data
    APP.modules.project_page.curProj().restoreRemovedState(state.state_id)
    return
