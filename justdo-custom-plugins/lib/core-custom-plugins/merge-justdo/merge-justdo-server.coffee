Meteor.methods
  "jdCustomMergeJustdo": (target_justdo_id, source_justdo_id) ->
    check target_justdo_id, String
    check source_justdo_id, String

    if target_justdo_id == source_justdo_id
      throw new Meteor.Error "cannot-merge-self"
    
    source_justdo = APP.collections.Projects.findOne source_justdo_id,
      members:
        $elemMatch:
          user_id: @userId
          is_admin: true
    ,
      fields:
        _id: 1
        title: 1

        custom_fields: 1
        members: 1
        "conf.custom_features": 1

    target_justdo = APP.collections.Projects.findOne target_justdo_id,
      members:
        $elemMatch:
          user_id: @userId
          is_admin: true
      fields:
        _id: 1

        members: 1
    
    # Check if user is admin of all justdos
    if not target_justdo? or not source_justdo?
      throw new Meteor.Error "justdos-not-found"

    container_task_id = APP.projects._grid_data_com.addChild(
      "/"
    ,
      project_id: target_justdo_id
      title: "Merged from #{source_justdo.title}"
    ,
      @userId
    )

    source_justdo_tasks_cursor = APP.collections.Tasks.find
      project_id: source_justdo._id
      _raw_removed_date: null
    ,
      fields:
        _id: 1
        seqId: 1
        parents: 1
        justdo_task_dependencies: 1
      sort:
        seqId: 1

    source_justdo_tasks_count = source_justdo_tasks_cursor.count()
    
    # Allocate sequence IDs for the tasks we are about to merge by incrementing
    # the target project lastTaskSeqId
    result = APP.collections.Projects.findAndModify
      query:
        _id: target_justdo_id
      fields:
        lastTaskSeqId: 1
      update:
        $inc: 
          lastTaskSeqId: source_justdo_tasks_count

    current_task_seqId = result?.value?.lastTaskSeqId + 1
    seqIds_map = {}
    tasks_with_dependencies = []
    root_order = 0

    craftUpdateOp = (task, new_task_dependencies_array) ->
      update_obj = 
        $set:
          seqId: seqIds_map[task.seqId]
          project_id: target_justdo_id

        $currentDate:
          _raw_updated_date: true
          _raw_updated_date_sans_users: true
          _raw_updated_date_only_users: true

      # task.root_order conveys two meanings:
      # 1. This task is in the root of the source_justdo, and
      # 2. The order for this task under the target_justdo container_task_id
      #    should be task.root_order
      if task.root_order?
        update_obj.$set["parents.#{container_task_id}"] = 
          order: task.root_order
        update_obj.$unset = 
          "parents.0": ""
      
      if new_task_dependencies_array?
        update_obj.$set.justdo_task_dependencies = new_task_dependencies_array

      update_op =
        updateOne:
          filter:
            _id: task._id
          update: update_obj

      return update_op


    bulk_write_ops = []

    source_justdo_tasks_cursor.forEach (task) ->
      seqIds_map[task.seqId] = current_task_seqId
      current_task_seqId += 1

      if task.parents?[0]?
          task.root_order = root_order
          root_order += 1

      if task.justdo_task_dependencies? and _.isArray(task.justdo_task_dependencies)
        # The bulk_write_op for tasks with dependencies will be added after all seqId are mapped
        # to a new one.
        tasks_with_dependencies.push task

        return

      bulk_write_ops.push craftUpdateOp task # Using bulkWrite here because every task will have a different new seqId and justdo_task_dependencies

      return

    _.each tasks_with_dependencies, (task) ->
      update_op = craftUpdateOp task, _.map(task.justdo_task_dependencies, (dep_seq_id) ->
        return seqIds_map[dep_seq_id]
      )
      
      bulk_write_ops.push update_op

      return

    updateJustdoIdInCollections = (collections, update_extensions) ->
      for collection in collections
        if collection?
          query =
            project_id: source_justdo_id

          update = _.extend
            $set:
              project_id: target_justdo_id
          , (update_extensions or {})

          options =
            multi: true

          do (collection) ->
            APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "update", query, update, options)
            collection.rawCollection().update query, update, options, Meteor.bindEnvironment (err) ->
              if err?
                console.error "As part of Merge of source_justdo_id=#{source_justdo_id}, #{collection._name} merge command failed"

              return

            return

      
      return

    postBulkWriteOps = ->
      updateJustdoIdInCollections [
        APP.collections.RpTasksResources,
        APP.collections.JDChatChannels,
        APP.collections.Formulas,
        APP.meetings_manager_plugin?.meetings_manager?.meetings
        APP.collections.TasksChangelog
      ], null

      updateJustdoIdInCollections [APP.collections.TasksPrivateData],
        $currentDate:
          _raw_updated_date: true

    if _.isEmpty(bulk_write_ops)
      postBulkWriteOps()
    else
      APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.Tasks._name, "bulkWrite")
      APP.collections.Tasks.rawCollection().bulkWrite bulk_write_ops, Meteor.bindEnvironment (err) ->
        if err?
          console.error("Merge operation failed (source_justdo_id: #{source_justdo_id})", err)

          return

        postBulkWriteOps()

        return

    target_update = {}

    if _.isArray(source_custom_features = source_justdo?.conf?.custom_features)
      Meteor._ensure target_update, "$addToSet"
      target_update.$addToSet["conf.custom_features"] = {$each: source_custom_features}

    if _.isArray(source_custom_fields = source_justdo?.custom_fields)
      Meteor._ensure target_update, "$push"
      target_update.$push["custom_fields"] = {$each: source_custom_fields}

    target_justdo_users_ids = {}
    for member_def in target_justdo.members
      target_justdo_users_ids[member_def.user_id] = true

    members_items_to_push_to_target = []
    for member_def in source_justdo.members
      if member_def.user_id not of target_justdo_users_ids
        member_def.is_admin = false # We downgrade admins when moving them to target
        members_items_to_push_to_target.push member_def


    if not _.isEmpty(members_items_to_push_to_target)
      Meteor._ensure target_update, "$push"
      target_update.$push["members"] = {$each: members_items_to_push_to_target}

    APP.collections.Projects.update(target_justdo_id, target_update)

    return container_task_id
