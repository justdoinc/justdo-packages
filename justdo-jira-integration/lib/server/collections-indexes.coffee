_.extend JustdoJiraIntegration.prototype,
  _ensureIndexesExists: ->
    # TASKS_COLLECTION_JIRA_ISSUE_KEY_INDEX
    @tasks_collection.rawCollection().createIndex({jira_issue_key: 1})

    # TASKS_COLLECTION_JIRA_SPRINT_MOUNTPOINT_ID_INDEX
    @tasks_collection.rawCollection().createIndex({jira_sprint_mountpoint_id: 1})

    # TASKS_COLLECTION_JIRA_FIX_VERSION_MOUNTPOINT_ID_INDEX
    @tasks_collection.rawCollection().createIndex({jira_fix_version_mountpoint_id: 1})

    # PROJECTS_COLLECTION_JIRA_PROJECT_KEY_INDEX
    @projects_collection.rawCollection().createIndex({"justdo_jira_integration.mounted_tasks.jira_project_key": 1})

    # PROJECTS_COLLECTION_JIRA_PROJECT_ID_INDEX
    @projects_collection.rawCollection().createIndex({"justdo_jira_integration.mounted_tasks.jira_project_id": 1})

    # PROJECTS_COLLECTION_MOUNTED_TASK_ID_INDEX
    @projects_collection.rawCollection().createIndex({"justdo_jira_integration.mounted_tasks.task_id": 1})

    # JIRA_COLLECTION_MOUNTED_JUSTDO_IDS_INDEX
    @jira_collection.rawCollection().createIndex({justdo_ids: 1})
    # PROJECTS_COLLECTION_JIRA_DOC_ID_INDEX
    @jira_collection.rawCollection().createIndex({[JustdoJiraIntegration.projects_collection_jira_doc_id]: 1})

    return
