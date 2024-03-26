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

      makeGuest: (project_id, member_id) ->
        check(project_id, String)
        check(member_id, String)

        projects_object.makeGuest project_id, member_id, @userId

      upgradeGuest: (project_id, guest_id) ->
        check(project_id, String)
        check(guest_id, String)

        projects_object.upgradeGuest project_id, guest_id, @userId

      removeMember: (project_id, member_id) ->
        check(project_id, String)
        check(member_id, String)

        projects_object.removeMember project_id, member_id, @userId

      bulkUpdate: (project_id, items_ids, modifier) ->
        check project_id, String
        check items_ids, [String]
        # modifier is thoroughly verified by projects_object.bulkUpdate

        projects_object.bulkUpdate project_id, items_ids, modifier, @userId

        return

      bulkUpdateTasksUsers: (project_id, options) ->
        check project_id, String
        # options is thoroughly verified by projects_object.bulkUpdateTasksUsers

        projects_object.bulkUpdateTasksUsers project_id, options, @userId

        return

      compoundBulkUpdate: (project_id, ops) ->
        check project_id, String
        # ops is thoroughly verified by projects_object.compoundBulkUpdate

        projects_object.compoundBulkUpdate project_id, ops, @userId

        return

      customCompoundBulkUpdate: (project_id, type_id, payload) ->
        check project_id, String
        check type_id, String
        # payload is thoroughly verified by projects_object.customCompoundBulkUpdate

        # IMPORTANT!!! DO NOT CALL HERE this.unblock() since we use fiber var to bypass bulk update's modifier validation.

        projects_object.customCompoundBulkUpdate project_id, type_id, payload, @userId

        return
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
      
      updateTaskDescriptionReadDate: (task_id) ->
        check task_id, String

        projects_object.updateTaskDescriptionReadDate task_id, @userId

        return

      getRootTasksAndProjects: (project_id, options) -> # projects as tasks that are marked as project, not to be confused with this task's Project terminology that changed to JustDo
        check project_id, String
        check options, Object

        return projects_object.getRootTasksAndProjects project_id, options, @userId

      handleJdCreationRequest: ->
        projects_object.handleJdCreationRequest @userId
        return