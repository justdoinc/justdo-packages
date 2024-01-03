APP.justdo_tooltips.registerTooltip
  id: "user-info"
  template: "user_info_tooltip"

Template.user_info_tooltip.onCreated ->
  @user_rv = new ReactiveVar {}
  @avatar_url_rv = new ReactiveVar ""
  @autorun =>
    user_id = @data.options.id

    if APP.justdo_chat.isBotUserId(user_id)
      user = APP.collections.JDChatBotsInfo.findOne(user_id)
    else
      user = Meteor.users.findOne(user_id)
    
    @user_rv.set user
    @avatar_url_rv.set JustdoAvatar.showUserAvatarOrFallback user
    return

  return

Template.user_info_tooltip.helpers
  userName: ->
    tpl = Template.instance()
    return JustdoHelpers.displayName(tpl.user_rv.get())

  userAvatar: ->
    tpl = Template.instance()
    user = tpl.user_rv.get()
    avatar = tpl.avatar_url_rv.get()
    
    # If avatar is a base64 svg, enlarge the text.
    if JustdoAvatar.isAvatarBase64Svg avatar
      $svg = JustdoAvatar.base64SvgAvatarToElement avatar
      $svg.attr("width", "100%")
      $svg.attr("height", "100%")
      $svg.find("circle").attr("cx", "50%")
      $svg.find("circle").attr("cy", "50%")
      $svg.find("circle").attr("r", "100%")
      $svg.find("text").css("font-size", "60px")
      return "#{JustdoAvatar.base64_svg_prefix}#{window.btoa(unescape(encodeURIComponent($svg.get(0).outerHTML)))}"

    return avatar
  



  showEmail: ->
    return true

  userEmail: ->
    tpl = Template.instance()

    if (user = tpl.user_rv.get())?
      return JustdoHelpers.getUserMainEmail user
  
  isMessageButtonsAllowedToShow: ->
    tpl = Template.instance()
    user_id = tpl.user_rv.get()._id

    is_user_performing_user = user_id is Meteor.userId()
    is_user_bot = APP.justdo_chat.isBotUserId(user_id)
    is_user_proxy = APP.justdo_site_admins.isProxyUser(user_id)
    return (not is_user_performing_user) and (not is_user_bot) and (not is_user_proxy)
  
  isCreateGroupAllowedToShow: ->
    return JD.activeJustdoId()?

Template.user_info_tooltip.events
  "click .send-message": ->
    Template.instance().data.tooltip_controller.closeTooltip()

    return
