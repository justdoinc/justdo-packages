APP.justdo_tooltips.registerTooltip
  id: "user-info"
  template: "user_info_tooltip"

APP.executeAfterAppLibCode ->
  JD.registerPlaceholderItem "user-info-tooltip-project-membership",
    data:
      template: "user_info_tooltip_project_membership_info"
    domain: "user-info-tooltip-bottom"
    position: 100
    listingCondition: -> JD.activeJustdoId()?
  return

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
  userDoc: ->
    tpl = Template.instance()
    return tpl.user_rv.get()

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
      # Proxy users has dotted border around their avatar. Here we replace it with a square version.
      if ($dotted_border = $svg.find("circle[style*=stroke-dasharray]")).length > 0 
        $dotted_border.remove()
        # First rect is to bring back the white border.
        # Second rect is the dotted lines.
        $svg.append """
            <rect width="100%" height="100%" fill="none" style="
              stroke: #ffffff;
              stroke-width: 5px;
            ">
            </rect>
            <rect width="100%" height="100%" fill="none" style="
              stroke: #546e7a;
              stroke-width: 3px;
              stroke-dasharray: 2 5;
              stroke-linecap: round;
              stroke-linejoin: round;">
            </rect>
        """

      return "#{JustdoAvatar.getBase64SvgPrefix()}#{window.btoa(unescape(encodeURIComponent($svg.get(0).outerHTML)))}"

    # Request a larger avatar from gravatar.
    if avatar.includes "gravatar"
      avatar = new URL(avatar)
      avatar.searchParams.set "s", 200
      avatar = avatar.toString()

    return encodeURI avatar

  getUserTooltipActionItems: -> JD.getPlaceholderItems "user-info-tooltip-actions"

  templateData: -> 
    tpl = Template.instance()

    ret = 
      user_rv: tpl.user_rv
      tooltip_controller: tpl.data.tooltip_controller
    return ret

  showEmail: ->
    return true
  
  getUserTooltipBottomItems: -> JD.getPlaceholderItems "user-info-tooltip-bottom"

Template.user_info_tooltip_project_membership_info.onCreated ->
  @user_rv = @data?.user_rv
  return

Template.user_info_tooltip_project_membership_info.helpers
  projectMemberStatus: ->
    tpl = Template.instance()
    user_id = tpl.user_rv.get()._id

    if not (project = APP.modules.project_page.curProj())?
      return
    
    if _.find(project.getAdmins(), (admin) -> admin.user_id is user_id)
      return "Admin"
    
    if _.find(project.getGuests(), (guest) -> guest.user_id is user_id)
      return "Guest"

    if _.find(project.getMembers(), (member) -> member.user_id is user_id)
      return "Member"
    
    return "Not a member"
  
  projectName: -> JD.activeJustdo({title: 1})?.title
