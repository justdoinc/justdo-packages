_.extend PACK.builtin_trackers,
  simpleTasksFieldsChangesTracker: (options) ->
    self = @

    if not (tracked_fields = options.tracked_fields)?
      tracked_fields = []

    last_queried_fields_definitions = null
    last_queried_fields_definitions_project_id = null
    last_queried_fields_definitions_project_id_expire_time = (new Date()).getTime()
    getProjectCustomFieldsDefinitions = (project_id) ->
      if project_id == last_queried_fields_definitions_project_id and (new Date()).getTime() < last_queried_fields_definitions_project_id_expire_time
        return last_queried_fields_definitions

      last_queried_fields_definitions_project_id = project_id
      last_queried_fields_definitions = GridControlCustomFields.getProjectCustomFieldsDefinitions(self.justdo_projects_obj, project_id)
      last_queried_fields_definitions_project_id_expire_time = (new Date()).getTime() + 2 * 1000 # 2 secs (we want it for one tick actually, to avoid the need to worry about changes in project's custom fields during the time the cache is valid)

      return last_queried_fields_definitions

    getFieldLabel = (project_id, field) ->
      if options.track_custom_fields
        custom_fields_definitions = getProjectCustomFieldsDefinitions(project_id)

        if field of custom_fields_definitions
          return custom_fields_definitions[field].label

      if options.track_pseudo_fields
        pseudo_custom_fields_definitions = self.getPseudoCustomFieldsTrackedBySimpleTasksFieldsChangesTracker()

        if field of pseudo_custom_fields_definitions
          return pseudo_custom_fields_definitions[field].label

      return self.tasks_collection.simpleSchema()._schema[field].label # XXX should be removed

    isTrackedField = (project_id, field) ->
      if options.track_custom_fields
        custom_fields_definitions = getProjectCustomFieldsDefinitions(project_id)

        if field of custom_fields_definitions
          return true

      if options.track_pseudo_fields
        pseudo_custom_fields_definitions = self.getPseudoCustomFieldsTrackedBySimpleTasksFieldsChangesTracker()

        if field of pseudo_custom_fields_definitions
          return true

      return field in tracked_fields

    addFieldUpdateLog = (performed_by, task_id, field, field_label, new_value, old_value, project_id) ->
      self.logChange
        field: field
        label: field_label # XXX should be removed
        new_value: new_value
        old_value: old_value
        task_id: task_id
        project_id: project_id
        by: performed_by

      return

    addClearedFieldLog = (performed_by, task_id, field, field_label, old_value, project_id) ->
      self.logChange
        field: field
        label: field_label # XXX should be removed
        new_value: ""
        old_value: old_value
        change_type: "unset"
        task_id: task_id
        project_id: project_id
        by: performed_by

      return

    self.tasks_collection.before.update (userId, doc, fieldNames, modifier, options) ->
      task_id = doc._id
      project_id = doc.project_id

      if modifier.$set?
        for field, new_value of modifier.$set
          if not isTrackedField(project_id, field)
            continue

          field_label = getFieldLabel(project_id, field)

          performed_by = self._extractUpdatedByFromModifierOrFail(modifier)

          old_value = doc[field] or null

          if old_value? and old_value is new_value
            # in this case there is no change in the new_value of the field.
            continue

          if not new_value?
            # Value got cleared
            addClearedFieldLog(performed_by, task_id, field, field_label, old_value, project_id)

            continue
          else
            addFieldUpdateLog(performed_by, task_id, field, field_label, new_value, old_value, project_id)

            continue

      if modifier.$unset?
        # We no longer support $unset on the Tasks collection, so no more of these
        # should be expected.
        for field, new_value of modifier.$unset
          if not isTrackedField(project_id, field)
            continue

          field_label = getFieldLabel(project_id, field)

          performed_by = self._extractUpdatedByFromModifierOrFail(modifier)

          addClearedFieldLog(performed_by, task_id, field, field_label, project_id)

          continue

      return true
