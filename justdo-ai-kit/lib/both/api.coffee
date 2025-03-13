_.extend JustdoAiKit.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  getConf: (conf_key) ->
    if conf_key?
      return @conf[conf_key]
    
    return @conf
  
  _isUserCampaignAllowFirstProjectTemplateGeneratorToShow: (campaign_id) ->
    is_user_campaign_allow_picker_to_show = true

    if APP.justdo_promoters_campaigns?
      if (user_campaign_doc = APP.justdo_promoters_campaigns?.getCampaignDoc(campaign_id))?
        is_user_campaign_allow_picker_to_show = user_campaign_doc.show_post_registration_new_project_templates_picker
    
    return is_user_campaign_allow_picker_to_show