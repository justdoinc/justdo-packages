APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  curProj = -> module.curProj()

  _.extend JustdoRoles.prototype,
    _immediateInit: ->
      return

    _deferredInit: ->
      if @destroyed
        return

      @registerConfigTemplate()
      @setupCustomFeatureMaintainer()
      @setupProjectRolesAndGrpsSubscription()

      return

    setupCustomFeatureMaintainer: ->
      custom_feature_maintainer =
        APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoRoles.project_custom_feature_id,

        installer: =>
          @registerConfigSectionTemplate()

          return

        destroyer: =>
          @unregisterConfigSectionTemplate()

          return

      @onDestroy =>
        custom_feature_maintainer.stop()

        return

      return

    _project_roles_and_grps_subscription_comp: null
    _project_roles_and_grps_subscription: null
    setupProjectRolesAndGrpsSubscription: ->
      @_project_roles_and_grps_subscription_comp = Tracker.autorun =>
        if @isPluginEnabled()
          if (project_id = curProj().id)
            @_project_roles_and_grps_subscription = Meteor.subscribe("jdrProjectRolesAndGrps", project_id)

        return

      @onDestroy =>
        @_project_roles_and_grps_subscription_comp.stop()
        @_project_roles_and_grps_subscription_comp = null

        @_project_roles_and_grps_subscription.stop()
        @_project_roles_and_grps_subscription = null

        return

      return

    isPluginEnabled: ->
      return curProj()?.isCustomFeatureEnabled(JustdoRoles.project_custom_feature_id)

    getProjectRolesAndGrpsDoc: (project_id) ->
      return @projects_roles_and_grps_collection.findOne({project_id: project_id})

    getCurrentProjectRolesAndGrpsDoc: ->
      if not (project_id = curProj()?.id)?
        return null

      return @getProjectRolesAndGrpsDoc(project_id)

    isUserHasFullPrivilegesForActiveProject: ->
      return curProj()?.isAdmin() # Full privileges are given to project admins

    getRegionsWithRegionalManagerPrivileges: ->
      if not (roles_and_grps_doc = @getCurrentProjectRolesAndGrpsDoc())?
        return []

      return _.filter roles_and_grps_doc.regions, (region) -> Meteor.userId() in region.managers

    showRolesAndGroupsManagerDialogOpenerInProjectSettingsDropdown: ->
      return @isPluginEnabled() and (@isUserHasFullPrivilegesForActiveProject() or @getRegionsWithRegionalManagerPrivileges().length > 0)

    _roles_and_groups_manager_dialog: null
    openRolesAndGroupsManagerDialog: ->
      if @_roles_and_groups_manager_dialog?
        console.warn "Roles and groups manager dialog already open"

        return
      
      data =
        roles_and_groups_manager_controller: @getRolesAndGroupsManagerControllerForCurrentProject()

        closeRolesAndGroupsManagerDialog: ->
          $(".roles-and-groups-manager-dialog .bootbox-close-button").click()

          return

      roles_and_groups_manager =
        APP.helpers.renderTemplateInNewNode(Template.justdo_roles_and_groups_manager, data)

      @_roles_and_groups_manager_dialog = bootbox.dialog
        title: "Roles &amp; Groups Manager"
        message: roles_and_groups_manager.node
        className: "roles-and-groups-manager-dialog bootbox-new-design"

        onEscape: =>
          @_roles_and_groups_manager_dialog = null

          return true

      roles_and_groups_manager_footer =
        APP.helpers.renderTemplateInNewNode(Template.justdo_roles_and_groups_manager_footer, data)

      @_roles_and_groups_manager_dialog.find(".modal-content").append(roles_and_groups_manager_footer.node)

      return

    getRolesAndGroupsManagerControllerForCurrentProject: ->
      self = @

      return Tracker.nonreactive =>
        # While we are not even running the following code in a reactive computation,
        # I want it to be very clear, so still, used the Tracker.nonreactive

        if not (project_roles_and_grps_doc = @getCurrentProjectRolesAndGrpsDoc())?
          # If doesn't exists, use the default. NOTE!!! We assume the subscription is ready by now.
          project_roles_and_grps_doc = JustdoRoles.default_client_side_project_roles_and_groups_doc

        raw_regions = project_roles_and_grps_doc.regions
        raw_roles = project_roles_and_grps_doc.roles
        raw_groups = project_roles_and_grps_doc.groups

        user_has_full_privileges = @isUserHasFullPrivilegesForActiveProject()

        #
        # REGIONS HELPERS
        #
        getRegionController = (roles_and_groups_manager_controller, region_raw_obj) ->
          if not region_raw_obj?
            region_raw_obj = {}
          
          return {
            _id: region_raw_obj._id or Random.id()
            _label_rv: new ReactiveVar(region_raw_obj.label or "New Region")

            userCanAddOrRemoveRegions: ->
              return user_has_full_privileges and @_id != "default"

            isLabelEditable: -> user_has_full_privileges and @_id != "default"

            changed: false

            setLabel: (label) ->
              if not @isLabelEditable()
                console.warn "Only admins can edit labels"

                return

              if @_id == "default"
                console.warn "The default region's label can't be changed."

                return

              @_label_rv.set(label)

              @changed = true

              return

            getLabel: ->
              return @_label_rv.get()

            regionalManagersEditable: -> user_has_full_privileges

            showRegionalManagers: -> @regionalManagersEditable()

            _managers_dep: new Tracker.Dependency()
            _managers: (region_raw_obj.managers or []).slice()

            setManagers: (managers) ->
              if not @regionalManagersEditable()
                console.warn "Only admins can edit labels"

                return

              @_managers = managers
              @_managers_dep.changed()

              @changed = true

              return

            getManagers: ->
              @_managers_dep.depend()

              project_members =
                curProj()?.getMembersIds() or []

              # Remove from @_managers users that aren't project memebrs anymore.
              managers = _.intersection(project_members, @_managers)

              return managers

            removeRegion: ->
              roles_and_groups_manager_controller.removeRegion(@_id)

              return
          }

        if user_has_full_privileges
          content_editable_regions = raw_regions
          content_editable_regions_ids = _.map content_editable_regions, (region) -> region._id
        else
          content_editable_regions = @getRegionsWithRegionalManagerPrivileges()
          content_editable_regions_ids = _.map content_editable_regions, (region) -> region._id

        #
        # ROLES HELPERS
        #
        getRoleController = (roles_and_groups_manager_controller, role_raw_object) ->
          if not role_raw_object?
            role_raw_object = {}

          # Every role must, at the minimum has a value for the default region.
          if not role_raw_object.regions? or _.isEmpty(role_raw_object.regions)
            role_raw_object.regions = [{_id: "default", uid: Meteor.userId()}]

          return {
            _id: role_raw_object._id or Random.id()
            _label_rv: new ReactiveVar(role_raw_object.label or "New role")

            userCanAddOrRemoveRoles: ->
              return user_has_full_privileges

            isLabelEditable: -> user_has_full_privileges

            changed: false

            setLabel: (label) ->
              if not @isLabelEditable()
                console.warn "Only admins can edit labels"

                return

              @_label_rv.set(label)

              @changed = true

              return

            getLabel: ->
              return @_label_rv.get()

            _regions_dep: new Tracker.Dependency()
            _regions: _.object(_.map(_.filter(role_raw_object.regions, (region_to_role) -> region_to_role._id in content_editable_regions_ids), (region_to_role) -> [region_to_role._id, region_to_role.uid]))

            setRegionValue: (region_id, value) ->
              @_regions[region_id] = value
              @_regions_dep.changed()

              @changed = true

              return

            getRegions: ->
              @_regions_dep.depend()

              return @_regions

            clearRegionValue: (region_id) ->
              if region_id == "default"
                console.warn "A value for the default region must be set for every role."

              delete @_regions[region_id]
              @_regions_dep.changed()

              return

            getRegionsValueControllers: ->
              role_controller_self = @

              region_value_controllers = []

              regions = @getRegions()

              for region_controller in roles_and_groups_manager_controller.getRegions()
                do (region_controller) =>
                  uid = regions[region_controller._id]

                  controller =
                    has_value: uid?

                    setUser: ->
                      options =
                        title: "Select user"
                        selected_user: uid or Meteor.userId()

                      ProjectPageDialogs.selectProjectUser options, (res) ->
                        if _.isString res
                          role_controller_self.setRegionValue(region_controller._id, res)

                        return

                      return 

                  if controller.has_value
                    _.extend controller,
                      uid: uid
                      region_id: region_controller._id
                      user: JustdoHelpers.getUsersDocsByIds(uid)
                      user_can_be_removed: region_controller._id != "default"
                      clearRegionValue: ->
                        role_controller_self.clearRegionValue(region_controller._id)

                        return
                      isUserMemberOfProject: ->
                        project_members_ids = curProj()?.getMembersIds() or []
                        
                        return uid in project_members_ids

                  region_value_controllers.push controller

              return region_value_controllers

            removeRole: ->
              roles_and_groups_manager_controller.removeRole(@_id)

              return
          }

        #
        # GROUPS HELPERS
        #
        getGroupController = (roles_and_groups_manager_controller, group_raw_object) ->
          if not group_raw_object?
            group_raw_object = {}

          return {
            _id: group_raw_object._id or Random.id()
            _label_rv: new ReactiveVar(group_raw_object.label or "New group")

            userCanAddOrRemoveGroups: ->
              return user_has_full_privileges

            isLabelEditable: -> user_has_full_privileges

            changed: false

            setLabel: (label) ->
              if not @isLabelEditable()
                console.warn "Only admins can edit labels"

                return

              @_label_rv.set(label)

              @changed = true

              return

            getLabel: ->
              return @_label_rv.get()

            _regions_dep: new Tracker.Dependency()
            _regions: _.object(_.map(_.filter(group_raw_object.regions, (region_to_group) -> region_to_group._id in content_editable_regions_ids), (region_to_group) -> [region_to_group._id, region_to_group.uids]))

            setRegionValue: (region_id, value) ->
              @_regions[region_id] = value
              @_regions_dep.changed()

              @changed = true

              return

            getRegions: ->
              @_regions_dep.depend()

              return @_regions

            clearRegionValue: (region_id) ->
              delete @_regions[region_id]
              @_regions_dep.changed()

              return

            getRegionsValueControllers: ->
              group_controller_self = @

              region_value_controllers = []

              regions = @getRegions()

              for region_controller in roles_and_groups_manager_controller.getRegions()
                do (region_controller) =>
                  uids = regions[region_controller._id]

                  controller =
                    has_value: _.isArray(uids)

                    setUsers: ->
                      options = 
                        title: "Select group members"
                        selected_users: uids or []
                        submit_label: "Set members"
                        none_selected_text: "No group members selected"

                      ProjectPageDialogs.selectMultipleProjectUsers options, (res) =>
                        if _.isArray(res)
                          if _.isEmpty(res)
                            group_controller_self.clearRegionValue(region_controller._id)
                          else
                            group_controller_self.setRegionValue(region_controller._id, res)

                        return

                      return 

                  if controller.has_value
                    _.extend controller,
                      uids: uids
                      region_id: region_controller._id
                      getUsers: ->
                        return _.map JustdoHelpers.getUsersDocsByIds(uids), (user_doc) ->
                          _.extend user_doc,
                            region_id: controller.region_id

                            setUsers: -> controller.setUsers()

                            removeUser: ->
                              uids_without_me = _.filter uids, (uid) -> uid != user_doc._id

                              if _.isEmpty(uids_without_me)
                                group_controller_self.clearRegionValue(region_controller._id)
                              else
                                group_controller_self.setRegionValue(region_controller._id, uids_without_me)

                              return

                            isUserMemberOfProject: ->
                              project_members_ids = curProj()?.getMembersIds() or []
                              
                              return user_doc._id in project_members_ids

                          return user_doc

                      clearRegionValue: ->
                        group_controller_self.clearRegionValue(region_controller._id)

                        return

                  region_value_controllers.push controller

              return region_value_controllers

            removeGroup: ->
              roles_and_groups_manager_controller.removeGroup(@_id)

              return
          }

        #
        # *THE* CONTROLLER
        #

        roles_and_groups_manager_controller = {}

        _.extend roles_and_groups_manager_controller,
          user_has_full_privileges: user_has_full_privileges

          #
          # REGIONS
          #

          _regions_controllers_dep: new Tracker.Dependency()
          _regions_controllers: _.map content_editable_regions, (region) -> getRegionController(roles_and_groups_manager_controller, region)
          _regions_list_changed: false

          getRegions: ->
            @_regions_controllers_dep.depend()

            return @_regions_controllers

          userCanAddOrRemoveRegions: -> @user_has_full_privileges

          removeRegion: (region_id) ->
            if not @userCanAddOrRemoveRegions()
              console.warn "Only admins can remove regions"

              return

            if region_id == "default"
              console.warn "The default region can't be removed."

              return

            @_regions_controllers =
              _.filter @_regions_controllers, (region_controller) -> region_controller._id != region_id

            @_regions_controllers_dep.changed()
            @_regions_list_changed = true

            return

          addRegion: (region_settings) ->
            if not @userCanAddOrRemoveRegions()
              console.warn "Only admins can remove regions"

              return

            @_regions_controllers.push(getRegionController(roles_and_groups_manager_controller, region_settings))

            @_regions_controllers_dep.changed()
            @_regions_list_changed = true

            return

          #
          # ROLES
          #
          _roles_controllers_dep: new Tracker.Dependency()
          _roles_controllers: _.map raw_roles, (role) -> getRoleController(roles_and_groups_manager_controller, role)
          _roles_list_changed: false

          getRoles: ->
            @_roles_controllers_dep.depend()

            return @_roles_controllers

          userCanAddOrRemoveRoles: -> @user_has_full_privileges

          removeRole: (role_id) ->
            if not @userCanAddOrRemoveRoles()
              console.warn "Only admins can remove roles"

              return

            @_roles_controllers =
              _.filter @_roles_controllers, (region_controller) -> region_controller._id != role_id

            @_roles_controllers_dep.changed()
            @_roles_list_changed = true

            return

          addRole: (role_settings) ->
            if not @userCanAddOrRemoveRoles()
              console.warn "Only admins can remove regions"

              return

            @_roles_controllers.push(getRoleController(roles_and_groups_manager_controller, role_settings))

            @_roles_controllers_dep.changed()
            @_roles_list_changed = true

            return

          #
          # GROUPS
          #
          _groups_controllers_dep: new Tracker.Dependency()
          _groups_controllers: _.map raw_groups, (group) -> getGroupController(roles_and_groups_manager_controller, group)
          _groups_list_changed: false

          getGroups: ->
            @_groups_controllers_dep.depend()

            return @_groups_controllers

          userCanAddOrRemoveGroups: -> @user_has_full_privileges

          removeGroup: (group_id) ->
            if not @userCanAddOrRemoveGroups()
              console.warn "Only admins can remove groups"

              return

            @_groups_controllers =
              _.filter @_groups_controllers, (region_controller) -> region_controller._id != group_id

            @_groups_controllers_dep.changed()
            @_groups_list_changed = true

            return

          addGroup: (group_settings) ->
            if not @userCanAddOrRemoveGroups()
              console.warn "Only admins can remove regions"

              return

            @_groups_controllers.push(getGroupController(roles_and_groups_manager_controller, group_settings))

            @_groups_controllers_dep.changed()
            @_groups_list_changed = true

            return

          #
          # TABS
          #
          current_tab_rv: new ReactiveVar "roles"

          setCurrentTab: (tab) ->
            return @current_tab_rv.set(tab)

          getCurrentTab: ->
            return @current_tab_rv.get()

          getObjForSetProjectRolesAndGroupsMethod: ->
            obj = {
              regions: []
              roles: []
              groups: []
            }

            for region in @getRegions()
              obj.regions.push({_id: region._id, label: region.getLabel(), managers: region.getManagers()})

            for role in @getRoles()
              obj.roles.push({_id: role._id, label: role.getLabel(), regions: _.map(role.getRegions(), (uid, region_id) -> {_id: region_id, uid: uid})})

            for group in @getGroups()
              obj.groups.push({_id: group._id, label: group.getLabel(), regions: _.map(group.getRegions(), (uids, region_id) -> {_id: region_id, uids: uids})})

            return obj

          getEditsArrayForPerformRegionalManagerEditsMethod: ->
            edits = {roles: [], groups: []}

            for role in @getRoles()
              role_regions = role.getRegions()

              for region_id in content_editable_regions_ids
                if (uid = role_regions[region_id])?
                  edits.roles.push({region_id: region_id, role_id: role._id, uid: uid})
                else
                  edits.roles.push({region_id: region_id, role_id: role._id, uid: null})

            for group in @getGroups()
              group_regions = group.getRegions()

              for region_id in content_editable_regions_ids
                if (uids = group_regions[region_id])?
                  edits.groups.push({region_id: region_id, group_id: group._id, uids: uids})
                else
                  edits.groups.push({region_id: region_id, group_id: group._id, uids: null})

            return edits

        return roles_and_groups_manager_controller

  return