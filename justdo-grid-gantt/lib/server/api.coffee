_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # # Defined in publications.coffee
    # @_setupPublications()

    # # Defined in allow-deny.coffee
    # @_setupAllowDenyRules()

    # # Defined in collections-indexes.coffee
    # @_ensureIndexesExists()

    # @_registerAllowedConfs()

    return

  setProgressPercentage: (task_id, new_progress_percentage, user_id) ->
    check task_id, String
    check new_progress_percentage, Number
    check user_id, String

    task = APP.collections.Tasks.findOne task_id, 
      members: user_id
    
    if not task?
      throw @_error "task-not-found"
    
    APP.collections.Tasks.update task_id,
      $set:
        "#{JustdoGridGantt.progress_percentage_pseudo_field_id}": new_progress_percentage
    
    return

  
