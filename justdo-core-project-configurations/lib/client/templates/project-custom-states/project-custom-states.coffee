default_states = [
  {
    "state_id": "pending",
    "label": "Pending",
    "type": "pre-work", # one of: pre-work/in-progress/post-work
    "bg_color": "#AFB7C3", # the user choose it, we automatically set the fg_color accordingly for contrast, e.g black bg will result in white fg.
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "in-progress",
    "label": "Custom state for In progress",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "done",
    "label": "Done",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "will-not-do",
    "label": "Cancelled",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "on-hold",
    "label": "On hold",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "duplicate",
    "label": "Duplicate",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": true
  },
  {
    "state_id": "fdsfsd34fdsf",
    "label": "Custom state",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": false
  }
]

removed_states = [
  {
    "state_id": "dsdasdasd",
    "label": "Some custom state",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": false
  }
  {
    "state_id": "fdsfsd34fdsf",
    "label": "One more state",
    "type": "in-progress",
    "bg_color": "#AFB7C3",
    "fg_color": "#000000",
    "default": false
  }
]

# ON CREATED
Template.project_custom_states.onCreated ->
  tpl = @
  tpl.active_states = new ReactiveVar default_states
  tpl.removed_states = new ReactiveVar removed_states

  return

# HELPERS
Template.project_custom_states.helpers
  activeStates: ->
    return Template.instance().active_states.get()

  removedStates: ->
    return Template.instance().removed_states.get()
