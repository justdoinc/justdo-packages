APP.executeAfterAppLibCode ->
  JD.registerPlaceholderItem "send-dm-to-user-btn",
    data:
      template: "send_dm_to_user_btn"
    domain: "user-info-tooltip-actions"
    position: 100
    # Actual listingCondition is defined in the template helper.
    listingCondition: -> return true
  return

Template.send_dm_to_user_btn.onCreated ->
  @user_rv = @data?.user_rv
  @tooltip_controller = @data?.tooltip_controller
  return

Template.send_dm_to_user_btn.helpers
  showSendDmToUserBtn: ->
    tpl = Template.instance()
    # Don't show send DM button if we're already inside the dm window.
    if tpl.tooltip_controller?.$target_container?.parents(".user-channel").length > 0
      return false

    user_id = tpl.user_rv?.get()?._id

    is_user_performing_user = user_id is Meteor.userId()
    is_user_bot = APP.justdo_chat.isBotUserId(user_id)
    is_user_proxy = APP.justdo_site_admins.isProxyUser(user_id)

    return (not is_user_performing_user) and (not is_user_bot) and (not is_user_proxy)

Template.send_dm_to_user_btn.events
  "click .send-message": (e, tpl) ->
    user_id = tpl.user_rv.get()._id

    APP.justdo_chat.generateClientUserChatChannel(user_id)
    tpl.tooltip_controller?.closeTooltip()

    return
