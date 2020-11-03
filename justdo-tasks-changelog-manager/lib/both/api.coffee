_.extend TasksChangelogManager.prototype,
  getActivityMessage: (activity_obj) ->
    performer_name = if activity_obj.by == Meteor.userId() then "You" else "#{JustdoHelpers.displayName(APP.helpers.getUsersDocsByIds activity_obj.by)}"

    if activity_obj.change_type == "created"
      ret_val = "#{performer_name}"

      ret_val += " created the task"
      users = activity_obj.users_added
      creator_index = activity_obj.users_added.indexOf(activity_obj.by)
      if creator_index > -1
        users.splice(creator_index, 1)
      if users.length == 0
        return ret_val + "."

      #list the first 3 users
      if users.length >=1
        ret_val += " and shared it with"

      for i in [1..users.length]
        if i > 1
          if users.length >=i
            if users.length == i
              ret_val += " and"
            else
              ret_val += ","
        if users[i-1] == Meteor.userId()
          ret_val += " you"
        else
          ret_val += " #{JustdoHelpers.displayName(APP.helpers.getUsersDocsByIds users[i-1])}"

        if i == 3 and users.length > 3
          ret_val += " and #{users.length-3} other user" #todo: add a tooltip or some other method to display all other users
          if users.length >4
            ret_val += "s"
          break

      return ret_val + "."

    if activity_obj.change_type == "moved_to_task"
      if activity_obj.new_value == "0"
        return "#{performer_name} made the task a top level task."

      if (task = APP.collections.Tasks.findOne activity_obj.new_value)?
        ret_val = "#{performer_name} transferred the task to task ##{task.seqId}"
        if task.title?
          ret_val = "#{ret_val} #{task.title}"
        if ret_val.length > 53
          ret_val = ret_val.substring(0,50) + "..."
        if ret_val.slice(-1) != "."
          ret_val += "."
        return ret_val


      #else - task is unknown to the user
      return "Transferred."

    if activity_obj.change_type == "users_change"
      ret_val = "#{performer_name}"

      if activity_obj.users_added?
        ret_val += " added "
        if activity_obj.users_added.length > 1
          ret_val += "the following users:"
        for i in [1..activity_obj.users_added.length]
          if i > 1 and activity_obj.users_added.length >= i
            if activity_obj.users_added.length == i
              ret_val += " and"
            else
              ret_val +=","
          if activity_obj.users_added[i-1] == Meteor.userId()
            ret_val += " you"
          else
            ret_val += " #{JustdoHelpers.displayName(APP.helpers.getUsersDocsByIds activity_obj.users_added[i-1])}"

      if activity_obj.users_added? and activity_obj.users_removed?
        ret_val += "; and"

      if activity_obj.users_removed?
        ret_val += " removed "
        if activity_obj.users_removed.length > 1
          ret_val += "the following users:"
        for i in [1..activity_obj.users_removed.length]
          if i > 1 and activity_obj.users_removed.length >= i
            if activity_obj.users_removed.length == i
              ret_val += " and"
            else
              ret_val +=","
          if activity_obj.users_removed[i-1] == Meteor.userId()
            ret_val += " you"
          else
            ret_val += " #{JustdoHelpers.displayName(APP.helpers.getUsersDocsByIds activity_obj.users_removed[i-1])}"

      return ret_val + "."

    if activity_obj.change_type == "unset"
      return "#{performer_name} cleared the task's #{JustdoHelpers.ucFirst(activity_obj.label)}."

    if activity_obj.change_type == "priority_increased"
      ret_val = "#{performer_name}"

      ret_val += " increased the task's priority (to #{activity_obj.new_value})."
      return ret_val

    if activity_obj.change_type == "priority_decreased"
      ret_val = "#{performer_name}"

      ret_val += " decreased the task's priority (to #{activity_obj.new_value})."
      return ret_val

    if activity_obj.change_type == "custom"
      return "#{performer_name} #{activity_obj.new_value}"

    if activity_obj.field == "owner_id"
      if (user = JustdoHelpers.getUsersDocsByIds activity_obj.new_value)?
        return "#{JustdoHelpers.displayName(user)} took ownership."
      return "Task owner changed."

    if activity_obj.field == "due_date" or activity_obj.field == "follow_up"
      return "#{performer_name} set #{JustdoHelpers.ucFirst(activity_obj.label)} to #{moment(new Date(activity_obj.new_value)).format('LL.')}"

    if not (schema = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields(true))?
      return "Loading..."

    getLabelFromFieldDefinition = (field_definition) ->
      label = JustdoHelpers.ucFirst(field_definition.label)

      if field_definition.obsolete? and field_definition.obsolete == true
        label += " (removed field)"

      return label

    field_definition = schema[activity_obj.field]
    if field_definition.grid_column_formatter == "keyValueFormatter"
      if not (new_value_txt_label = field_definition.grid_values?[activity_obj.new_value]?.txt)?
        if not (new_value_txt_label = field_definition.grid_removed_values?[activity_obj.new_value]?.txt)?
          new_value_txt_label = "Unknown"

      return "#{performer_name} set #{getLabelFromFieldDefinition(field_definition)} to: #{new_value_txt_label}."

    # and the generic case:
    if activity_obj.new_value.length == 0
      return "#{performer_name} cleared #{getLabelFromFieldDefinition(field_definition)}."

    new_value = activity_obj.new_value
    
    return "#{performer_name} set #{getLabelFromFieldDefinition(field_definition)} to: #{new_value}."
