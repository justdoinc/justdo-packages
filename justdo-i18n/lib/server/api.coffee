_.extend JustdoI18n.prototype,
  _immediateInit: ->
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

    @_setupAfterImprintCampaignIdHook()

    return


  _setupAfterImprintCampaignIdHook: ->
    APP.justdo_promoters_campaigns?.on "after-imprint-campaign-id", ({campaign_doc, user_id}) ->
      if not (lang = campaign_doc?.lang)?
        return

      modifier = 
        $set:
          "profile.lang": lang
      Meteor.users.update(user_id, modifier)

      return
      
    return