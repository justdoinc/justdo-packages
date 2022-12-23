start_date_custom_field_id = "customfield_10015"
end_date_custom_field_id = "customfield_10036"
sprint_custom_field_id = "customfield_10020"
story_point_estimate_custom_field_id = "customfield_10016"
epic_link_custom_field_id = "customfield_10109"

_.extend JustdoJiraIntegration,
  primitive_field_mappers:
    number: (justdo_id, field, destination, req_body) ->
      if not field?
        return null
      if _.isNumber field
        return field
      if _.isString field?.toString
        field = field.toString
      return parseFloat field
    date: (justdo_id, field, destination, req_body) ->
      if destination is "jira"
        return field
      if destination is "justdo"
        if _.isString field
          date = field
        if _.isString field?.to
          date = field.to
        if date?
          return moment.utc(date).format("YYYY-MM-DD")
        return null
    # NOTE: field param of option is in the format of {justdo_field_id, jira_field_id, field_val},
    # unlike other mapper functions that receives only field_val.
    # If destination is "jira", field_val is Justdo field value. Vice versa.
    select: (justdo_id, field, destination, req_body) ->
      {justdo_field_id, field_val} = field
      justdo_custom_field_def = @_getJustdoCustomFieldDef justdo_id, justdo_field_id


      if destination is "jira"
        # Unset
        if not field_val?
          return null

        field_option_def = _.find justdo_custom_field_def.field_options.select_options, (field_option) -> field_option.option_id is field_val

        return {id: field_option_def.jira_option_id}

      if destination is "justdo"
        if _.has field_val, "to"
          field_val = field_val.to
        if _.has field_val, "id"
          field_val = field_val.id

        justdo_field_val = null
        if _.isString field_val
          field_option_def = _.find justdo_custom_field_def.field_options.select_options, (field_option) -> field_option.jira_option_id is field_val
          justdo_field_val = field_option_def.option_id

        return justdo_field_val

