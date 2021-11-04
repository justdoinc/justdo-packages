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

    parentChangeMsg = (activity_obj, op) ->
      old_parent = APP.collections.Tasks.findOne(activity_obj.old_value, {fields: {seqId: 1}})

      if activity_obj.new_value is "0"
        op_name = ""
        if op == "add"
          op_name = "added"
        else if op == "remove"
          op_name = "removed"
        else if op == "move"
          op_name = "made"
        ret_val = "#{performer_name} #{op_name} the task as a top level task"
        if old_parent?
          ret_val += " (Was under ##{old_parent.seqId})"
        return ret_val + "."

      if (task = APP.collections.Tasks.findOne(activity_obj.new_value, {fields: {seqId: 1, title: 1}}))?
        op_name = ""
        if op == "add"
          op_name = "added"
        else if op == "remove"
          op_name = "removed"
        else if op == "move"
          op_name = "transferred"
          # If operation type is transfer and the original parent is accessible, return the "from-to" message
          # No task title is added for both tasks since the message template is already roughly 50 chars long,
          # which is approaching the current ellipsis limit 53 chars.
          if old_parent?
            ret_val = "#{performer_name} transferred from ##{old_parent.seqId} to ##{task.seqId}."
            return ret_val

        # Otherwise we only show seqId of the new parent, and add its title
        ret_val = "#{performer_name} #{op_name} #{if op is "remove" then "from" else "to"} ##{task.seqId}"
        if task.title?
          ret_val = "#{ret_val} #{task.title}"
        if ret_val.slice(-1) != "."
          ret_val += "."
        return ret_val

      # else - task is unknown to the user
      op_name = ""
      if op == "add"
        op_name = "Added"
      else if op == "remove"
        op_name = "Removed"
      else if op == "move"
        op_name = "Transfer"
      return "#{op_name} a parent (not shared with you)"

    if activity_obj.change_type == "moved_to_task"
      return parentChangeMsg(activity_obj, "move")

    if activity_obj.change_type == "add_parent"
      return parentChangeMsg(activity_obj, "add")
    
    if activity_obj.change_type == "remove_parent"
      return parentChangeMsg(activity_obj, "remove")

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

    if activity_obj.change_type == "transfer_rejected"
      return "#{performer_name} rejected the ownership transfer request."

    if activity_obj.field == "owner_id"
      if (user = JustdoHelpers.getUsersDocsByIds activity_obj.new_value)?
        return "#{JustdoHelpers.displayName(user)} became owner."
      return "Task owner changed."

    if not (schema = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields(true))?
      return "Loading..."

    field_definition = schema[activity_obj.field]

    # Get display label of field name
    getLabelFromFieldDefinition = ->
      label = JustdoHelpers.ucFirst(field_definition.label)

      if field_definition.obsolete? and field_definition.obsolete == true
        label += " (removed field)"

      return label

    if field_definition.grid_column_formatter is "unicodeDateFormatter"
      return "#{performer_name} set #{JustdoHelpers.ucFirst(activity_obj.label)} to #{moment(new Date(activity_obj.new_value)).format('LL.')}"

    if field_definition.grid_column_formatter is "keyValueFormatter"
      if not (new_value_txt_label = field_definition.grid_values?[activity_obj.new_value]?.txt)?
        if not (new_value_txt_label = field_definition.grid_removed_values?[activity_obj.new_value]?.txt)?
          new_value_txt_label = "Unknown"
      return "#{performer_name} set #{getLabelFromFieldDefinition(field_definition)} to: #{new_value_txt_label}."

    # and the generic case:
    if activity_obj.new_value.length == 0
      return "#{performer_name} cleared #{getLabelFromFieldDefinition(field_definition)}."

    new_value = activity_obj.new_value

    return "#{performer_name} set #{getLabelFromFieldDefinition(field_definition)} to: #{new_value}."

  getHumanReadableOldValue: (activity_obj) ->
    old_value = activity_obj.old_value

    if not old_value? or (old_value is null)
      return "empty"

    if activity_obj.field == "owner_id"
      return JustdoHelpers.displayName old_value

    if not (schema = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields(true))?
      return "..." # Loading

    field_definition = schema[activity_obj.field]

    if field_definition.grid_column_formatter is "unicodeDateFormatter"
      return moment(new Date(old_value)).format('LL.')

    if field_definition.grid_column_formatter is "keyValueFormatter"
      if not (old_value_txt_label = field_definition.grid_values?[old_value]?.txt)?
        if not (old_value_txt_label = field_definition.grid_removed_values?[old_value]?.txt)?
          old_value_txt_label = "Unknown"
      return old_value_txt_label

    return old_value
