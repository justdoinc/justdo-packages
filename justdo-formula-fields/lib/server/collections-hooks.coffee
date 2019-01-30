_.extend JustdoFormulaFields.prototype,
  _setupCollectionsHooks: ->
    @projectsInstallUninstallProcedures()

    @removedFormulaCustomFieldsProcedures()

    @checkIfFormulaNeedsRecalcForTaskUpdate()

    return

  projectsInstallUninstallProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      feature_id = JustdoFormulaFields.project_custom_feature_id # shortcut

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

  removedFormulaCustomFieldsProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      previous_removed_custom_fields_ids = _.map(@previous?.removed_custom_fields, (field_def) -> field_def.field_id) or []
      new_removed_custom_fields_ids = _.map(doc.removed_custom_fields, (field_def) -> field_def.field_id) or []

      custom_fields_ids_removed_now = _.difference(new_removed_custom_fields_ids, previous_removed_custom_fields_ids)

      for custom_field_id_removed_now in custom_fields_ids_removed_now
        removed_custom_field_def = _.find(doc.removed_custom_fields, (field_def) -> field_def.field_id == custom_field_id_removed_now)

        if removed_custom_field_def.custom_field_type_id == JustdoFormulaFields.custom_field_type_id
          self.disableRemovedCustomFieldFormula(doc._id, custom_field_id_removed_now)

    return

  checkIfFormulaNeedsRecalcForTaskUpdate: ->
    self = @

    self.tasks_collection.after.update (user_id, task_doc, changed_fields, modifier, options) ->
      self.findActiveFormulasAffectedByFieldChangesForProject task_doc.project_id, changed_fields, (formula_doc) ->
        project_doc = APP.collections.Projects.findOne(task_doc.project_id)

        custom_field_id = formula_doc.custom_field_id

        processed_formula =
          self.processFormula(formula_doc.formula, custom_field_id, self.getCustomFieldsFromProjectDoc(project_doc), {compile: true})

        try
          calculated_value = processed_formula.eval(task_doc)
        catch e
          console.error "Failed to calculate formula field #{custom_field_id}, for task #{task_doc._id}", e

        raw_tasks_collection = self.tasks_collection.rawCollection()

        update_query = {_id: task_doc._id}
        update_modifier = {$set: {"#{custom_field_id}": calculated_value}}

        APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_modifier)

        APP.justdo_analytics.logMongoRawConnectionOp(self.tasks_collection._name, "update", update_query, update_modifier)
        raw_tasks_collection.update update_query, update_modifier, Meteor.bindEnvironment (err) ->
          if err?
            console.error(err)

          return

      return

    return