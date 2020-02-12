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
      required_actions_subscription: self.modules.required_actions.subscribe(project_id)
      stopped: false

      getProjectDoc: (options) ->
        self.getProjectDoc(project_id, options)

      updateProjectDoc: (update_op) ->
        # Set removeEmptyStrings to false so empty title won't result
        # in exception when attempting to remove the title key, which
        # is a mandatory key
        self.projects_collection.update(project_id, update_op, {removeEmptyStrings: false})

      isAdmin: ->
        res = self.projects_collection.findOne(
          _id: project_id
          members: 
            $elemMatch:
              user_id: Meteor.userId()
              is_admin: true
        )

        if res?
          return true
        else
          return false

      isGuest: -> not JD.activeJustdo({members: 1}).members?

      membersCount: ->
        @getProjectDoc()?.members?.length

      getMembers: ->
        if not (project_doc = @getProjectDoc())?
          return []

        if (members = project_doc.members)?
          return members

        return [{user_id: Meteor.userId(), is_admin: false, is_guest: true}] # This will happen only for guests

      getMembersIds: (options) -> self.getProjectMembersIds(@id, options)

      getAdmins: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return member.is_admin and (include_non_enrolled or Meteor.users.findOne(member.user_id)?.enrolled_member)

      getNonAdmins: (include_non_enrolled=true) ->
        return _.filter @getMembers(), (member) ->
          return not member.is_admin and (include_non_enrolled or Meteor.users.findOne(member.user_id)?.enrolled_member)

      getNonEnrolledMembers: ->
        return _.filter @getMembers(), (member) -> not Meteor.users.findOne(member.user_id)?.enrolled_member

      isUntitled: ->
        project_title = @getProjectDoc()?.title

        if not(project_title?) or _.isEmpty(project_title.trim()) or project_title == self._default_project_name
          return true

        return false

      downgradeAdmin: (member_id, cb) ->
        Meteor.call "downgradeAdmin", @id, member_id, (err) ->
          cb(err)

      upgradeAdmin: (member_id, cb) ->
        Meteor.call "upgradeAdmin", @id, member_id, (err) ->
          cb(err)

      inviteMember: (invited_user, cb) ->
        Meteor.call "inviteMember", @id, invited_user, (err, user_id) ->
          cb(err, user_id)

      bulkUpdate: (items_ids, modifier, cb) -> 
        Meteor.call "bulkUpdate", @id, items_ids, modifier, (err) ->
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
        return @getProjectDoc()?.custom_fields or []

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
          Meteor.user()?.justdo_projects?.daily_email_projects_array

        if _.isArray(daily_email_projects_array) and @id in daily_email_projects_array
          return true

        return false

      isSubscribedToEmailNotifications: ->
        prevent_notifications_for_array =
          Meteor.user()?.justdo_projects?.prevent_notifications_for

        if not _.isArray(prevent_notifications_for_array) or @id not in prevent_notifications_for_array
          return true

        return false

      subscribeToEmailNotifications: (subscribe=true, cb) ->
        self.configureEmailNotificationsSubscriptions(@id, subscribe, cb)

        return

      stop: ->
        if not @stopped
          @stopped = true

          @tasks_subscription.stop()
          @tickets_queue_subscription.stop()
          @required_actions_subscription.stop()

          self.logger.debug "Project #{project_id} subscription stopped"

      # For elaborate discussion about prereqs see operations_prereq.coffee
      # under grid-control package.
      prereqs:
        projectHasTicketsQueues: (prereq) =>
          self.modules.tickets_queues.opreqProjectHasTicketsQueues(prereq)

    return project_obj