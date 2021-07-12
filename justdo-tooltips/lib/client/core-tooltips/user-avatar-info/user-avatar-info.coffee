APP.justdo_tooltips.registerTooltip
  id: "user-avatar-info"
  template: "user_avatar_info_tooltip"

Template.user_avatar_info_tooltip.helpers
  userName: ->

    return JustdoHelpers.displayName(@options.id)

  userAvatar: ->
    user = Meteor.users.findOne(@options.id)

    if user?
      return JustdoAvatar.showUserAvatarOrFallback(user)

  showEmail: ->
    return true

  userEmail: ->
    user = Meteor.users.findOne(@options.id)

    if user?
      return user.emails[0].address

Template.user_avatar_info_tooltip.events
  "click .send-message": ->
    Template.instance().data.tooltip_controller.closeTooltip()

    return
