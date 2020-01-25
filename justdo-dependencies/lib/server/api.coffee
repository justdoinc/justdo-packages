_.extend JustdoDependencies.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    #todo: Daniel - I'm hackingly registering a new bot with the same 'your assitance' look, till we have an API to do add a msg type
    APP.justdo_chat._registerBot "bot:your-assistant-jd-dependencies",
      profile:
        first_name: "Your"
        last_name: "Assistant"
        profile_pic: "/packages/justdoinc_justdo-chat/media/bots-avatars/your-assistant.png"

      msgs_types:
        "dependencies-cleared-for-execution":
          data_schema: {}
          rec_msgs_templates: # rec stands for recommanded
            en:
              "All dependencies are marked as 'done'. You can start working on this task."

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    console.log "Plugin #{JustdoDependencies.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    console.log "Plugin #{JustdoDependencies.project_custom_feature_id} removed from project #{project_doc._id}"

    return
