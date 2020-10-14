_.extend PACK.builtin_trackers,
  parentsChangesTracker: ->
    self = @

    self.justdo_projects_obj._grid_data_com.setGridMethodMiddleware "movePath", (path, perform_as, etc) ->
      newParentId = ''
      if etc.new_parent_item?
        newParentId = etc.new_parent_item._id
        if etc.item.parents[newParentId] # this is a case in which we just change the order of tasks..
          return true
      else if etc.new_location.parent == '0'  # if moving to the root
        if etc.current_parent_id == '0' #if previous paretn was also root, then do nothing...
          return true
        newParentId = 0
      else
        return true # (as requested) - don't break the code, although we should never get here.

      obj =
        field: 'parents'
        label: 'Parents'
        new_value: newParentId
        change_type: 'moved_to_task'
        task_id: etc.item._id
        project_id: etc.item.project_id
        by: perform_as

      self.logChange(obj)

      return true
