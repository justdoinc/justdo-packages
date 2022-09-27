data_integrity_check_rate_ms = 1000 * 60 * 5 # 5 mins

start_date_custom_field_id = "customfield_10015"
end_date_custom_field_id = "customfield_10036"
sprint_custom_field_id = "customfield_10020"
story_point_estimate_custom_field_id = "customfield_10016"
epic_link_custom_field_id = "customfield_10109"

_.extend JustdoJiraIntegration,
  access_token_update_rate_ms: 1000 * 60 * 50  # 50 mins
  webhook_connection_check_rate_ms: 1000 * 60 # 1 min
  data_integrity_check_rate_ms: data_integrity_check_rate_ms
  data_integrity_margin_of_safety: data_integrity_check_rate_ms / 5

  # XXX Try to search for custom field ids using Jira API and store it in DB

  # XXX For IT only
  # task_id_custom_field_id: "customfield_10035"
  # project_id_custom_field_id: "customfield_10034"
  # last_updated_custom_field_id: "customfield_10033"

  # XXX For ID/company-managed projects
  task_id_custom_field_id: "customfield_10028"
  project_id_custom_field_id: "customfield_10029"
  last_updated_custom_field_id: "customfield_10030"
  start_date_custom_field_id = "customfield_10008"
  end_date_custom_field_id = "customfield_10009"
  sprint_custom_field_id = "customfield_10020"

  # XXX On-perm
  # epic_link_custom_field_id: epic_link_custom_field_id
  # task_id_custom_field_id: "customfield_10113"
  # project_id_custom_field_id: "customfield_10112"
  # last_updated_custom_field_id: "customfield_10114"
  # start_date_custom_field_id = "customfield_10115"
  # end_date_custom_field_id = "customfield_10116"
  # sprint_custom_field_id = "customfield_10110"

  start_date_custom_field_id: start_date_custom_field_id
  end_date_custom_field_id: end_date_custom_field_id
  story_point_estimate_custom_field_id: story_point_estimate_custom_field_id
  sprint_custom_field_id: sprint_custom_field_id

  # XXX Maybe implement a two-way map inside JustdoHelpers?

  # justdo_field_to_jira_field_map #
  # {
  #  [key]: Field id in Justdo
  #   {
  #    id: Field id in Jira. Must exist if name isn't provided. Takes precedence before name if both are set.
  #    name: Field name in Jira. Must exist if id isn't provided. id will be used if both are set
  #    type: Determines whether to use .toString or .to in jira changelog.
  #          if a field has a mapper(), the value returned from mapper() will be used
  #          regardless of the type.
  #          For fields that aren't showing in issue.fields as string, use raw
  #      string/raw: value will be saved as-is
  #      array: the "name" property inside each object inside the incoming array
  #             will be extracted and saved as a string array
  #             XXX what if the value is numeric/date/non-string/doesn't have name property?
  #    mapper: Used by fields that require some kind of mapping. Called under the context of APP.justdo_jira_integration
  #            ***Note that it should handle both cases of issue_created and issue_updated when mapping fields from Jira
  #      - justdo_id: Justdo id that the event is related to.
  #      - field_val: The value to be mapped. Required.
  #      - destination: Accepts either "jira" or "justdo". Determines where the returned value is used. Required.
  #      - req_body:
  #          - When destination is "justdo":
  #            - The entire request body from webhook. Used to provide additional information about the Jira issue. Optional.
  #          - When destination is "jira":
  #            - The entire task doc related to the issue.
  #   }
  # }

  # Temp workaround for on-perm Jira installations that has field name/id discrepencies with Jira cloud
  alt_field_name_map:
    "Fix Version": "fixVersions"
    "Actual Start": "jd_start_date"
    "Actual End": "jd_end_date"
    "Epic Link": epic_link_custom_field_id

  justdo_field_to_jira_field_map:
    title:
      name: "summary"
      type: "string"
    description:
      name: "description"
      type: "string" # XXX Should be markdown doc instead
    jira_sprint:
      id: sprint_custom_field_id
      name: "Sprint"
      type: "string"
      # We don't current support editing sprint in Justdo.
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "justdo"
          if _.isString field[0]?.name
            return field[0].name

          # Move from old sprint parent to new sprint parent if the sprint is created as a task
          jira_issue_id = parseInt req_body.issue.id
          grid_data = APP.projects._grid_data_com
          justdo_admin_id = @_getJustdoAdmin req_body.issue.fields[JustdoJiraIntegration.project_id_custom_field_id]
          # XXX Chance for optimization
          task_doc = @tasks_collection.findOne({jira_issue_id: jira_issue_id}, {fields: {parents2: 1}})

          # Remove sprint
          if (old_sprint_mountpoint = @tasks_collection.findOne({jira_sprint_mountpoint_id: parseInt field.from}, {fields: {_id: 1}}))?
            try
              grid_data.removeParent "/#{old_sprint_mountpoint._id}/#{task_doc._id}/", justdo_admin_id
            catch e
              if e.error isnt "unknown-parent"
                console.trace()
                console.error e

          # Add sprint
          if (new_sprint_mountpoint = @tasks_collection.findOne({jira_sprint_mountpoint_id: parseInt field.to}, {fields: {_id: 1}}))?
            try
              grid_data.addParent task_doc._id, {parent: new_sprint_mountpoint._id}, justdo_admin_id
            catch e
              if e.error isnt "parent-already-exists"
                console.trace()
                console.error e

          # Update sprint field for subtasks
          if req_body.issue.fields.issuetype.name isnt "Epic"
            @tasks_collection.update({"parents2.parent": task_doc._id}, {$set: {jira_sprint: field.toString}}, {multi: true})

          return field.toString
    jira_issue_type:
      name: "issuetype"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "jira"
          return {name: field}
        if destination is "justdo"
          field_val = field.name or field.toString
          return field_val
    # We don't current support editing fix version in Justdo.
    jira_fix_version:
      name: "fixVersions"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "justdo"
          if _.isArray field
            return _.map field, (fix_version) -> fix_version.name
          else
            jira_issue_id = parseInt req_body.issue.id
            grid_data = APP.projects._grid_data_com
            justdo_admin_id = @_getJustdoAdmin req_body.issue.fields[JustdoJiraIntegration.project_id_custom_field_id]
            ops = {}

            if _.isString field.from
              old_fix_version_mountpoint = @tasks_collection.findOne({jira_fix_version_mountpoint_id: parseInt field.from}, {fields: {_id: 1}})
              ops.$pull =
                jira_fix_version: field.fromString
            task_doc = @tasks_collection.findOne({jira_issue_id: jira_issue_id}, {fields: {parents2: 1}})
            if _.isString field.to
              new_fix_version_mountpoint = @tasks_collection.findOne({jira_fix_version_mountpoint_id: parseInt field.to}, {fields: {_id: 1}})
              ops.$addToSet =
                jira_fix_version: field.toString

            if req_body.issue.fields.issuetype.name is "Epic"
              query = task_doc._id
            else
              query =
                $or: [
                  _id: task_doc._id
                ,
                  "parents2.parent": task_doc._id
                ]
            @tasks_collection.update(query, ops, {multi: true})

            if old_fix_version_mountpoint?
              try
                grid_data.removeParent "/#{old_fix_version_mountpoint._id}/#{task_doc._id}/", justdo_admin_id
              catch e
                if e.error isnt "unknown-parent"
                  console.trace()
                  console.error e
            if new_fix_version_mountpoint?
              try
                grid_data.addParent task_doc._id, {parent: new_fix_version_mountpoint._id}, justdo_admin_id
              catch e
                if e.error isnt "parent-already-exists"
                  console.trace()
                  console.error e

            return
    due_date:
      name: "duedate"
      type: "raw"
    state:
      name: "status"
      mapper: (justdo_id, field, destination, req_body) ->
        # XXX As states can be customized in Jira, consider fetching all the available states and ids instead.
        # Changing state in Jira is done by performing a transition with the corresponding state id.

        if destination is "jira"
          justdo_to_jira_states_map =
            "pending": 11
            "in-progress": 21
            "done": 31
          return justdo_to_jira_states_map[field]
        if destination is "justdo"
          field_val = field.to or field.id
          # XXX For IT
          # jira_to_justdo_states_map =
          #   "10000": "pending"
          #   "10001": "in-progress"
          #   "10002": "done"
          # XXX For ID / company managed projects
          jira_to_justdo_states_map =
            "10003": "pending"
            "3": "in-progress"
            "10004": "done"
          return jira_to_justdo_states_map[field_val]
        return
    owner_id:
      id: "assignee"
      mapper: (justdo_id, field, destination, req_body) ->
        if not justdo_id?
          throw @_error "justdo-id-not-found"

        if destination is "jira"
          client = @getJiraClientForJustdo(justdo_id).v2

          if not (justdo_account_email = Meteor.users.findOne(field, {fields: {emails: 1}})?.emails?[0]?.address)?
            throw @_error "user-not-found"

          jira_account = await @getJiraUser justdo_id, {email: justdo_account_email}
          jira_account_id = jira_account?[0]?.accountId
          # if not (jira_account_id = jira_account?[0]?.accountId)?
          #   throw @_error "jira-account-not-found"

          client.issues.assignIssue({issueIdOrKey: req_body.jira_issue_id, accountId: jira_account_id})
            .catch (err) -> console.error err

        if destination is "justdo"
          # Remove any pending ownership transfer
          if (task_id = req_body?.issue?.fields?[JustdoJiraIntegration.task_id_custom_field_id])?
            @tasks_collection.update task_id, {$unset: {pending_owner_id: 1}}

          # Assignee removed. Use justdo admin as task owner.
          if not (jira_account_id_or_email = field?.to or field?.accountId or field?.emailAddress)?
            return @_getJustdoAdmin justdo_id

          jira_project_id = parseInt req_body.issue.fields.project.id
          # This if statement shouldn't happen as we already fetched all users.
          if not (justdo_user_id = @getJustdoUserIdByJiraAccountIdOrEmail jira_project_id, jira_account_id_or_email)?
            return @_getJustdoAdmin justdo_id

          return justdo_user_id
    jira_issue_reporter:
      id: "reporter"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "justdo"
          jira_project_id = parseInt req_body.issue.fields.project.id
          jira_account_id = field.accountId or field.to
          user_id = @getJustdoUserIdByJiraAccountId jira_project_id, jira_account_id
          # If field.to exists, an issue update is performed and task_id is already in place.
          # Therefore we update activity log in place.
          # If field.accountId exists instead, a new task is being created
          # and the update on activity log will be performed in _createTaskFromJiraIssue()
          if _.isString field.to
            task_id = req_body.issue.fields[JustdoJiraIntegration.task_id_custom_field_id]
            APP.tasks_changelog_manager.logChange
              field: "jira_issue_reporter"
              label: "Issue Reporter"
              change_type: "custom"
              task_id: task_id
              by: user_id
              new_value: "became reporter"
          return user_id
    start_date:
      id: start_date_custom_field_id
      name: "Actual start"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "jira"
          return field
        if destination is "justdo"
          if _.isString field
            start_date = field
          if _.isString field.to
            start_date = field.to
          return moment.utc(start_date).format("YYYY-MM-DD")
    end_date:
      id: end_date_custom_field_id
      name: "Actual end"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "jira"
          return field
        if destination is "justdo"
          if _.isString field
            end_date = field
          if _.isString field.to
            end_date = field.to
          return moment.utc(end_date).format("YYYY-MM-DD")
    jira_story_point:
      id: story_point_estimate_custom_field_id
      name: story_point_estimate_custom_field_id
      mapper: (justdo_id, field, destination, req_body) ->
        if _.isString field.toString
          return parseFloat field.toString
        return parseFloat field
      # XXX Currently story point estimate is used as the duration which is not ideal.
      # XXX The followings are meant for mapping the field value to the actual time estimate field.
      # We store duration as days, Jira store duration as seconds
      # A day in Jira is 8 hrs by default
      # XXX Might need to consider how many hours a day is in both systems.
      # mapper: (justdo_id, field, destination, req_body) ->
        # if destination is "jira"
        #   return "#{field}d"
        #
        # if destination is "justdo"
        #   # Since 1 work day in Jira is 8 hrs, we multiply the time by 3 to get the correct parsing
        #   # And -1 second since moment will parse 86400 seconds (1 day) into 2 days.
        #   return moment.utc((field - 1) * 3 * 1000).format "D"
        # return
