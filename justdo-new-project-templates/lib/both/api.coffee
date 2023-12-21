_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return
    
  isUserCampaignAllowPickerToShow: (campaign_id) ->
    is_user_campaign_allow_picker_to_show = true

    if APP.justdo_promoters_campaigns?
      if (user_campaign_doc = APP.justdo_promoters_campaigns?.getCampaignDoc campaign_id)?
        is_user_campaign_allow_picker_to_show = user_campaign_doc.show_post_registration_new_project_templates_picker
    
    return is_user_campaign_allow_picker_to_show