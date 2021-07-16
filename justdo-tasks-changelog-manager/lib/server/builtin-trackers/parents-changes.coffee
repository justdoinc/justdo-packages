_.extend PACK.builtin_trackers,
  parentsChangesTracker: ->
    self = @

    self.justdo_projects_obj._grid_data_com.setGridMethodMiddleware "movePath", (path, perform_as, etc) ->
      new_parent_id = ""
      if etc.new_parent_item?
        new_parent_id = etc.new_parent_item._id
        if etc.item.parents[new_parent_id] # this is a case in which we just change the order of tasks..
          return true
      else if etc.new_location.parent == "0"  # if moving to the root
        if etc.current_parent_id == "0" #if previous paretn was also root, then do nothing...
          return true
        new_parent_id = 0
      else
        return true # (as requested) - don"t break the code, although we should never get here.

      log_obj =
        field: "parents"
        label: "Parents"
        new_value: new_parent_id
        change_type: "moved_to_task"
        task_id: etc.item._id
        project_id: etc.item.project_id
        by: perform_as

      self.logChange(log_obj)

      return true
    
    self.justdo_projects_obj._grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) ->
      new_parent_id = ""
      if etc.new_parent_item?
        new_parent_id = etc.new_parent_item._id
      else if etc.new_location.parent == "0"  # if moving to the root
        new_parent_id = 0
      else
        return true # (as requested) - don"t break the code, although we should never get here.

      log_obj =
        field: "parents"
        label: "Parents"
        new_value: new_parent_id
        change_type: "add_parent"
        task_id: etc.item._id
        project_id: etc.item.project_id
        by: perform_as

      self.logChange(log_obj)

      return true
    
    self.justdo_projects_obj._grid_data_com.setGridMethodMiddleware "removeParent", (path, perform_as, etc) ->
      removed_parent = etc.parent_id or ""
      if removed_parent == "0"  # if moving to the root
        new_parent_id = 0

      log_obj =
        field: "parents"
        label: "Parents"
        new_value: removed_parent
        change_type: "remove_parent"
        task_id: etc.item._id
        project_id: etc.item.project_id
        by: perform_as

      self.logChange(log_obj)

      return true
