isUserIdEnrolled = (user_id) ->
  return JustdoHelpers.getUserDocById(user_id, {get_docs_by_reference: true})?.enrolled_member

_.extend Projects.prototype,
  loadProject: (project_id) ->
    self = @

    # Fetch only the id field to trigger reactivity in related computations only
    # if the project document removed.
    if not (self.projects_collection.findOne({_id: project_id}, {fields: {_id: 1}}))?
      throw @_error "unknown-project"

    project_obj =
      # Note @ sign refers to project_obj here, use self for the Projects obj
      id: project_id
      projects_obj: self
      tasks_subscription: self.requireProjectTasksSubscription(project_id)
      tickets_queue_subscription: self.modules.tickets_queues.subscribe(project_id)
      active_task_augmented_users_field_auto_subscription: self.activeTaskAugmentedUsersFieldAutoSubscription()

      is_admin_rv: new ReactiveVar false # See below is_admin_computation

      stopped: false

      getProjectDoc: (options) ->
        if not options?
          options = {}
        if not options.fields?
          if options.allow_undefined_fields == true
            options.fields = undefined
          else
            # This line should be:
            # throw new Meteor.Error "fields-not-specified", "Fields parameters must be provide"
            console.error "fields option must be specified" 

        self.getProjectDoc(project_id, options)

      updateProjectDoc: (update_op) ->
        # Set removeEmptyStrings to false so empty title won't result
        # in exception when attempting to remove the title key, which
        # is a mandatory key
        self.projects_collection.update(project_id, update_op, {removeEmptyStrings: false})

      isAdmin: -> @is_admin_rv.get()

      isGuest: -> not JD.activeJustdo({members: 1})?.members?

      membersCount: ->
        @getProjectDoc({fields: {members: 1}})?.members?.length

      getMembers: ->
        if not (project_doc = @getProjectDoc({fields: {members: 1}}))?
          return []

        if (members = project_doc.members)?
          return members

        return [{user_id: Meteor.userId(), is_admin: false, is_guest: true}] # This will happen only for guests

      getMembersIds: (options) -> self.getProjectMembersIds(@id, options)

      getMembersDocs: (get_project_members_ids_options, get_users_docs_by_ids_options) ->
        members_ids = @getMembersIds(get_project_members_ids_options)

        get_users_docs_by_ids_options = _.extend {user_fields_reactivity: false, missing_users_reactivity: true, ret_type: "array", get_docs_by_reference: true}, get_users_docs_by_ids_options

        members_docs = JustdoHelpers.getUsersDocsByIds(members_ids, get_users_docs_by_ids_options)

        return members_docs

      getAdmins: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return not member.is_guest and member.is_admin and (include_non_enrolled or isUserIdEnrolled(member.user_id))

      getNonAdmins: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return not member.is_admin and (include_non_enrolled or isUserIdEnrolled(member.user_id))

      getNonAdminsNonGuests: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return not member.is_admin and (not member.is_guest? or not member.is_guest) and (include_non_enrolled or isUserIdEnrolled(member.user_id))

      getGuests: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return member.is_guest and (include_non_enrolled or isUserIdEnrolled(member.user_id))

      getNonEnrolledMembers: ->
        return _.filter @getMembers(), (member) -> not Meteor.users.findOne(member.user_id, {fields: {enrolled_member: 1}})?.enrolled_member

      isUntitled: ->
        project_title = @getProjectDoc({fields: {title: 1}})?.title

        if not(project_title?) or _.isEmpty(project_title.trim()) or project_title == self._default_project_name
          return true

        return false

      downgradeAdmin: (member_id, cb) ->
        Meteor.call "downgradeAdmin", @id, member_id, (err) ->
          cb(err)

      upgradeAdmin: (member_id, cb) ->
        Meteor.call "upgradeAdmin", @id, member_id, (err) ->
          cb(err)

      makeGuest: (member_id, cb) ->
        Meteor.call "makeGuest", @id, member_id, (err) ->
          cb(err)

      upgradeGuest: (guest_id, cb) ->
        Meteor.call "upgradeGuest", @id, guest_id, (err) ->
          cb(err)

      inviteMember: (invited_user, cb) ->
        Meteor.call "inviteMember", @id, invited_user, (err, user_id) ->
          cb(err, user_id)

      bulkUpdate: (items_ids, modifier, cb) -> 
        Meteor.call "bulkUpdate", @id, items_ids, modifier, (err) ->
          return JustdoHelpers.callCb cb, err

        return

      compoundBulkUpdate: (ops, cb) -> 
        Meteor.call "compoundBulkUpdate", @id, ops, (err) ->
          return JustdoHelpers.callCb cb, err

        return

      customCompoundBulkUpdate: (type_id, payload, cb) -> 
        Meteor.call "customCompoundBulkUpdate", @id, type_id, payload, (err) ->
          return JustdoHelpers.callCb cb, err

        return

      removeMember: (member_id, cb) -> 
        Meteor.call "removeMember", @id, member_id, (err) ->
          cb(err)

      setProjectMode: (mode, cb) ->
        Meteor.call "setProjectMode", @id, mode, (err) ->
          cb(err)

      removeProject: (cb) -> 
        Meteor.call "removeProject", @id, (err) ->
          cb(err)

      configureProject: (conf_updates, cb) -> 
        self.configureProject @id, conf_updates, (err) ->
          if _.isFunction cb
            cb(err)

      setProjectCustomFields: (custom_fields, cb) -> 
        Meteor.call "setProjectCustomFields", @id, custom_fields, (err) ->
          cb(err)

          return

        return

      getProjectCustomFields: ->
        return @getProjectDoc({fields: {custom_fields: 1}})?.custom_fields or []

      getProjectConfiguration: ->
        # Returns all the projects conf and not a specific one
        # since we want to avoid confusion regarding when reactivity
        # will be triggered.
        res = @getProjectDoc({fields: {"conf": 1}})

        if not res?.conf?
          return {}

        return res.conf

      getProjectConfigurationSetting: (setting) ->
        # Returns a specifc configuration setting undefined if the
        # setting or any of the resources required to obtain it
        # doesn't exist.
        #
        # Note, reactivity will be triggered on change of any of
        # the project settings and not only for the specific one
        # requested.
        return @getProjectConfiguration()?[setting]

      enableCustomFeatures: (features) ->
        if not features?
          self.logger.error "enableCustomFeature: no features provided"

          return

        if _.isString(features)
          features = [features]

        if not _.isArray(features)
          self.logger.error "enableCustomFeature: features should be an array or a string"

          return

        if _.isEmpty(features)
          self.logger.error "enableCustomFeature: features can't be empty"

          return

        current_custom_features =
          @getProjectConfigurationSetting("custom_features") or []

        @configureProject
          custom_features: _.union(current_custom_features, features)

        return

      disableCustomFeatures: (features) ->
        if not features?
          self.logger.error "disableCustomFeature: no features provided"

          return

        if _.isString(features)
          features = [features]

        if not _.isArray(features)
          self.logger.error "disableCustomFeature: features should be an array or a string"

          return

        if _.isEmpty(features)
          self.logger.error "disableCustomFeature: features can't be empty"

          return

        current_custom_features =
          @getProjectConfigurationSetting("custom_features") or []

        @configureProject
          custom_features: _.difference(current_custom_features, features)

        return 

      isCustomFeatureEnabled: (feature) ->
        if feature is "INTEGRAL"
          return true

        # !!!IMPORTANT!!!
        # Reactivity triggered on any change to project
        # configuration!
        if not _.isString(feature)
          self.logger.error "enableCustomFeature: features should be an array or a string"

          return false

        if not (custom_features = @getProjectConfigurationSetting("custom_features"))?
          # No custom features for this project
          return false

        return feature in custom_features

      subscribeToDailyEmail: (subscribe=true, cb) ->
        self.configureEmailUpdatesSubscriptions(@id, subscribe, cb)

        return

      isSubscribedToDailyEmail: ->
        daily_email_projects_array =
          Meteor.user({fields: {"justdo_projects.daily_email_projects_array": 1}})?.justdo_projects?.daily_email_projects_array

        if _.isArray(daily_email_projects_array) and @id in daily_email_projects_array
          return true

        return false

      isSubscribedToEmailNotifications: ->
        prevent_notifications_for_array =
          Meteor.user({fields: {"justdo_projects.prevent_notifications_for": 1}})?.justdo_projects?.prevent_notifications_for

        if not _.isArray(prevent_notifications_for_array) or @id not in prevent_notifications_for_array
          return true

        return false

      subscribeToEmailNotifications: (subscribe=true, cb) ->
        self.configureEmailNotificationsSubscriptions(@id, subscribe, cb)

        return

      _schemaStateDefToStateDef: (state_id, schema_state_def) ->
        state_def =
          state_id: state_id
          txt: schema_state_def.txt
          bg_color: schema_state_def.bg_color
          order: schema_state_def.order

        return state_def

      _sortStatesArrayByOrderRemoveOrderField: (states_array) ->
        states_array = _.sortBy states_array, "order"

        states_array = _.map states_array, (state_def) ->
          delete state_def.order
          return state_def

        return states_array

      _getDefaultCustomStates: ->
        states_def = []

        for state_id, schema_state_def of APP.collections.Tasks.simpleSchema()._schema.state.grid_values
          if state_id == "nil"
            continue

          states_def.push @_schemaStateDefToStateDef(state_id, schema_state_def)

        states_def = @_sortStatesArrayByOrderRemoveOrderField(states_def)

        return states_def

      getCustomStates: ->
        if not (custom_states = @getProjectConfigurationSetting("custom_states"))?
          return @_getDefaultCustomStates()

        return custom_states

      getHiddenCustomStates: ->
        current_custom_states_ids = _.map @getCustomStates(), (state_def) -> state_def.state_id

        hidden_states_defs = []
        for state_id, schema_state_def of APP.collections.Tasks.simpleSchema()._schema.state.grid_values
          if state_id in current_custom_states_ids or state_id == "nil"
            continue

          hidden_states_defs.push @_schemaStateDefToStateDef(state_id, schema_state_def)

        hidden_states_defs = @_sortStatesArrayByOrderRemoveOrderField(hidden_states_defs)

        return hidden_states_defs

      setCustomStates: (states_array) ->
        @configureProject
          custom_states: states_array

        return

      stop: ->
        if not @stopped
          @stopped = true

          @tasks_subscription.stop()
          @tickets_queue_subscription.stop()
          @active_task_augmented_users_field_auto_subscription.stop()
          @is_admin_computation.stop()

          self.logger.debug "Project #{project_id} subscription stopped"

      # For elaborate discussion about prereqs see operations_prereq.coffee
      # under grid-control package.
      prereqs:
        projectHasTicketsQueues: (prereq) =>
          self.modules.tickets_queues.opreqProjectHasTicketsQueues(prereq)

    project_obj.is_admin_computation = Tracker.autorun ->
      # Add fields, to avoid invalidation on project doc changes
      res = self.projects_collection.findOne(
        {
          _id: project_id
          members: 
            $elemMatch:
              user_id: Meteor.userId()
              is_admin: true
        },
        {fields: {_id: 1}}
      )

      if res?
        project_obj.is_admin_rv.set true
      else
        project_obj.is_admin_rv.set false

      return

    return project_obj

  ensureAllMembersPublicBasicUsersInfoLoaded: (cb) ->
    members = @getProjectMembersIds JD.activeJustdoId()
    @ensureUsersPublicBasicUsersInfoLoaded members, cb
    return
