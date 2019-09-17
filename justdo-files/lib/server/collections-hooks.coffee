_.extend JustdoFiles.prototype,
  _setupCollectionsHooks: ->
    @projectsInstallUninstallProcedures()

    return

  projectsInstallUninstallProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      feature_id = JustdoFiles.project_custom_feature_id # shortcut

      if (custom_features = modifier.$set?["conf.custom_features"])?
        previous_custom_features = @previous?.conf?.custom_features
        new_custom_features = doc.conf?.custom_features

        plugin_was_installed_before = false
        if _.isArray previous_custom_features
          plugin_was_installed_before = feature_id in previous_custom_features

        plugin_is_installed_after = false
        if _.isArray new_custom_features
          plugin_is_installed_after = feature_id in new_custom_features

        if not plugin_was_installed_before and plugin_is_installed_after
          self.performInstallProcedures(doc, user_id)

        if plugin_was_installed_before and not plugin_is_installed_after
          self.performUninstallProcedures(doc, user_id)

      return

    return