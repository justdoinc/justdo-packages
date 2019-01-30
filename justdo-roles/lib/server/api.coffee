_.extend JustdoRoles.prototype,
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

  _setProjectRolesAndGroupsRolesAndGroupsObjSchema: new SimpleSchema
    regions:
      label: "Regions"

      type: [JustdoRoles.schemas.RegionsSchema]

    roles:
      label: "Roles"

      type: [JustdoRoles.schemas.RolesSchema]

    groups:
      label: "Groups"

      type: [JustdoRoles.schemas.GroupsSchema]
  setProjectRolesAndGroups: (project_id, roles_and_groups_obj, user_id) ->
    check project_id, String

    # Check user is admin of said project, only admins are given full privileges
    project_doc = APP.projects.requireProjectAdmin(project_id, user_id)

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_setProjectRolesAndGroupsRolesAndGroupsObjSchema,
        roles_and_groups_obj,
        {self: @, throw_on_error: true}
      )
    roles_and_groups_obj = cleaned_val

    # Validations/forced defaults
    {regions, roles, groups} = roles_and_groups_obj

    # regions can't be empty
    if regions.length == 0
      throw @_error "invalid-argument", "Regions array can't be empty. Please set at the minimum the definition for the _id='default' region."

    # The first region in the regions array, must be the "default" region.
    if regions[0]._id is not "default"
      throw @_error "invalid-argument", "The regions array must begin from _id: 'default' region."

    regions[0].label = "Default" # We don't allow the default region to have a label other than Default

    # Ensure there is no repetition of regions/roles/groups _ids
    if _.unique(_.map(regions, (region) -> region._id)).length != regions.length
      throw @_error "invalid-argument", "Same region _id used more than once."

    if _.unique(_.map(groups, (group) -> group._id)).length != groups.length
      throw @_error "invalid-argument", "Same group _id used more than once."

    if _.unique(_.map(roles, (role) -> role._id)).length != roles.length
      throw @_error "invalid-argument", "Same role _id used more than once."

    # Every role must set a value for the default region in its regions array - as its first value.
    for role in roles
      if role.regions[0]._id != "default"
        throw @_error "invalid-argument", "Role #{role.label} doesn't define a user for the default region."

    update =
      $set:
        project_id: project_id
        updatedBy: user_id
        regions: regions
        roles: roles
        groups: groups

    @projects_roles_and_grps_collection.update({project_id: project_id}, update, {upsert: true})

    return

  _performRegionalManagerEditsEditsObjSchema: new SimpleSchema
    roles:
      label: "Roles edits"

      optional: true

      type: [JustdoRoles.schemas.RoleRegionEditSchema]

    groups:
      label: "Groups edits"

      optional: true

      type: [JustdoRoles.schemas.GroupRegionEditSchema]

  performRegionalManagerEdits: (project_id, edits, user_id) ->
    check project_id, String
    check edits, Object

    project_doc = APP.projects.requireUserIsMemberOfProject(project_id, user_id)

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_performRegionalManagerEditsEditsObjSchema,
        edits,
        {self: @, throw_on_error: true}
      )
    edits = cleaned_val

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see PROJECT_ROLES_AND_GROUPS_INDEX there)
    #
    existing_project_roles_grps =
      @projects_roles_and_grps_collection.findOne({project_id: project_id}, {fields: {project_id: 1, regions: 1, roles: 1, groups: 1}})
    if not existing_project_roles_grps?
      throw @_error "invalid-argument", "Project #{project_id}, doesn't have a roles/grps document yet."

    regions_with_manager_privileges =
      _.map(_.filter(existing_project_roles_grps.regions, (region_def) -> user_id in region_def.managers), (region_def) -> region_def._id)

    if regions_with_manager_privileges.length == 0
      throw @_error "invalid-argument", "You aren't a manager of any regions of project #{project_id}."

    {roles, groups} = existing_project_roles_grps

    roles_changed = false
    groups_changed = false

    if edits.roles?
      for role_edit in edits.roles
        # Check that for each region, user is regional manager
        if role_edit.region_id not in regions_with_manager_privileges
          throw @_error "invalid-argument", "You aren't a manager of region #{role_edit.region_id}."

        for role in roles
          if role._id == role_edit.role_id
            found = false
            for region in role.regions
              if region._id == role_edit.region_id
                roles_changed = true

                region.uid = role_edit.uid

            if not found
              roles_changed = true

              role.regions.push {_id: role_edit.region_id, uid: role_edit.uid}

    if roles_changed
      # Remove removed regions definitions
      for role in roles
        role.regions = _.filter role.regions, (region) -> region.uid?

    if edits.groups?
      for group_edit in edits.groups
        # Check that for each region, user is regional manager
        if group_edit.region_id not in regions_with_manager_privileges
          throw @_error "invalid-argument", "You aren't a manager of group #{group_edit.region_id}."

        for group in groups
          if group._id == group_edit.group_id
            found = false
            for region in group.regions
              if region._id == group_edit.region_id
                groups_changed = true

                region.uids = group_edit.uids

            if not found
              groups_changed = true

              group.regions.push {_id: group_edit.region_id, uids: group_edit.uids}

    if groups_changed
      # Remove removed regions definitions
      for group in groups
        group.regions = _.filter group.regions, (region) -> region.uids?

    if not roles_changed and not groups_changed
      # Nothing to do
      return
    
    update = {$set: {updatedBy: user_id}}

    if roles_changed
      update.$set.roles = roles

    if groups_changed
      update.$set.groups = groups

    @projects_roles_and_grps_collection.update({project_id: project_id}, update)

    return

  projectRolesAndGrpsPublicationHandler: (publish_this, project_id, user_id) ->
    check project_id, String

    project_doc = APP.projects.requireUserIsMemberOfProject(project_id, user_id)

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see PROJECT_ROLES_AND_GROUPS_INDEX there)
    #
    return @projects_roles_and_grps_collection.find({project_id: project_id}, {fields: {project_id: 1, regions: 1, roles: 1, groups: 1}})
