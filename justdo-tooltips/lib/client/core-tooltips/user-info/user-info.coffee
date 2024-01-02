APP.justdo_tooltips.registerTooltip
  id: "user-info"
  template: "user_info_tooltip"

Template.user_info_tooltip.helpers
  userName: ->

    return JustdoHelpers.displayName(@options.id)

  userAvatar: ->
    user = Meteor.users.findOne(@options.id)

    if user?
      return JustdoAvatar.showUserAvatarOrFallback(user)
  userAvatarBgColor: ->
    if APP.justdo_chat.isBotUserId(@options.id)
      user = APP.collections.JDChatBotsInfo.findOne(@options.id)
    else
      user = Meteor.users.findOne(@options.id)

    if not user?
      return 

    avatar = JustdoAvatar.showUserAvatarOrFallback(user)
    if JustdoAvatar.isAvatarBase64Svg avatar
      $svg = JustdoAvatar.base64SvgAvatarToElement avatar
      return $svg.find("circle").attr("fill")
    else
      $img = $("<img />").attr("src", avatar).attr("crossorigin", "anonymous")
      bg_color_arr = JustdoHelpers.getImageColor $img.get(0)

      return "rgb(#{bg_color_arr?[0]}, #{bg_color_arr?[1]}, #{bg_color_arr?[2]})"

  showEmail: ->
    return true

  userEmail: ->
    user = Meteor.users.findOne(@options.id)

    if user?
      return user.emails[0].address

Template.user_info_tooltip.events
  "click .send-message": ->
    Template.instance().data.tooltip_controller.closeTooltip()

    return
