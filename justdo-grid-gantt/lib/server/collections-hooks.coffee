_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    # Defined in db-migrations.coffee
    # @_setupDbMigrations()
    
    return

  _deferredInit: ->
    if @destroyed
      return

    # # Defined in methods.coffee
    # @_setupMethods()

    # # Defined in publications.coffee
    # @_setupPublications()

    # # Defined in allow-deny.coffee
    # @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # # Defined in collections-indexes.coffee
    # @_ensureIndexesExists()

    return
  
  _setupCollectionsHooks: ->
    @setupMilestoneRestrictions()

  setupMilestoneRestrictions: ->
    self = @
    APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
      if modifier?.$set?[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"
        if not modifier.$set?
          modifier.$set = {}
        modifier.$set.end_date = doc.start_date
      else if doc?[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"
        if (new_start_date = modifier.$set?.start_date)?
          modifier.$set.end_date = new_start_date
        else if modifier.$set?.end_date?
          return false

      return true