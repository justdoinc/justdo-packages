_.extend JustdoJiraIntegration.prototype,
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

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoJiraIntegration.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoJiraIntegration.project_custom_feature_id})

  getJiraServerInfoFromJustdoId: (justdo_id) ->
    check justdo_id, String
    jira_doc_id = @projects_collection.findOne(justdo_id, {fields: {[JustdoJiraIntegration.projects_collection_jira_doc_id]: 1}})?[JustdoJiraIntegration.projects_collection_jira_doc_id]
    return @jira_collection.findOne(jira_doc_id, {fields: {server_info: 1}})?.server_info
