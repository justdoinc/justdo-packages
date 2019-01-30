if Meteor.isServer
  Meteor.publish "allUsers", ->
    Meteor.users.find {}

if Meteor.isClient
  Template.custom_input.onCreated ->
    @profile_pic = new ReactiveVar null
    @email = new ReactiveVar null
    @first_name = new ReactiveVar null
    @last_name = new ReactiveVar null
    Meteor.subscribe "allUsers"

  Template.custom_input.helpers
    profile_pic: -> Template.instance().profile_pic.get()
    email: -> Template.instance().email.get()
    first_name: -> Template.instance().first_name.get()
    last_name: -> Template.instance().last_name.get()

  Template.custom_input.events
    "keyup #email": (e, template) ->
      template.email.set e.target.value
    "keyup #first-name": (e, template) ->
      template.first_name.set e.target.value
    "keyup #last-name": (e, template) ->
      template.last_name.set e.target.value

  Template.all_user.helpers
    users: -> Meteor.users.find()