_.extend JustdoJiraIntegration,
  # XXX Try to search for custom field ids using Jira API and store it in DB

  # XXX Cloud
  task_id_custom_field_id: "customfield_10028"
  project_id_custom_field_id: "customfield_10029"
  last_updated_custom_field_id: "customfield_10030"
  start_date_custom_field_id = "customfield_10008"
  end_date_custom_field_id = "customfield_10009"
  sprint_custom_field_id = "customfield_10020"
  epic_link_custom_field_id = "customfield_10014"

  # XXX On-perm oauth1
  # epic_link_custom_field_id = "customfield_10102"
  # task_id_custom_field_id: "customfield_10201"
  # project_id_custom_field_id: "customfield_10202"
  # last_updated_custom_field_id: "customfield_10200"
  # start_date_custom_field_id = "customfield_10203"
  # end_date_custom_field_id = "customfield_10204"
  # sprint_custom_field_id = "customfield_10106"
  # story_point_estimate_custom_field_id = "customfield_10107"
  #
  # XXX On-perm oauth2
  # epic_link_custom_field_id = "customfield_10109"
  # task_id_custom_field_id: "customfield_10201"
  # project_id_custom_field_id: "customfield_10202"
  # last_updated_custom_field_id: "customfield_10200"
  # start_date_custom_field_id = "customfield_10205"
  # end_date_custom_field_id = "customfield_10206"
  # sprint_custom_field_id = "customfield_10108"
  # story_point_estimate_custom_field_id = "customfield_10111"

  start_date_custom_field_id: start_date_custom_field_id
  end_date_custom_field_id: end_date_custom_field_id
  story_point_estimate_custom_field_id: story_point_estimate_custom_field_id
  sprint_custom_field_id: sprint_custom_field_id
  epic_link_custom_field_id: epic_link_custom_field_id

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
    [story_point_estimate_custom_field_id]: "Story Points"

  # NOTE: If you add or remove any items inside justdo_field_to_jira_field_map,
  # remember to update hardcoded_field_map in both/static.coffee!
  justdo_field_to_jira_field_map:
    title:
      name: "summary"
      type: "string"
    description:
      name: "description"
      type: "string"
    jira_sprint:
      id: sprint_custom_field_id
      name: "Sprint"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "justdo"
          updateSprintFieldOfChildTasks = (task_id, sprint_name) =>
            # Update sprint field for subtasks
            if @getIssueTypeRank(req_body.issue.fields.issuetype.name, jira_project_id) < 1
              @tasks_collection.update({project_id: justdo_id, "parents2.parent": task_doc._id}, {$set: {jira_sprint: new_sprint_name}}, {multi: true})

          # Move from old sprint parent to new sprint parent if the sprint is created as a task
          jira_issue_id = parseInt req_body.issue.id
          jira_project_id = parseInt req_body.issue.fields.project.id

          # Issue sprint field can hold multiple sprints, but one of them isn't closed at most.
          sprint_field = req_body.issue.fields[JustdoJiraIntegration.sprint_custom_field_id]
          if (active_sprint = @_getActiveSprintOfIssue sprint_field)?
            # For Jira Cloud
            if _.isString active_sprint.name
              new_sprint_id = active_sprint.id
              new_sprint_name = active_sprint.name

            # For Jira Server
            if (tokens = active_sprint.match?(/(name=[A-Za-z\s0-9]+)|(id=\d+)/g))?
              new_sprint_id = tokens[0].replace "id=", ""
              new_sprint_name = tokens[1].replace "name=", ""

            if _.isString new_sprint_id
              new_sprint_id = parseInt new_sprint_id
            new_sprint_mountpoint = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_sprint_mountpoint_id: new_sprint_id}, {fields: {_id: 1}})?._id

          if (task_doc = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_issue_id: jira_issue_id}, {fields: {_id: 1, jira_sprint: 1, parents2: 1}}))?
            grid_data = APP.projects._grid_data_com
            justdo_admin_id = @_getJustdoAdmin justdo_id

            # In case a discrepency happens, fetch the old sprint id from our db.
            if task_doc.jira_sprint? and (task_doc.jira_sprint isnt new_sprint_name)
              query =
                _id:
                  $in: _.map task_doc.parents2, (parent_obj) -> parent_obj.parent
                project_id: justdo_id
                jira_project_id: jira_project_id
                jira_sprint_mountpoint_id:
                  $ne: null
              query_options =
                fields:
                  jira_sprint_mountpoint_id: 1
              old_sprint_mountpoint = @tasks_collection.findOne(query, query_options)?._id

            # If the issue has an active sprint but it's not in our tasks collection, the sprint task is likely being reopened.
            # In this case we do nothing, as after the sprint task being created, this mapper will be called again and put the issue to the right sprint parent.
            if new_sprint_id? and not new_sprint_mountpoint?
              return task_doc.jira_sprint

            if @getIssueTypeRank(req_body.issue.fields.issuetype.name, jira_project_id) > -1
              if old_sprint_mountpoint? and new_sprint_mountpoint?
                # Relocate issue
                try
                  grid_data.movePath "/#{old_sprint_mountpoint}/#{task_doc._id}/", {parent: new_sprint_mountpoint, order: 0}, justdo_admin_id
                catch e
                  if e.error not in ["parent-already-exists", "unknown-parent"]
                    console.trace()
                    console.error "[justdo-jira-integration] Relocate issue sprint parent failed.", e
              # Remove sprint parent
              else if old_sprint_mountpoint?
                try
                  grid_data.removeParent "/#{old_sprint_mountpoint}/#{task_doc._id}/", justdo_admin_id
                catch e
                  if e.error isnt "unknown-parent"
                    console.trace()
                    console.error "[justdo-jira-integration] Remove issue sprint parnet failed.", e
              # Add sprint parent
              else if new_sprint_mountpoint?
                try
                  grid_data.addParent task_doc._id, {parent: new_sprint_mountpoint, order: 0}, justdo_admin_id
                catch e
                  if e.error isnt "parent-already-exists"
                    console.trace()
                    console.error "[justdo-jira-integration] Add issue sprint parnet failed.", e

            # Update sprint field for subtasks
            updateSprintFieldOfChildTasks task_doc._id, new_sprint_name

          return new_sprint_name or null
    jira_issue_type:
      name: "issuetype"
      mapper: (justdo_id, field, destination, req_body) ->
        jira_project_id = parseInt(req_body.jira_project_id or req_body.issue.fields.project.id)
        jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

        _moveAllChildTasksToRoadmap = (task_id) =>
          non_epic_non_subtask_issue_types = _.map @getRankedIssueTypesInJiraProject(jira_doc_id, jira_project_id)[0], (issue_type_def) -> issue_type_def.name

          child_task_ids = @tasks_collection.find({project_id: justdo_id, "parents2.parent": task_id, jira_issue_type: {$in: non_epic_non_subtask_issue_types}}, {fields: {_id: 1}}).map (task_doc) -> "/#{task_id}/#{task_doc._id}/"
          mountpoint_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_mountpoint_type: "roadmap", jira_project_id: jira_project_id, project_id: justdo_id}, {fields: {_id: 1}})?._id
          if not _.isEmpty child_task_ids
            APP.projects._grid_data_com.movePath child_task_ids, {parent: mountpoint_task_id}, @_getJustdoAdmin justdo_id
          return

        if destination is "jira"
          # If an Epic became other issue type, move all existing child to root
          if (@getIssueTypeRank(req_body.jira_issue_type, jira_project_id) is 1) and (@getIssueTypeRank(field, jira_project_id) isnt 1)
            task_id = req_body._id
            _moveAllChildTasksToRoadmap task_id
          return {name: field}

        if destination is "justdo"
          field_val = field.name or field.toString
          # If an Epic became other issue type, move all existing child to root
          if (@getIssueTypeRank(field?.fromString, jira_project_id) is 1) and (@getIssueTypeRank(field_val, jira_project_id) isnt 1)
            if not (task_id = req_body.issue.fields[JustdoJiraIntegration.task_id_custom_field_id])?
              task_id = @tasks_collection.findOne({project_id: justdo_id, jira_issue_id: parseInt req_body.issue.id}, {fields: {_id: 1}})
            _moveAllChildTasksToRoadmap task_id
          return field_val
    jira_fix_version:
      name: "fixVersions"
      mapper: (justdo_id, field, destination, req_body) ->
        if destination is "justdo"
          if _.isArray field
            return _.map field, (fix_version) -> fix_version.name
          else
            jira_issue_id = parseInt req_body.issue.id
            jira_project_id = parseInt req_body.issue.fields.project.id
            grid_data = APP.projects._grid_data_com
            justdo_admin_id = @_getJustdoAdmin justdo_id
            ops = {}

            if _.isString field.from
              old_fix_version_mountpoint = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_fix_version_mountpoint_id: parseInt field.from}, {fields: {_id: 1}})
              ops.$pull =
                jira_fix_version: field.fromString
            task_doc = @tasks_collection.findOne({jira_issue_id: jira_issue_id}, {fields: {parents2: 1}})
            if _.isString field.to
              new_fix_version_mountpoint = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_fix_version_mountpoint_id: parseInt field.to}, {fields: {_id: 1}})
              ops.$addToSet =
                jira_fix_version: field.toString
            if @getIssueTypeRank(req_body.issue.fields.issuetype.name, jira_project_id) is 1
              query = task_doc._id
            else
              query =
                project_id: justdo_id
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
                grid_data.addParent task_doc._id, {parent: new_fix_version_mountpoint._id, order: 0}, justdo_admin_id
              catch e
                if e.error isnt "parent-already-exists"
                  console.trace()
                  console.error e

            return
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
          field_val = field.name or field.toString
          field_val = field_val?.toLowerCase()
          # XXX For IT
          # jira_to_justdo_states_map =
          #   "10000": "pending"
          #   "10001": "in-progress"
          #   "10002": "done"
          # XXX For ID / company managed projects
          jira_to_justdo_states_map =
            "to do": "pending"
            "in progress": "in-progress"
            "done": "done"
          return jira_to_justdo_states_map[field_val]
        return
    owner_id:
      id: "assignee"
      mapper: (justdo_id, field, destination, req_body) ->
        if not justdo_id?
          throw @_error "justdo-id-not-found"

        if destination is "jira"
          client = @getJiraClientForJustdo(justdo_id).v2

          if not (justdo_account_email = APP.accounts.getUserById(field).emails?[0]?.address)?
            throw @_error "user-not-found"

          jira_account = @getJiraUser justdo_id, {email: justdo_account_email}
          jira_account_id = jira_account?[0]?.accountId

          req = {issueIdOrKey: req_body.jira_issue_id}
          if @isJiraInstanceCloud()
            req.accountId = jira_account_id
          else
            req.name = jira_account?[0]?.username
          {err} = @pseudoBlockingJiraApiCallInsideFiber "issues.assignIssue", req, client
          if err?
            err = err?.response?.data or err
            console.error err
          return

        if destination is "justdo"
          # Remove any pending ownership transfer
          if (task_id = req_body?.issue?.fields?[JustdoJiraIntegration.task_id_custom_field_id])?
            @tasks_collection.update task_id, {$unset: {pending_owner_id: 1}}

          # Assignee removed. Use justdo admin as task owner.
          if not (jira_account_id_or_email = field?.to or field?.accountId or field?.emailAddress)?
            return @_getJustdoAdmin justdo_id

          # Issue changelog from Jira server will not provide email address. In this case we get the user email from issue body.
          if @getAuthTypeIfJiraInstanceIsOnPerm()?
            jira_account_id_or_email = req_body.issue.fields.assignee.emailAddress

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
          jira_account_id_or_email = field.accountId or field.emailAddress or field.to
          user_id = @getJustdoUserIdByJiraAccountIdOrEmail jira_project_id, jira_account_id_or_email
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
    jira_story_point:
      id: story_point_estimate_custom_field_id
      name: "Story Points"
      mapper: JustdoJiraIntegration.primitive_field_mappers.number
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
