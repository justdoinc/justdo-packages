day =  24 * 3600 * 1000

_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    @_states_manager = {}
    
    @fields_to_trigger_task_change_process = ["start_date", "end_date", "due_date", "parents"]
    
    @task_id_to_info = {} # Map to relevant information including
                          #   self_start_time: # indicates the beginning of the gantt block for the task
                          #   self_end_time: # indicates the ending of the gantt block for the task
                          #   milestone_time:
                          #   earliest_child_start_time: # the earliest child task start time
                          #   latest_child_end_time: # the latest child task end time
                          #   alerts: [<structure TBD>,]
                          #   parents: an Array of the parents ids. Those need to be iterated and updated
                          #            when parents change, or when the task is removed (which at that time
                          #            we no longer have it's parents
                          # (*)all times in epoch
    @missing_parents = new Set() # see comment in processTaskAdd
    @gantt_dirty_tasks = new Set()
    @_epoch_range = {} # a map of grid_id to from and to epoch time to the specific grid
    @_columns_width = {} # map if grid_id to reactive vars of gantt column width
    
    @task_ids_edited_locally = new Set()  # this Set is used to store task ids that were edited locally
                                          # using the gantt column (mostly mouse control). This set is used
                                          # to determine if a change in a task is a result of a local change,
                                          # and if so, to update dependent tasks, or if it is a result of other
                                          # update, in which case we don't update the dependents.
    
    @_lock_dates_edit = 0
    @lockDatesEdit = ->
      @_lock_dates_edit += 1
      return
  
    @unlockDatesEdit = ->
      @_lock_dates_edit -= 1
      if @_lock_dates_edit < 0
        @_lock_dates_edit = 0
      return
      
    @canEditDates = ->
      return @_lock_dates_edit == 0
      
    
    @resetTaskIdToInfo = ->
      self.task_id_to_info = {}
      return
      
    @initTaskIdToInfo = ->
      self.resetTaskIdToInfo()
      if not (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
        return
      for task_id, task_obj of core_data.items_by_id
        self.processTaskAdd task_obj
        
      self.processGanttDirtyTasks()
      return # end of initTaskIdToInfo
    
    @processChangesQueue = (queue) =>
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      for [msg_type, [task_id, data]] in queue.queue
        if msg_type == "update"
          for field in data
            if field in self.fields_to_trigger_task_change_process
              self.processTaskChange core_data.items_by_id[task_id]
        else if msg_type == "add"
          self.processTaskAdd data
        else if msg_type == "remove"
          self.processTaskRemove task_id
        else if msg_type == "parent_update"
          self.processTaskParentUpdate task_id
        else
          console.error "justdo-grid-gantt unhandled msg type", msg_type
  
      self.processGanttDirtyTasks()
      return # end of process changes queue
  
    @processGanttDirtyTasks = () ->
      gc = APP.modules.project_page.gridControl()
      column_index = gc.getFieldIdToColumnIndexMap()[JustdoGridGantt.pseudo_field_id]
      tree_indices = gc._grid_data._items_ids_map_to_grid_tree_indices
      
      if column_index?
        self.gantt_dirty_tasks.forEach (task_id) ->
          if task_id != "0" # this the mother of all root tasks. Daniel - I need guidance if change is needed
            if (rows = tree_indices[task_id])?
              for row in rows
                APP.modules.project_page.gridControl()._grid.updateCell(row, column_index, true) # true is to avoid the same-tick updateCell block
          return # end of for each
      
      self.gantt_dirty_tasks.clear()

      self.refreshArrows({defer: true}) # Defer to let the grid refresh

      return # end of process gantt dirty tasks
  
    @processTaskAdd = (task_obj) ->
      task_id = task_obj._id
      task_info = self.getOrCreateTaskInfoObject task_id
      task_info.parents = Object.keys task_obj.parents
      
      # Note: a child could be added before its parent (happens in cases of multiple parents)
      # In order to manage such cases we use a Set of missing_parents. Once such a missing parent
      # is added, appear, the first thing that it has to do it to recalculate its first and last children
      for parent in task_info.parents
        if not self.task_id_to_info[parent]
          self.missing_parents.add parent
        
      self.processTaskChange task_obj
      
      # the part where a missing parent is added
      if self.missing_parents.has task_id
        old_task_info = _.extend {}, task_info
        
        if self.recalculateEarliestChildTime task_id
          self.processStartTimeChange task_id, task_info, old_task_info
        if self.recalculateLatestChildTime task_id
          self.processEndTimeChange task_id, task_info, old_task_info
        self.missing_parents.delete task_id
        
      self.warnings_manager.checkTask task_obj
      return
      
    @processTaskChange = (task_obj) ->
      if not(task_info = self.task_id_to_info[task_obj._id])?
        console.error "grid-gantt - unidentified task changed"
        
      old_task_info = _.extend {}, task_info
      
      # start time
      if task_obj.start_date?
        task_info.self_start_time = self.dateStringToStartOfDayEpoch task_obj.start_date
      else
        delete task_info.self_start_time
        
      # end time
      if task_obj.end_date?
        if task_obj.end_date == task_obj.due_date
          task_info.self_end_time = self.dateStringToMidDayEpoch task_obj.end_date
        else
          task_info.self_end_time = self.dateStringToEndOfDayEpoch task_obj.end_date
          
      else if task_obj.due_date? and task_obj.start_date
        task_info.self_end_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.self_end_time
        
      # milestone
      if task_obj.due_date?
        task_info.milestone_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.milestone_time
        
      # checking start_time change
      if task_info.self_start_time != old_task_info.self_start_time
        self.processStartTimeChange task_obj._id, task_info, old_task_info
  
      # checking end_time change
      if task_info.self_end_time != old_task_info.self_end_time
        self.processEndTimeChange task_obj._id, task_info, old_task_info
      
      #checking milestone
      if task_info.milestone_time != old_task_info.milestone_time
        self.processMilestoneTimeChange task_obj._id, task_info, old_task_info
  
      self.warnings_manager.checkTask task_obj
      return # end of processTaskChange
    
    @processTaskRemove = (task_id) ->
      if not (old_task_info = self.task_id_to_info[task_id])?
        return
      
      if old_task_info.self_start_time?
        self.processStartTimeChange task_id, {}, old_task_info
      if old_task_info.self_end_time?
        self.processEndTimeChange task_id, {}, old_task_info
      if old_task_info.milestone_time?
        self.processMilestoneTimeChange() task_id, {}, old_task_info
        
      delete self.task_id_to_info[task_id]
      self.warnings_manager.removeTask task_id
      return
  
    @processTaskParentUpdate = (task_id) ->
      if not (old_task_info = self.task_id_to_info[task_id])?
        console.error "grid-gantt - task not found (parents-update)"
        old_task_info =
          parents: []
      # when parents change, we need to 'touch' all the parents that were removed and all those added:
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      current_parents = (Object.keys core_data.items_by_id[task_id].parents) or []
      old_parents = old_task_info.parents
      parents_added = new Set(current_parents)
      for parent in old_parents
        parents_added.delete parent
      
      parents_removed = new Set(old_parents)
      for parent in current_parents
        parents_removed.delete parent
        
      all_changed_parents = []
      parents_added.forEach (parent_id) ->
        all_changed_parents.push parent_id
      parents_removed.forEach (parent_id) ->
        all_changed_parents.push parent_id
        
      # end update the cached data
      self.task_id_to_info[task_id].parents = current_parents
  
      # update parents
      for parent_id in all_changed_parents
        parent_task_info = self.task_id_to_info[parent_id]
        old_parent_task_info = _.extend {}, parent_task_info
      
        if self.recalculateEarliestChildTime parent_id
          self.processStartTimeChange parent_id, parent_task_info, old_parent_task_info
          
        if self.recalculateLatestChildTime parent_id
          self.processEndTimeChange parent_id, parent_task_info, old_parent_task_info
          
      return
  
    @processStartTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      # for the value of the earliest child, we take the minimum of the start_time and the earliest_child_start_time
      start_time = self.earliestOfSelfStartAndEarliestChildStart task_info
      old_start_time = self.earliestOfSelfStartAndEarliestChildStart old_task_info
      
      # loop on all parents to update the earliest child task
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      all_parents = new Set(task_info.parents)
      if old_task_info.parents?
        for parent in old_task_info.parents
          all_parents.add parent
      
      all_parents.forEach (parent_id) ->
        # if the parent_id is in the missing parents, we won't deal with it now, since we don't know its own
        # parents, and won't be able to change those as well. We will process it when it's added.
        if self.missing_parents.has parent_id
          return # keep going on the forEach
          
        parent_changed = false
        parent_task_info = self.getOrCreateTaskInfoObject parent_id
        old_parent_task_info = _.extend {}, parent_task_info
        
        # we have 4 cases to cover: new start_time, start_time removed, start_time increased, start_time decreased

        # 1. new start_time
        if start_time? and not old_start_time?
          if not parent_task_info.earliest_child_start_time?
            parent_task_info.earliest_child_start_time = start_time
            parent_changed = true
          else # parent early child exists
            if start_time < parent_task_info.earliest_child_start_time
              parent_task_info.earliest_child_start_time = start_time
              parent_changed = true
            # else - do noting because start time is new but bigger than existing parent earliest child start
        
        # 2. start_time removed
        else if not start_time? and old_start_time?
          if parent_task_info.earliest_child_start_time? and old_start_time <= parent_task_info.earliest_child_start_time
            parent_changed = self.recalculateEarliestChildTime parent_id
          # else do nothing because either the parent early does not exist or that the old_start time was bigger than the parent earliest child
          
        else if start_time? and old_start_time?
          # 3. start_time decreased
          if start_time < old_start_time
            if not parent_task_info.earliest_child_start_time? or start_time < parent_task_info.earliest_child_start_time
              parent_task_info.earliest_child_start_time = start_time
              parent_changed = true
            
          # 4. start_time increased
          else if start_time > old_start_time
            if not parent_task_info.earliest_child_start_time?
              parent_task_info.earliest_child_start_time = start_time
              parent_changed = true
            else if old_start_time <= parent_task_info.earliest_child_start_time
              parent_changed = self.recalculateEarliestChildTime parent_id
            # else do nothing because the old_start_time was not the parent's earliest child start time
            
        else if not start_time and not old_start_time # we should never get here, so alert if we do:
          console.error "grid-gantt: unresolved start change"
        
        if parent_changed
          self.processStartTimeChange parent_id, parent_task_info, old_parent_task_info
          
      return
  
    @processEndTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      # for the value of the last child, we take the latest of the end_time and the latest_child_end_time
      end_time = self.latestOfSelfEndAndLatestChildEnd task_info
      old_end_time = self.latestOfSelfEndAndLatestChildEnd old_task_info
  
      # loop on all parents to update the latest child task
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      all_parents = new Set(task_info.parents)
      if old_task_info.parents?
        for parent in old_task_info.parents
          all_parents.add parent
  
      all_parents.forEach (parent_id) ->
        # if the parent_id is in the missing parents, we won't deal with it now, since we don't know its own
        # parents, and won't be able to change those as well. We will process it when it's added.
        if self.missing_parents.has parent_id
          return # keep going on the forEach
        
        parent_changed = false
        parent_task_info = self.getOrCreateTaskInfoObject parent_id
        old_parent_task_info = _.extend {}, parent_task_info
    
        # we have 4 cases to cover: new end_time, end_time removed, end_time decreased, end_time increased
    
        # 1. new end_time
        if end_time? and not old_end_time?
          if not parent_task_info.latest_child_end_time?
            parent_task_info.latest_child_end_time = end_time
            parent_changed = true
          else # parent latest child exists
            if end_time > parent_task_info.latest_child_end_time
              parent_task_info.latest_child_end_time = end_time
              parent_changed = true
          # else - do noting because end time is new but smaller than existing parent latest child end
      
        # 2. end_time removed
        else if not end_time? and old_end_time?
          if parent_task_info.latest_child_end_time? and old_end_time >= parent_task_info.latest_child_end_time
            parent_changed = self.recalculateLatestChildTime parent_id
          # else do nothing because either the parent early does not exist or that the old_start time was bigger than the parent earliest child
    
        else if end_time? and old_end_time?
          # 3. end_time increased
          if end_time > old_end_time
            if not parent_task_info.latest_child_end_time? or end_time > parent_task_info.latest_child_end_time
              parent_task_info.latest_child_end_time = end_time
              parent_changed = true
        
            # 4. end_time decreased
          else if end_time < old_end_time
            if not parent_task_info.latest_child_end_time?
              parent_task_info.latest_child_end_time = end_time
              parent_changed = true
            else if old_end_time >= parent_task_info.latest_child_end_time
              parent_changed = self.recalculateLatestChildTime parent_id
            # else do nothing because the old_end_time was not the parent's latest child end time
    
        else if not end_time and not old_end_time # we should never get here, so alert if we do:
          console.error "grid-gantt: unresolved end change"
    
        if self.task_ids_edited_locally.has task_id
          if parent_changed
            self.task_ids_edited_locally.add parent_id
            self.updateDependentTasks parent_id
          self.task_ids_edited_locally.delete task_id
        if parent_changed
          self.processEndTimeChange parent_id, parent_task_info, old_parent_task_info
      return
      
    @_printDebugInfo = (task_id) ->
      task_info = self.getOrCreateTaskInfoObject task_id
      console.log "----------#{task_id}----------"
      if task_info.self_start_time
        console.log " self start ", moment(task_info.self_start_time).format()
      if task_info.self_end_time
        console.log " self end ", moment(task_info.self_start_time).format()
      if task_info.earliest_child_start_time
        console.log " earliest child start ", moment(task_info.earliest_child_start_time).format()
      if task_info.latest_child_end_time
        console.log " latest child end ", moment(task_info.latest_child_end_time).format()
      console.log "------------------------------"
      
    @recalculateEarliestChildTime = (task_id) ->
      # returns true if value changed, otherwise false
      task_info = self.getOrCreateTaskInfoObject task_id
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      
      if (children = core_data.tree_structure[task_id])?
        earliest_child_time = undefined
        for order, child_id of children
          child_task_info = self.getOrCreateTaskInfoObject child_id
          child_early_time = self.earliestOfSelfStartAndEarliestChildStart child_task_info
          if not earliest_child_time?
            earliest_child_time = child_early_time
          else if child_early_time? and child_early_time < earliest_child_time
            earliest_child_time = child_early_time
        if not task_info.earliest_child_start_time? or task_info.earliest_child_start_time != earliest_child_time
          task_info.earliest_child_start_time = earliest_child_time
          return true
          
      else # no children
        if task_info.earliest_child_start_time?
          delete task_info.earliest_child_start_time
          return true
        
      return false
  
    @recalculateLatestChildTime = (task_id) ->
      # returns true if value changed, otherwise false
      task_info = self.getOrCreateTaskInfoObject task_id
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
    
      if (children = core_data.tree_structure[task_id])?
        latest_child_time = undefined
        for order, child_id of children
          child_task_info = self.getOrCreateTaskInfoObject child_id
          child_latest_time = self.latestOfSelfEndAndLatestChildEnd child_task_info
          if not latest_child_time?
            latest_child_time = child_latest_time
          else if child_latest_time? and child_latest_time > latest_child_time
            latest_child_time = child_latest_time
        
        if not task_info.latest_child_end_time? or task_info.latest_child_end_time != latest_child_time
          task_info.latest_child_end_time = latest_child_time
          return true
    
      else # no children
        if task_info.latest_child_end_time?
          delete task_info.latest_child_end_time
          return true
    
      return false
  
    @getOrCreateTaskInfoObject = (task_id) ->
      if not (task_info = self.task_id_to_info[task_id])?
        task_info = {}
        self.task_id_to_info[task_id] = task_info
        self.gantt_dirty_tasks.add task_id
      return task_info
      
    @processMilestoneTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      return
      
    @dateStringToStartOfDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g

      if not re.test date
        return Date.UTC(0)

      split_date = date.split("-")

      return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

    @dateStringToEndOfDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g
      if not re.test date
        return Date.UTC(0)
      return day - 1 + self.dateStringToStartOfDayEpoch date

    @dateStringToMidDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g
      if not re.test date
        return Date.UTC(0)
      half_day = 1000 * 60 * 60 * 12
      return half_day + self.dateStringToStartOfDayEpoch date

    @timeOffsetPixels = (epoch_range, time, width_in_pixels) ->
      epoch_start = epoch_range[0]
      epoch_end = epoch_range[1]
      if epoch_end <= epoch_start
        return undefined
      return (time - epoch_start) / (epoch_end - epoch_start) * width_in_pixels
  
    @pixelsDeltaToEpochDelta = (delta_pixels) ->
      range = self.getEpochRange()
      return delta_pixels / self.grid_gantt_column_width * (range[1] - range[0])
    
    @earliestOfSelfStartAndEarliestChildStart = (task_info) ->
      if task_info.self_start_time?
        if task_info.earliest_child_start_time?
          if task_info.self_start_time < task_info.earliest_child_start_time
            return task_info.self_start_time
          else
            return task_info.earliest_child_start_time
        else
          return task_info.self_start_time
      else # no self_start_time
        if task_info.earliest_child_start_time?
          return task_info.earliest_child_start_time
      return undefined
  
    @latestOfSelfEndAndLatestChildEnd = (task_info) ->
      if task_info.self_end_time?
        if task_info.latest_child_end_time?
          if task_info.self_end_time > task_info.latest_child_end_time
            return task_info.self_end_time
          else
            return task_info.latest_child_end_time
        else
          return task_info.self_end_time
      else # no self_start_time
        if task_info.latest_child_end_time?
          return task_info.latest_child_end_time
      return undefined
      
    @setPresentationEndTime = (task_id, new_end_time) ->
      self.task_id_to_info[task_id].self_end_time = new_end_time
      self.gantt_dirty_tasks.add task_id
      self.processGanttDirtyTasks()
      return
  
    @setPresentationMilestone = (task_id, new_milestone_time) ->
      self.task_id_to_info[task_id].milestone_time = new_milestone_time
      self.gantt_dirty_tasks.add task_id
      self.processGanttDirtyTasks()
      return
  
    @setPresentationStartTime = (task_id, new_start_time) ->
      self.task_id_to_info[task_id].self_start_time = new_start_time
      self.gantt_dirty_tasks.add task_id
      self.processGanttDirtyTasks()
      return
      
    @updateTaskStartDateBasedOnDependencies = (dependent_obj, independent_id) ->
      # we need to now go over all independents tasks and find the limiting factors. This could have been done with a
      # single find command, but since it's a client side code, and we have the tasks' ids, it is easier to go one by
      # one. In this specific case, it's probably as effective.
      
      #todo: for now we just check F2S dependencies. When other types will be supported we will need to touch this code
      latest_independent_date = null
      if not (dependencies_mf = dependent_obj.justdo_task_dependencies_mf)?
        return
      for dependency in dependencies_mf
        independent_obj = JD.collections.Tasks.findOne dependency.task_id
        if dependency.type == "F2S"
          if (independent_end_date = independent_obj.end_date)?
            if not latest_independent_date? or independent_end_date > latest_independent_date
              latest_independent_date = independent_end_date
          if (latest_child  = @task_id_to_info[dependency.task_id]?.latest_child_end_time)?
            independent_end_date = moment.utc(latest_child).format("YYYY-MM-DD")
            if not latest_independent_date? or independent_end_date > latest_independent_date
              latest_independent_date = independent_end_date
  
      if latest_independent_date?
        next_date = moment.utc(latest_independent_date)
        next_date.add 1, 'day'
        next_date = next_date.format("YYYY-MM-DD")
        if next_date != dependent_obj.start_date
          if independent_id? and self.task_ids_edited_locally.has independent_id
            self.task_ids_edited_locally.add dependent_obj._id
          self.moveTaskToNewStartDate dependent_obj, next_date
      
      return
      
    @updateDependentTasks = (original_task_obj_id) ->
      JD.collections.Tasks.find({"justdo_task_dependencies_mf.task_id": original_task_obj_id}).forEach (dependent) ->
        self.updateTaskStartDateBasedOnDependencies dependent, original_task_obj_id
      return
  
    @moveTaskToNewStartDate = (task_obj, new_start_date) ->
      self = @
      # Important note: in this version, we just use calendar days, we ignore weekends, holidays, vacations and personal days etc.
      # todo - include weekends and holidays in duration,
      # todo - don't start a task on weekend/holiday
      set_value = {}
      set_value.start_date = new_start_date
      task_duration = 1
      
      if (prev_start_date = task_obj.start_date)?
        if (prev_end_date = task_obj.end_date or task_obj.due_date)?
          prev_start_date_moment = moment.utc prev_start_date
          prev_end_date_moment = moment.utc prev_end_date
          task_duration = prev_end_date_moment.diff prev_start_date_moment, "days"
  
      new_end_data_moment = moment.utc(new_start_date)
      new_end_data_moment = new_end_data_moment.add task_duration, "days"
      set_value.end_date = new_end_data_moment.format("YYYY-MM-DD")
      
      # Daniel - need your help here - w/o this defer, the database is updates but the local
      # grid is not updating. todo: Need to understand why, and hopefully remove this defer.
      Meteor.defer =>
        JD.collections.Tasks.update
          _id: task_obj._id
        ,
          $set: set_value
        ,
          (err)->
            if err?
              console.error err
              return
            # important note - must call with the _id and not the object, because the object changes by the update
            # call, but task_obj doesn't
            self.updateDependentTasks task_obj._id
            return #end of callback
      return
      
  _deferredInit: ->
    self = @
    
    if @destroyed
      return
    
    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    
    return
  
  setColumnWidth: (width) ->
    if (gc_id = APP.modules.project_page.gridControl()?.getGridUid())?
      if not @_columns_width[gc_id]?
        @_columns_width[gc_id] = new ReactiveVar width
      else
        @_columns_width[gc_id].set width
    return
  
  getColumnWidth: ->
    if not (gc = APP.modules.project_page.gridControl())?
      return -1
    if (gc_id = gc.getGridUid())?
      if @_columns_width[gc_id]?
        return @_columns_width[gc_id].get()
    
    # in case we didn't find it cached (happens on initiation once)
    for column in gc.getView()
      if column.field == JustdoGridGantt.pseudo_field_id
        @setColumnWidth column.width
        return column.width
    
    return -1
    
  zoomIn: ->
    range = @getEpochRange()
    third = (range[1] - range[0]) / 3
    @setEpochRange [(range[0] + third), (range[1] - third)]
    return
  
  zoomOut: ->
    range = @getEpochRange()
    delta = range[1] - range[0]
    @setEpochRange [(range[0] - delta), (range[1] + delta)]
    return
  
  getEpochRange: ->
    if not (gc_id = APP.modules.project_page.gridControl()?.getGridUid())?
      return [0, 0]
    if not (range = @_epoch_range[gc_id])?
      start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
      from = new ReactiveVar (start_of_day_epoch - 5 * day)
      to = new ReactiveVar (start_of_day_epoch + 6 * day - 1000)
      range = [from, to]
      @_epoch_range[gc_id] = range
    return [range[0].get(), range[1].get()]
  
  setEpochRange: (range) ->
    if not (gc_id = APP.modules.project_page.gridControl()?.getGridUid())?
      return
    @_epoch_range[gc_id][0].set(range[0])
    @_epoch_range[gc_id][1].set(range[1])
    return
    
  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoGridGantt.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoGridGantt.project_custom_feature_id})

  setupCustomFeatureMaintainer: ->
    self = @
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGridGantt.project_custom_feature_id,
        installer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoGridGantt.pseudo_field_id,
              label: JustdoGridGantt.pseudo_field_label
              field_type: JustdoGridGantt.pseudo_field_type
              formatter: JustdoGridGantt.pseudo_field_formatter_id
              grid_visible_column: true
              grid_editable_column: false
              default_width: 400

          # trigger observer reset on justdo change
          self.core_data_events_triggering_computation = Tracker.autorun =>
            if (justdo_id = JD.activeJustdo({_id: 1})?._id)?
              Tracker.nonreactive =>
                self.initTaskIdToInfo()
              if (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
                core_data.on "data-changes-queue-processed", self.processChangesQueue
            else
              self.resetTaskIdToInfo()
            return
    
        destroyer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.pseudo_field_id

          if self.core_data_events_triggering_computation?
            self.core_data_events_triggering_computation.stop()
  
          if (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
            core_data.off "data-changes-queue-processed", self.processChangesQueue
            
          @dependencies_map = {}
          @dependents_to_keys_set = {}
          @task_id_to_info = {}
          @_states_manager = {}
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
    
  is_gantt_column_displayed_rv: new ReactiveVar false
  