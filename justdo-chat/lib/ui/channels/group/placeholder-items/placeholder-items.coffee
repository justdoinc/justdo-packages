APP.executeAfterAppLibCode ->
  JD.registerPlaceholderItem "create-group-channel-with-user",
    data:
      template: "create_group_chat_with_user_btn"
    domain: "user-info-tooltip-actions"
    position: 200
    # Actual listingCondition is defined in the template helper.
    listingCondition: -> return true
  return

Template.create_group_chat_with_user_btn.onCreated ->
  @user_rv = @data?.user_rv
  @tooltip_controller = @data?.tooltip_controller

Template.create_group_chat_with_user_btn.helpers
  showCreateGroupWithUserBtn: ->
    tpl = Template.instance()
    user_id = tpl.user_rv?.get()?._id

    is_user_performing_user = user_id is Meteor.userId()
    is_user_bot = APP.justdo_chat.isBotUserId(user_id)
    is_user_proxy = APP.justdo_site_admins.isProxyUser(user_id)
    is_active_justdo_exists = JD.activeJustdoId()?

    return is_active_justdo_exists and (not is_user_performing_user) and (not is_user_bot) and (not is_user_proxy)

Template.create_group_chat_with_user_btn.events
  "click .create-group": (e, tpl) ->
    user_id = tpl.user_rv.get()._id
    APP.justdo_chat.upsertGroupChat({members_to_add: [user_id]})
    tpl.tooltip_controller?.closeTooltip()

    return
