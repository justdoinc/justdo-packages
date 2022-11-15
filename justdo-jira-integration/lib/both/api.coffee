_.extend JustdoJiraIntegration.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

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

  getJiraDocIdFromJustdoId: (justdo_id) ->
    check justdo_id, String
    if not (jira_doc_id = @projects_collection.findOne(justdo_id, {fields: {"conf.#{JustdoJiraIntegration.projects_collection_jira_doc_id}": 1}})?.conf?[JustdoJiraIntegration.projects_collection_jira_doc_id])?
      throw @_error "not-supported", "Justdo #{justdo_id} does not have a linked Jira doc"
    return jira_doc_id

  getJiraServerInfoFromJustdoId: (justdo_id) ->
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id
    return @jira_collection.findOne(jira_doc_id, {fields: {server_info: 1}})?.server_info

  getAuthTypeIfJiraInstanceIsOnPerm: ->
    if @server_type.includes "server"
      return @server_type.replace "server-", ""
    return

  isJiraInstanceCloud: ->
    return @server_type.includes "cloud"
