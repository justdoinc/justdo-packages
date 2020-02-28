Template.add_as_guest_toggle.Controller = ->
  @is_add_as_guest_rv = new ReactiveVar false

  @toggle = =>
    return @is_add_as_guest_rv.set(not @is_add_as_guest_rv.get())

  @isAddAsGuest = ->
    return @is_add_as_guest_rv.get()

  return @

Template.add_as_guest_toggle.onCreated ->
  # Check whether a proper controller provided.

  if @data.controller?.constructor != Template.add_as_guest_toggle.Controller
    APP.projects._error("invalid-argument", "The Template.add_as_guest_toggle needs to be initiated with a data object that has the 'controller' property set to an instance of Template.add_as_guest_toggle.Controller")

    return

  return

Template.add_as_guest_toggle.helpers
  isAddAsGuest: -> @controller.isAddAsGuest()

  about_guests: -> Projects.guest_user_help_instruction

Template.add_as_guest_toggle.events
  "click .add-as-guest-toggle": (e, tpl) ->
    return @controller.toggle()
