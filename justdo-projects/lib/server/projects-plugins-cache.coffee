# It is common need for plugins developers to need to efficiently tell whether task X belongs to a project
# where the plugin is installed. Such checks might happen in hooks that can happen very frequently.
# In an effort to address that need the projects cache got introduced. In the furuter the right way
# to implement that is with memcache.

_.extend Projects.prototype,
  _initProjectsPluginsCache: ->
    @_projects_plugins_cache = {}

    setCachedProjectPlugins = (project_id, fields) =>
      if not (custom_features = fields.conf?.custom_features)?
        return

      delete @_projects_plugins_cache[project_id]
      @_projects_plugins_cache[project_id] = new Set()

      for custom_feature in custom_features
        @_projects_plugins_cache[project_id].add(custom_feature)

      return

    removeProjectFromCache = (project_id) =>
      delete @_projects_plugins_cache[project_id]

      return

    @projects_collection.find().observeChanges
      added: (id, fields) ->
        setCachedProjectPlugins(id, fields)

        return

      changed: (id, fields) ->
        setCachedProjectPlugins(id, fields)

        return

      removed: (id) ->
        removeProjectFromCache(id)

        return

  isPluginIdInstalledOnProjectId: (project_id, plugin_id) ->
    return @_projects_plugins_cache[project_id].has(plugin_id)
