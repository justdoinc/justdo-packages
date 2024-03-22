_.extend JustdoNewProjectTemplates.prototype,
  _immediateInit: ->
    @_preventFirstTaskOfProjectBeingCreated()
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _preventFirstTaskOfProjectBeingCreated: ->
    if @app_type is "web-app"
      # When the justdo-new-project-template is turned on, we don't want the usual
      # first task to be created, as it will occupy a redundant seqId. Further,
      # we'll need to remove it.
      APP.projects.on "pre-create-first-project-for-new-user", (new_user_doc, create_new_project_options) =>
        user_campaign_id = new_user_doc.promoters?.referring_campaign_id
        
        if APP.justdo_promoters_campaigns?
          is_new_project_template_picker_allowed_to_show = APP.justdo_promoters_campaigns.isUserCampaignAllowNewProjectTemplatePickerToShow user_campaign_id
        else
          is_new_project_template_picker_allowed_to_show = true
        
        if is_new_project_template_picker_allowed_to_show
          create_new_project_options.init_first_task = false
        return

    return
