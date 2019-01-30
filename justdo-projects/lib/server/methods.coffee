_.extend Projects.prototype,
  _setupMethods: ->
    projects_object = @

    Meteor.methods
      requireLogin: -> # defined in helpers.coffee
        projects_object.requireLogin @userId

      getProjectIfUserIsMember: (project_id) ->
        check(project_id, String)

        projects_object.getProjectIfUserIsMember project_id, @userId

      requireUserIsMemberOfProject: (project_id) ->
        check(project_id, String)

        projects_object.requireUserIsMemberOfProject project_id, @userId

      isProjectAdmin: (project_id) ->
        check(project_id, String)

        projects_object.isProjectAdmin project_id, @userId

      requireProjectAdmin: (project_id) ->
        check(project_id, String)

        projects_object.requireProjectAdmin project_id, @userId

      createNewProject: (options) ->
        # options are checked by createNewProject() api
        return projects_object.createNewProject options, @userId

      removeProject: (project_id) ->
        check(project_id, String)

        projects_object.removeProject project_id, @userId

      inviteMember: (project_id, invited_user) ->
        check(project_id, String)
        check(invited_user, Object) # properly checked by projects_object.inviteMember

        projects_object.inviteMember project_id, invited_user, @userId

      resendEnrollmentEmail: (project_id, invited_user_id) ->
        check(project_id, String)
        check(invited_user_id, String)

        projects_object.resendEnrollmentEmail project_id, invited_user_id, @userId

      downgradeAdmin: (project_id, member_id) ->
        check(project_id, String)
        check(member_id, String)

        projects_object.downgradeAdmin project_id, member_id, @userId

      upgradeAdmin: (project_id, member_id) ->
        check(project_id, String)
        check(member_id, String)

        projects_object.upgradeAdmin project_id, member_id, @userId

      removeMember: (project_id, member_id) ->
        check(project_id, String)
        check(member_id, String)

        projects_object.removeMember project_id, member_id, @userId

      postRegInit: ->
        projects_object.postRegInit @userId

      configureEmailUpdatesSubscriptions: (projects_ids, set_subscription_mode=true) ->
        # Args checks are taken care of by configureEmailUpdatesSubscriptions

        projects_object.configureEmailUpdatesSubscriptions projects_ids, set_subscription_mode, @userId

        return

      configureEmailNotificationsSubscriptions: (projects_ids, set_subscription_mode=true) ->
        # Args checks are taken care of by configureEmailNotificationsSubscriptions

        projects_object.configureEmailNotificationsSubscriptions projects_ids, set_subscription_mode, @userId

        return

      setProjectCustomFields: (project_id, custom_fields) ->
        check(project_id, String)

        # For custom_fields, we count on the schema validations to avoid setting wrong/malicious custom_fields

        projects_object.setProjectCustomFields project_id, custom_fields, @userId

        return

      isSubscribedToDailyEmail: (project_id) ->
        check(project_id, String)

        projects_object.isSubscribedToDailyEmail project_id, @userId

      configureProject: (project_id, configuration) ->
        check(project_id, String)
        check(configuration, Object) # Full validation is taken care of by
                                     # projects_object.configureProject()

        projects_object.configureProject project_id, configuration, @userId

        return