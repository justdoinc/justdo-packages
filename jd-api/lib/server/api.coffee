_.extend JD,
  isPluginIdInstalledOnJustdoId: (justdo_id, plugin_id) ->
    return APP.projects.isPluginIdInstalledOnProjectId(justdo_id, plugin_id)