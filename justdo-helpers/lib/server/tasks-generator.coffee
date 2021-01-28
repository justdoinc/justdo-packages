options_schema = new SimpleSchema
  project_id:
    type: String
  max_levels:
    type: Number
  max_items_to_add:
    type: Number
  min_items_per_parent:
    type: Number
  max_items_per_parent:
    type: Number
  parents:
    type: [String]
  max_words_in_title:
    type: Number
  max_words_in_status:
    type: Number
  fields:
    type: Object

lorem_arr = JustdoHelpers.lorem_ipsum_arr

Meteor.methods
  "JDHelpersTasksGenerator": (options) ->
    user_id = @userId

    check user_id, String
    check options, Object
    options_schema.validate options

    if not JustdoHelpers.isPocPermittedDomains()
      return

    if not (project = APP.collections.Projects.findOne(options.project_id))?
      throw new Error "project-not-found"

    {max_levels, min_items_per_parent, max_items_per_parent, parents, fields} = options
    
    items_added = 0
    all_tasks = []
    parent_next_order = {}

    fetch_parents_last_order_promises = []

    for parent in parents
      do (parent) ->
        fetch_parents_last_order_promises.push(APP.collections.Tasks.rawCollection().aggregate([{
          $match:
            project_id: options.project_id
            "parents.#{parent}":
              $exists: true
        }, {
          $group:
            _id: "$project_id"
            max_order:
              $max: "$parents.#{parent}.order"
        }]).forEach (doc) ->
          parent_next_order[parent] = doc.max_order + 1

          return
        )

        return

    addNecessaryFields = (child_fields, parent) ->
      now = new Date()
      child_fields._id = Random.id()
      child_fields._raw_added_users_dates =
        "#{user_id}": now
      child_fields._raw_updated_date = now
      child_fields.createdAt = now
      child_fields.created_by_user_id = user_id
      child_fields.owner_id = user_id
      child_fields.parents =
        "#{parent}":
          order: getParentLastOrder parent
      priority = 0
      child_fields.project_id = options.project_id
      # seqId will be added later
      child_fields.state = "nil"
      child_fields.updatedAt = now
      child_fields.users = [user_id]
      child_fields.users_updated_at = now

      return

    getParentLastOrder = (parent) ->
      if not parent_next_order[parent]?
        parent_next_order[parent] = 0
      
      return_val = parent_next_order[parent]
      parent_next_order += 1
      return return_val

    addChildrenToParents = (parents, level) ->
      if level == 0
        return

      added_children_ids = []
      
      for parent in parents
        children_count = lodash.random(min_items_per_parent, max_items_per_parent)
        i = 0
        while i < children_count
          child_fields = _.extend {}, fields # Create a copy
          addNecessaryFields child_fields, parent
          # add neccessary fields
          for field_name in ["title", "status"]
            if not child_fields[field_name]? and options["max_words_in_#{field_name}"] != 0
              child_fields[field_name] = lodash.sampleSize(lorem_arr, lodash.random(1, options["max_words_in_#{field_name}"])).join(" ")
          
          added_children_ids.push child_fields._id
          all_tasks.push child_fields
          if (items_added += 1) == options.max_items_to_add
            return
          
          i += 1

      addChildrenToParents added_children_ids, level - 1

      return
    
    await Promise.all(fetch_parents_last_order_promises)
    
    addChildrenToParents parents, max_levels
    
    # allocate seqId
    result = APP.collections.Projects.findAndModify
      query:
        _id: options.project_id
      fields:
        lastTaskSeqId: 1
      update:
        $inc:
          lastTaskSeqId: items_added

    current_seq_id = result?.value?.lastTaskSeqId + 1
    for task in all_tasks
      task.seqId = current_seq_id
      current_seq_id += 1

    APP.collections.Tasks.rawCollection().insertMany all_tasks

    return items_added