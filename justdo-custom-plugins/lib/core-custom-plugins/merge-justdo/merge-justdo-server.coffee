Meteor.methods
  "jdCustomMergeJustdo": (target_justdo_id, source_justdo_id) ->
    check source_justdo_id, String
    check target_justdo_id, String

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

    target_justdo = APP.collections.Projects.findOne target_justdo_id,
      members:
        $elemMatch:
          user_id: @userId
          is_admin: true
      fields:
        _id: 1
        lastTaskSeqId: 1
    
    # Check if user is admin of all justdos
    if not target_justdo? or not source_justdo?
      throw new Meteor.Error "justdos-not-found"
    
    bulk_write_ops = []

    src_justdo = source_justdo
    container_task_id = APP.projects._grid_data_com.addChild(
      "/"
    ,
      project_id: target_justdo_id
      title: "Merged from #{src_justdo.title}"
    ,
      @userId
    )

    tasks_count = APP.collections.Tasks.find
      project_id: src_justdo._id
    ,
      fields:
        _id: 1
    .count()

    # if tasks_count == 0
    #   # Source justdo is an empty justdo
    #   bulk_write_ops.push
    #     updateOne:
    #       filter:
    #         _id: container_task_id
    #       update:
    #         $set:
    #           title: "Merged from #{src_justdo.title} (Empty)"

    #   continue

    result = APP.collections.Projects.findAndModify
      query:
        _id: target_justdo_id
      fields:
        lastTaskSeqId: 1
      update:
        $inc: 
          lastTaskSeqId: tasks_count
      new: true

    lastTaskSeqId = result.value.lastTaskSeqId - tasks_count + 1
    seqIds_map = {}
    tasks_with_dependencies = []
    root_order = 0

    tasks = APP.collections.Tasks.find
      project_id: src_justdo._id
    ,
      fields:
        _id: 1
        seqId: 1
        parents: 1
        justdo_task_dependencies: 1
      sort:
        seqId: 1
    .forEach (task) ->
      seqIds_map[task.seqId] = lastTaskSeqId
      if task.justdo_task_dependencies?
        if task.parents?[0]?
          task.root_order = root_order
          root_order += 1
        # The bulk_write_op will be added after all seqId are mapped to a new one
        tasks_with_dependencies.push task
        return
      
      bulk_write_op =     # Using bulkWrite here because every task will have a different new seqId and justdo_task_dependencies
        updateOne:
          filter:
            _id: task._id
          update:
            $set:
              seqId: seqIds_map[task.seqId]
              project_id: target_justdo_id

      if task.parents?[0]?
        bulk_write_op.updateOne.update.$set["parents.#{container_task_id}"] = 
          order: root_order
        bulk_write_op.updateOne.update.$unset = 
          "parents.0": ""
        root_order += 1

      bulk_write_ops.push bulk_write_op

      lastTaskSeqId += 1

    _.each tasks_with_dependencies, (task) ->
      bulk_write_op =     
        updateOne:
          filter:
            _id: task._id
          update:
            $set:
              seqId: seqIds_map[task.seqId]
              project_id: target_justdo_id
              justdo_task_dependencies: _.map task.justdo_task_dependencies, (dep_seq_id) ->
                return seqIds_map[dep_seq_id]

      if task.root_order?
        bulk_write_op.updateOne.update.$set["parents.#{container_task_id}"] = 
          order: task.root_order
        bulk_write_op.updateOne.update.$unset = 
          "parents.0": ""

      bulk_write_ops.push bulk_write_op

    if bulk_write_ops.length > 0
      APP.collections.Tasks.rawCollection().bulkWrite bulk_write_ops,
        ordered: true

      updateJustdoIdInCollections = (collections) ->
        for collection in collections
          if collection?
            collection.rawCollection().update
              project_id: source_justdo_id
            ,
              $set:
                project_id: target_justdo_id
      
      updateRawUpdatedDateInCollections = (collections) ->
        for collection in collections
          if collection?
            collection.rawCollection().update
              project_id: source_justdo_id
            ,
              $currentDate:
                _raw_updated_date: true

      updateJustdoIdInCollections [
        APP.collections.RpTasksResources,
        APP.collections.TasksPrivateData,
        APP.collections.JDChatChannels,
        APP.collections.Formulas,
        APP.meetings_manager_plugin?.meetings_manager?.meetings,
        APP.collections.JDRProjectsRolesAndGrps
      ] 

      updateRawUpdatedDateInCollections [
        APP.collections.Tasks,
        APP.collections.TasksPrivateData
      ]

      # We are not handling users.justdo_time_tracker_report_configs 
      # because it might conflict with the configs set in the target justdo, also
      # the config data simply doesn't worth to be handled with the performance overhead

      # Don't do yet:
      # concat project.custom_fields
      # concat project.conf.custom_features
      # projects.members
      # video_call_rooms

    return container_task_id
