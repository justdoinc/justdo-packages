# ON CREATED
Template.project_custom_state_item.onCreated ->
  tpl = @
  tpl.is_editing_label = new ReactiveVar false

  return

# ON RENDERED
Template.project_custom_state_item.onRendered ->
  $(".active-states").sortable
    items: ".project-custom-state-item"
    handle: ".custom-state-handle"
    tolerance: "pointer"

  return

# HELPERS
Template.project_custom_state_item.helpers
  isEditingLabel: ->
    return Template.instance().is_editing_label.get()

  defaultLabel: ->
    state_id = @state_id
    gc = APP.modules.project_page.gridControl()
    state_label = gc?.getSchemaExtendedWithCustomFields()?.state?.grid_values?[state_id]?.txt

    return state_label


# EVENTS
Template.project_custom_state_item.events
  "click .custom-state-label-text-active": (e, tpl) ->
    tpl.is_editing_label.set true
    Meteor.defer ->
      tpl.$(".custom-state-label-input").focus()

    return

  "blur .custom-state-label-input": (e, tpl) ->
    tpl.is_editing_label.set false

    return
