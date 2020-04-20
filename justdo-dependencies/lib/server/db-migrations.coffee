_.extend JustdoDependencies.prototype,
  _setupDbMigrations: ->
    JD.collections.Tasks.find({"#{JustdoDependencies.dependencies_field_id}": {$exists: true}, "#{JustdoDependencies.dependencies_mf_field_id}": {$exists: false}}).forEach (task_obj) ->
      machine_friendly = []
      for seq_id in task_obj[JustdoDependencies.dependencies_field_id]
        if(dep_obj = JD.collections.Tasks.findOne({project_id: task_obj.project_id, seqId: seq_id}))?
          machine_friendly.push
            task_id: dep_obj._id
            type: "F2S"
      JD.collections.Tasks.update({_id: task_obj._id}, {$set: {"#{JustdoDependencies.dependencies_mf_field_id}": machine_friendly}})
    return