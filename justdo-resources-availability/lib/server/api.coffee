_.extend JustdoResourcesAvailability.prototype,
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
    # Called when plugin installed for project project_doc._id
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id
    # Note, isn't called on project removal
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} removed from project #{project_doc._id}"

    return

  saveResourceAvailability: (project_id, availability, resource_user_id, task_id, executing_user_id) ->

    #sanitize availability structure
    sanitized_availability = {}

    check availability.holidays, [String]
    sanitized_availability.holidays = availability.holidays
    for i in [0..6]
      check availability.working_days[i].from, String
      check availability.working_days[i].to, String
      check availability.working_days[i].holiday, Boolean
      Meteor._ensure sanitized_availability, "working_days", i
      sanitized_availability.working_days[i] = availability.working_days[i]

    check executing_user_id, String
    check project_id, String
    if resource_user_id
      check resource_user_id, String
    if task_id
      check task_id, String

    if not(project_obj = APP.collections.Projects.findOne({_id: project_id, "members.user_id": executing_user_id}))
      throw @_error "project-not-found", "Project not found, or executing member not part of project"

    #find the executing member to see if he is allowed to modify
    is_admin = false
    for member in project_obj.members
      if member.user_id == executing_user_id
        if member.is_admin
          is_admin = true
        break

    if is_admin or executing_user_id == resource_user_id
      resource_availability_field = JustdoResourcesAvailability.project_custom_feature_id
      all_resources = _.extend {}, project_obj[resource_availability_field]
      key = project_id
      if resource_user_id
        key += ":" + resource_user_id
      if task_id
        key += ":" + task_id

      all_resources[key] = sanitized_availability
      op = {$set: {"#{resource_availability_field}": all_resources}}

      APP.collections.Projects.update(project_id, op)

    return