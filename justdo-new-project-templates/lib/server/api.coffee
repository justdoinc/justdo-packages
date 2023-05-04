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
    # When the justdo-new-project-template is turned on, we don't want the usual
    # first task to be created, as it will occupy a redundant seqId. Further,
    # we'll need to remove it.
    APP.projects.on "pre-create-new-justdo", (user_id, options, project) ->
      options.init_first_task = false
      return

    return
