_.extend JustdoFormulaFields.prototype,
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

    return

  performInstallProcedures: (project_doc, user_id) ->
    if (custom_fields = project_doc.custom_fields)?
      # look for disabled formula fields, and re-enable them.

      # XXX Starting from mongo 3.6, we will be able to do the following in
      # pure mongo query.

      changed = false
      for custom_field in custom_fields
        if custom_field.custom_field_type_id == JustdoFormulaFields.custom_field_type_id
          if custom_field.disabled == true
            delete custom_field.disabled

            changed = true

      if changed
        @projects_collection.update(project_doc._id, {$set: {custom_fields: custom_fields}})

    @enableProjectFormulasDueToPluginEnable(project_doc._id)

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    if (custom_fields = project_doc.custom_fields)?
      # Disable the project's formula fields, and re-enable them.

      # XXX Starting from mongo 3.6, we will be able to do the following in
      # pure mongo query.

      changed = false
      for custom_field in custom_fields
        if custom_field.custom_field_type_id == JustdoFormulaFields.custom_field_type_id
          if not custom_field.disabled? or not custom_field.disabled
            custom_field.disabled = true

            changed = true

      if changed
        @projects_collection.update(project_doc._id, {$set: {custom_fields: custom_fields}})

    @disableProjectFormulasDueToPluginDisable(project_doc._id)

    return

  projectFormulasPublicationHandler: (publish_this, project_id, user_id) ->
    check project_id, String
    check user_id, String

    if _.isEmpty(project_id)
      publish_this.stop()

      return

    APP.projects.requireUserIsMemberOfProject project_id, user_id

    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_ALL_FORMULAS_INDEX there)
    #
    return @formulas_collection.find({project_id: project_id})

  _createSameValueObjectFromArray: (arr, value) ->
    return _.object(_.map(arr, (dependent_field_id) -> return [dependent_field_id, value]))

  setCustomFieldFormula: (project_id, custom_field_id, formula, options, user_id) ->
    self = @

    # If formula is set to null/"", we regard it as a formula clearing/init request.

    check project_id, String
    check custom_field_id, String
    check formula, Match.Maybe(String)
    check options, Object # at the moment, there are no options, need to properly validate once we'll have
    check user_id, String

    # Normalize formula to null if we are about to clear the formula.
    if _.isString formula
      formula = formula.trim()

      if _.isEmpty formula
        formula = null

    project_doc = APP.projects.requireProjectAdmin project_id, user_id

    if not @isPluginInstalledOnProjectDoc(project_doc)
      throw @_error "plugin-not-installed-for-project", "Can't set a formula for a field in a project where the #{JustdoFormulaFields.plugin_human_readable_name} plugin is disabled."

    modifier =
      $set:
        formula: formula
        formula_field_updated_at: new Date()
        formula_field_edited_by: user_id

        defect_found: false
        defect_cause: null

        project_removed: false # can't be removed as we just fetched it.

        plugin_disabled: false
        formula_field_removed: false

    if _.isString formula # Formula is String means we need to process it now
      # Parse and compile the formula to ensure it is valid
      # (Many Meteor.Error() exceptions can be raised in this step)
      processed_formula =
        @processFormula(formula, custom_field_id, @getCustomFieldsFromProjectDoc(project_doc), {compile: true})

      dependent_fields = _.keys(processed_formula.field_to_symbol)
      modifier.$set.formula_dependent_fields_object = @_createSameValueObjectFromArray(dependent_fields, null)
      modifier.$set.formula_dependent_fields_array = dependent_fields
    else # Formula is not string 
      modifier.$set.formula_dependent_fields_object = null
      modifier.$set.formula_dependent_fields_array = null

    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_SPECIFIC_FORMULA_INDEX there)
    #
    @formulas_collection.upsert({project_id: project_id, custom_field_id: custom_field_id}, modifier)

    # Update the entire column

    raw_tasks_collection = @tasks_collection.rawCollection()
    if not _.isString(formula)
      # If we are clearing the formula, clear the column
      update_query =
        project_id: project_id,
        _raw_removed_date: null,
        "#{custom_field_id}": {$ne: null}
      update_modifier = {$set: {"#{custom_field_id}": null}}

      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_modifier)

      APP.justdo_analytics.logMongoRawConnectionOp(self.tasks_collection._name, "update", update_query, update_modifier)
      raw_tasks_collection.update update_query, update_modifier, {multi: true}, Meteor.bindEnvironment (err) ->
        if err?
          console.error(err)

        return

      return
    else
      # This one is actually partially using the FETCH_PROJECT_NON_REMOVED_TASKS_INDEX index
      or_query = [{ # Find existing cases where a value is already set in the formula field
        "#{custom_field_id}": {$ne: null}
      }]

      for dep_field in dependent_fields
        or_query.push {
          [dep_field]: {$ne: null}
        }

      tasks_to_update_query =
        $and:
          [
            project_id: project_id,
            _raw_removed_date: null,
            $or: or_query
          ]
        
      fields_projection = _.extend @_createSameValueObjectFromArray(dependent_fields, 1), {_id: 1, "#{custom_field_id}": 1}
      @tasks_collection.find(tasks_to_update_query, {fields: fields_projection}).forEach (task_doc) ->
        try
          calculated_value = processed_formula.eval(task_doc)
        catch e
          console.error "Failed to calculate formula field #{custom_field_id}, for task #{task_doc._id}", e

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

  findActiveFormulasAffectedByFieldChangesForProject: (project_id, changed_fields, cb) ->
    check project_id, String
    check changed_fields, [String]

    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_ACTIVE_FORMULAS_INDEX there)
    #
    query =
      project_id: project_id
      formula: {$ne: null}
      formula_dependent_fields_array: {$in: changed_fields}
      defect_found: false
      project_removed: false
      plugin_disabled: false
      formula_field_removed: false

    return @formulas_collection.find(query).forEach cb    

  disableProjectFormulasDueToPluginDisable: (project_id) ->
    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_ALL_FORMULAS_INDEX there)
    #
    @formulas_collection.update({project_id: project_id}, {$set: {plugin_disabled: true}}, {multi: true})

    return

  enableProjectFormulasDueToPluginEnable: (project_id) ->
    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_ALL_FORMULAS_INDEX there)
    #
    @formulas_collection.update({project_id: project_id}, {$set: {plugin_disabled: false}}, {multi: true})

    return

  disableRemovedCustomFieldFormula: (project_id, custom_field_id) ->
    #
    # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_SPECIFIC_FORMULA_INDEX there)
    #
    @formulas_collection.update({project_id: project_id, custom_field_id: custom_field_id}, {$set: {formula_field_removed: true}})

    return
