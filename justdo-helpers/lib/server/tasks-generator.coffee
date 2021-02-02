range_allowed_value_types = ["date-string", "float", "integer"]

options_schema = new SimpleSchema
  project_id:
    type: String
  max_levels:
    type: Number
    defaultValue: 10
  max_items_to_add:
    # If we add max_items_to_add tasks, we will stop adding more tasks immediately
    type: Number
    defaultValue: 1000
  min_items_per_parent:
    type: Number
    defaultValue: 1
  max_items_per_parent:
    type: Number
    defaultValue: 10
  parents:
    type: [String]
    defaultValue: ["0"]
  max_words_in_title:
    type: Number
    defaultValue: 20 # 0 means no title will be set by us
  max_words_in_status:
    type: Number
    defaultValue: 20 # 0 means no title will be set by us
  custom_fields:
    type: Object
    blackbox: true
    defaultValue: {}

lorem_arr = JustdoHelpers.lorem_ipsum_arr

pad0 = (num) ->
  return "#{num}".padStart(2, 0)

throwInvalidCustomFieldErr = (field_name, msg) ->
  throw new Meteor.Error "invalid-custom-fields", "For #{field_name}, #{msg}"

Meteor.methods
  "JDHelpersTasksGenerator": (options) ->
    user_id = @userId

    check user_id, String
    check options, Object

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        options_schema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    # Validate and pre-process custom_fields
    if options.custom_fields?
      for field_name, field_def of options.custom_fields
        if not _.isArray(field_def) and _.isObject(field_def)
          if not field_def.type?
            throwInvalidCustomFieldErr field_name, "type option not specified"
          if field_def.type == "random-value"
            if not _.isArray(field_def.allowed_values) or field_def.allowed_values.length == 0
              throwInvalidCustomFieldErr field_name, "allowed_values option not specifid"
          else if field_def.type == "range"
            if not (field_def.value_type in range_allowed_value_types)
              throwInvalidCustomFieldErr field_name, "value_type option must be in #{range_allowed_value_types}"
            if not _.isArray(field_def.range) or field_def.range.length != 2
              throwInvalidCustomFieldErr field_name, "range option must be an array with length of 2"

            min = field_def.range[0]
            max = field_def.range[1]
            # XXX error if max < min
            if field_def.value_type == "date-string"
              if not min or min < 0
                min = 0
              min = moment.utc(min).startOf("day").toDate().getTime()
              max = moment.utc(max).startOf("day").toDate().getTime()
            else if field_def.value_type == "float"
            else if field_def.value_type == "integer"
              min = Math.ceil min
              max = Math.floor max
            
            if max < min
              throwInvalidCustomFieldErr field_name, "range option is invalid"

            field_def.range[0] = min
            field_def.range[1] = max

    if not JustdoHelpers.isPocPermittedDomains()
      return

    if not (project = APP.collections.Projects.findOne(options.project_id))?
      throw new Error "project-not-found"

    items_added = 0
    all_tasks = []
    parent_next_order = {}

    fetch_parents_last_order_promises = []

    for parent in options.parents
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

    now = new Date() # A single now for all the created tasks
    generateTaskDocForParent = (parent) ->
      # Note seqId will be added later

      fallback_fields = # Will be set only if weren't been set already by custom_fields
        owner_id: user_id
        priority: 0
        state: "nil"

      forced_fields =
        _id: Random.id()
        
        users: _.union [user_id], options.custom_fields?.users
        users_updated_at: now
        _raw_added_users_dates:
          "#{user_id}": now
        
        _raw_updated_date: now

        createdAt: now

        created_by_user_id: user_id

        parents:
          "#{parent}":
            order: getParentLastOrder parent

        project_id: options.project_id

        updatedAt: now

      custom_fields = {}
      for field_name, field_def of options.custom_fields
        if not _.isObject field_def
          custom_fields[field_name] = field_def
        else
          if field_def.chance_empty? and Random.fraction() < field_def.chance_empty
            continue

          if field_def.type == "random-value"
            custom_fields[field_name] = Random.choice field_def.allowed_values
          else if field_def.type == "range"
            min = field_def.range[0]
            max = field_def.range[1]
            if field_def.value_type == "date-string"
              rand_date = moment.utc(Math.floor(Random.fraction() * (max - min) + min))
              custom_fields[field_name] = "#{pad0(rand_date.year())}-#{pad0(rand_date.month()+1)}-#{pad0(rand_date.date())}"
            else if field_def.value_type == "float"
              custom_fields[field_name] = Random.fraction() * (max - min) + min
            else if field_def.value_type == "integer"
              custom_fields[field_name] = Math.floor(Random.fraction() * (max - min) + min)

      fields = _.extend fallback_fields, custom_fields, forced_fields

      # Add neccessary fields
      for field_name in ["title", "status"]
        # Set only if aren't set already
        if not fields[field_name]? and options["max_words_in_#{field_name}"] != 0
          fields[field_name] = lodash.sampleSize(lorem_arr, lodash.random(1, options["max_words_in_#{field_name}"])).join(" ")
      
      return fields

    getParentLastOrder = (parent) ->
      if not parent_next_order[parent]?
        parent_next_order[parent] = 0
      
      return_val = parent_next_order[parent]
      parent_next_order[parent] += 1
      return return_val

    addChildrenToParents = (parents, level) ->
      if level == 0
        return

      added_children_ids = []
      
      for parent in parents
        children_count = lodash.random(options.min_items_per_parent, options.max_items_per_parent)
        i = 0
        while i < children_count
          child_fields = generateTaskDocForParent parent

          added_children_ids.push child_fields._id
          all_tasks.push child_fields
          if (items_added += 1) == options.max_items_to_add
            return
          
          i += 1

      addChildrenToParents added_children_ids, level - 1

      return
    
    await Promise.all(fetch_parents_last_order_promises)
    
    addChildrenToParents options.parents, options.max_levels
    
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