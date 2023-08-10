_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return
    
  isUserCampaignAllowPickerToShow: (user_id) ->
    is_user_campaign_allow_picker_to_show = true

    if APP.justdo_promoters_campaigns?
      if (user_campaign_doc = APP.justdo_promoters_campaigns?.getCampaignDoc user_id)?
        is_user_campaign_allow_picker_to_show = user_campaign_doc.show_new_project_templates_picker
    
    return is_user_campaign_allow_picker_to_show

    return
