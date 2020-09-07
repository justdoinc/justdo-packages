day =  24 * 3600 * 1000

_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    @_states_manager = {}
    
    @fields_to_trigger_task_change_process = ["start_date", "end_date", "due_date", "parents", 
      JustdoGridGantt.is_milestone_pseudo_field_id, JustdoDependencies.dependencies_mf_field_id,
      JustdoGridGantt.progress_percentage_pseudo_field_id,
      JustdoDependencies.is_task_dates_frozen_pseudo_field_id
    ]
    
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
                          #   lead_to_milestones:
                          #   critical_path_of_milestones:
                          #   milestone_subtasks:
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
        if task_obj[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"
          self.dirty_milestones.add task_obj._id
        
      self.processGanttDirtyTasks()
      self.processDirtyMilestones()

      return # end of initTaskIdToInfo
    
    @processChangesQueue = (queue) =>
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      for [msg_type, [task_id, data]] in queue.queue
        if msg_type == "update"
          for field in data
            if field in self.fields_to_trigger_task_change_process
              self.processTaskChange core_data.items_by_id[task_id]
              self.gantt_dirty_tasks.add task_id
        else if msg_type == "add"
          self.processTaskAdd data
        else if msg_type == "remove"
          self.processTaskRemove task_id
        else if msg_type == "parent_update"
          self.processTaskParentUpdate task_id
        else
          console.error "justdo-grid-gantt unhandled msg type", msg_type

      self.processDirtyMilestones()
      self.processGanttDirtyTasks()
      return # end of process changes queue
  
    @processGanttDirtyTasks = () ->
      if not (gc = APP.modules.project_page.gridControl())?
        self.gantt_dirty_tasks.clear() # todo: Amit is uncertain about this solution, need to rethink, can't explain why
                                       # we get to this phase.
        return
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
        task_info.self_end_time = self.dateStringToEndOfDayEpoch task_obj.end_date
      #   if task_obj.end_date == task_obj.due_date
      #     task_info.self_end_time = self.dateStringToMidDayEpoch task_obj.end_date
      #   else
      #     task_info.self_end_time = self.dateStringToEndOfDayEpoch task_obj.end_date
          
      # else if task_obj.due_date? and task_obj.start_date
      #   task_info.self_end_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.self_end_time
      
      if task_obj.due_date?
        task_info.due_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.due_time

      # milestone
      if task_obj[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and task_obj.start_date?
        task_info.milestone_time = self.dateStringToStartOfDayEpoch task_obj.start_date
        task_info.self_start_time = task_info.self_end_time = task_info.milestone_time
        if not task_info.milestone_subtasks?
          task_info.milestone_subtasks = []
      else
        delete task_info.milestone_time

      if task_obj[JustdoDependencies.is_task_dates_frozen_pseudo_field_id] == "true"
        task_info.is_dates_frozen = true
      else
        delete task_info.is_dates_frozen
      
      # dependencies
      if (dependencies_mf = task_obj[JustdoDependencies.dependencies_mf_field_id])?
        task_info.dependencies = _.map dependencies_mf, (dep) -> dep.task_id
      else
        delete task_info.dependencies

      if (progress_percentage = task_obj[JustdoGridGantt.progress_percentage_pseudo_field_id])?
        task_info.progress_percentage = progress_percentage
      else
        delete task_info.progress_percentage

      # checking start_time change
      if task_info.self_start_time != old_task_info.self_start_time
        self.processStartTimeChange task_obj._id, task_info, old_task_info
  
      # checking end_time change
      if task_info.self_end_time != old_task_info.self_end_time
        self.processEndTimeChange task_obj._id, task_info, old_task_info
      
      #checking milestone
      if task_info.milestone_time != old_task_info.milestone_time
        self.dirty_milestones.add task_obj._id

      # check if any milestones need to be marked as dirty
      if task_info.self_start_time != old_task_info.self_start_time or 
          task_info.self_end_time != old_task_info.self_end_time or
          not _.isEqual task_info.dependencies, old_task_info.dependencies
        self.addDirtyMilestonesOfTask task_obj._id

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
      
      self.addDirtyMilestonesOfTask task_id

      delete self.task_id_to_info[task_id]
      self.warnings_manager.removeTask task_id
      return
  
    @processTaskParentUpdate = (task_id) ->
      self = @

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
        critical_child_count = _.extend {}, old_task_info.critical_child_count
        for milestone_task_id of old_task_info.critical_path_of_milestones
          if milestone_task_id == old_task_info._id
            continue
          critical_child_count[milestone_task_id] = if critical_child_count[milestone_task_id]? then critical_child_count[milestone_task_id]+1 else 1
        self.incCriticalChildCount parent_id, critical_child_count
      parents_removed.forEach (parent_id) ->
        all_changed_parents.push parent_id
        critical_child_count = _.extend {}, old_task_info.critical_child_count
        for milestone_task_id of old_task_info.critical_path_of_milestones
          if milestone_task_id == old_task_info._id
            continue
          critical_child_count[milestone_task_id] = if critical_child_count[milestone_task_id]? then critical_child_count[milestone_task_id]+1 else 1
        self.decCriticalChildCount parent_id, critical_child_count
        
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
      if not task_info?
        task_info = {
          parents: []
        }
      if not old_task_info?
        old_task_info = {
          parents: []
        }

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
      if not task_info?
        task_info = {
          parents: []
        }
      if not old_task_info?
        old_task_info = {
          parents: []
        }

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
        task_info = {
          lead_to_milestones: {}
          critical_path_of_milestones: {}
          critical_child_count: {}
        }
        self.task_id_to_info[task_id] = task_info
        self.gantt_dirty_tasks.add task_id
      return task_info
      
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

    @setPresentationDueTime = (task_id, new_due_time) ->
      self.task_id_to_info[task_id].due_time = new_due_time
      self.gantt_dirty_tasks.add task_id
      self.processGanttDirtyTasks()
      return

    @setPresentationStartTime = (task_id, new_start_time) ->
      self.task_id_to_info[task_id].self_start_time = new_start_time
      self.gantt_dirty_tasks.add task_id
      self.processGanttDirtyTasks()
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
          
          APP.modules.project_page.setupPseudoCustomField JustdoGridGantt.is_milestone_pseudo_field_id,
            label: JustdoGridGantt.is_milestone_pseudo_field_label
            field_type: "select"
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100
            field_options :
              select_options : [
                {option_id: "true", label: "Yes"}
              ]
          
          APP.modules.project_page.setupPseudoCustomField JustdoGridGantt.progress_percentage_pseudo_field_id,
            label: JustdoGridGantt.progress_percentage_pseudo_field_label
            field_type: "number"
            formatter: JustdoGridGantt.progress_percentage_pseudo_field_formatter_id
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100
          
          @setupStartDateEndDateChangeHintForMilestones()

          self.setupContextMenu()

          return
    
        destroyer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.pseudo_field_id

          APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.is_milestone_pseudo_field_id
          APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.progress_percentage_pseudo_field_id

          if self.core_data_events_triggering_computation?
            self.core_data_events_triggering_computation.stop()
  
          if (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
            core_data.off "data-changes-queue-processed", self.processChangesQueue
          
          @cleanupStartDateEndDateChangeHintForMilestones()

          self.unsetContextMenu()

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
  
  isTaskGanttMilestone: (task_id) ->
    task = APP.collections.Tasks.findOne task_id,
      fields:
        "#{JustdoGridGantt.is_milestone_pseudo_field_id}": 1
    return task?[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"

  setupContextMenu: ->
    self = @

    context_menu = APP.justdo_tasks_context_menu

    context_menu.registerMainSection "gantt",
      position: 400
      data:
        label: "Gantt"

    context_menu.registerSectionItem "gantt", "set-as-gantt-milestone",
      position: 100
      data:
        label: "Set as a Gantt milestone"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.collections.Tasks.update task_id,
            $set:
              "#{JustdoGridGantt.is_milestone_pseudo_field_id}": "true"
          return
        icon_type: "feather"
        icon_val: "jd-rhombus"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return not self.isTaskGanttMilestone task_id
    
    context_menu.registerSectionItem "gantt", "unset-as-gantt-milestone",
      position: 100
      data:
        label: "Unset as a Gantt milestone"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.collections.Tasks.update task_id,
            $set:
              "#{JustdoGridGantt.is_milestone_pseudo_field_id}": null
          return
        icon_type: "feather"
        icon_val: "jd-x-rhombus"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return self.isTaskGanttMilestone task_id
    
    return

  unsetContextMenu: ->
    context_menu = APP.justdo_tasks_context_menu
    context_menu.unregisterMainSection "gantt"

    return
  
  _is_dragging_milestone_no_hint : false
  date_change_hint_hook_handler: null
  setupStartDateEndDateChangeHintForMilestones: ->
    self = @
    self.date_change_hint_hook_handler = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
      if doc[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and self.isGridGanttInstalledInJustDo JD.activeJustdoId()
        if modifier?.$set?.start_date == modifier?.$set?.end_date
          return true

        if self._is_dragging_milestone_no_hint == false and (modifier?.$set?.start_date != undefined or modifier?.$set?.end_date != undefined)
          JustdoSnackbar.show
            text: "The end date will always be same as the start date because this task is set as a Gantt milestone"

        if modifier?.$set?.end_date != undefined
          return false
        
        self._is_dragging_milestone_no_hint = false

      return true
      
    return
  
  cleanupStartDateEndDateChangeHintForMilestones: ->
    if self.date_change_hint_hook_handler?
      self.date_change_hint_hook_handler.remove()
      self.date_change_hint_hook_handler = null

    return

  # --------- Critical path --------- #
  dirty_milestones: new Set()

  addDirtyMilestonesOfTask: (task_id) ->
    self = @

    for milestone_task_id of self.task_id_to_info[task_id].lead_to_milestones
      self.dirty_milestones.add milestone_task_id
    
    return

  processDirtyMilestones: ->
    self = @

    self.dirty_milestones.forEach (task_id) ->
      self.recalculateCriticalPath task_id

    self.dirty_milestones.clear()

    return

  recalculateCriticalPath: (milestone_task_id) ->
    self = @
    tasks_info = self.task_id_to_info
    
    if not (milestone_subtasks = tasks_info[milestone_task_id].milestone_subtasks)?
      return 

    # Clean up previous ciritical path info
    for subtask_id in milestone_subtasks
      delete tasks_info[subtask_id].lead_to_milestones[milestone_task_id]
      if subtask_id != milestone_task_id and tasks_info[subtask_id].critical_path_of_milestones[milestone_task_id]?
        for parent_id in tasks_info[subtask_id].parents
          self.decCriticalChildCount parent_id,
            "#{milestone_task_id}": 1
      delete tasks_info[subtask_id].critical_path_of_milestones[milestone_task_id]
      self.gantt_dirty_tasks.add subtask_id

    if tasks_info[milestone_task_id].milestone_time?
      tasks_info[milestone_task_id].milestone_subtasks = []
      self._cpBackwardPass milestone_task_id, milestone_task_id, true
    else
       # the task is no longer a milestone
      delete tasks_info[milestone_task_id].milestone_subtasks

    return
  
  _cpBackwardPass: (milestone_task_id, task_id, is_cp=true) ->
    self = @
    tasks_info = self.task_id_to_info

    self.gantt_dirty_tasks.add task_id

    # Add lead_to_milestones
    tasks_info[milestone_task_id].milestone_subtasks.push task_id
    tasks_info[task_id].lead_to_milestones[milestone_task_id] = true

    # Add critical_path_of_milestones
    if is_cp
      tasks_info[task_id].critical_path_of_milestones[milestone_task_id] = true
      if milestone_task_id != task_id
        for parent_id in tasks_info[task_id].parents
          self.incCriticalChildCount parent_id,
            "#{milestone_task_id}": 1

    if not (task_items = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core?.items_by_id)?
      return

    if not (dependencies_mf = task_items[task_id]?.justdo_task_dependencies_mf)?
      return

    for dependency in dependencies_mf
      self._cpBackwardPass milestone_task_id, dependency.task_id, (is_cp and self._isStartedImmediatelyAfter(task_id, dependency.task_id))

    return
  
  incCriticalChildCount: (task_id, counts_to_inc) ->
    self = @

    task_info = self.task_id_to_info[task_id]
    if not task_info?
      return

    for milestone_task_id, val of counts_to_inc
      critical_child_count = task_info.critical_child_count[milestone_task_id]
      task_info.critical_child_count[milestone_task_id] = if critical_child_count? then critical_child_count+val else val

    self.gantt_dirty_tasks.add task_id
    
    if (parents = task_info.parents)?
      for parent_id in parents
        # if the parent_id is in the missing parents, we won't deal with it now, since we don't know its own
        # parents, and won't be able to change those as well. We will process it when it's added.
        if self.missing_parents.has parent_id
          return # keep going on the forEach
          
        self.incCriticalChildCount parent_id, counts_to_inc

    return

  decCriticalChildCount: (task_id, counts_to_dec) ->
    self = @

    task_info = self.task_id_to_info[task_id]
    if not task_info?
      return

    for milestone_task_id, val of counts_to_dec
      critical_child_count = task_info.critical_child_count[milestone_task_id]
      task_info.critical_child_count[milestone_task_id] = if critical_child_count? then critical_child_count-val else 0

    self.gantt_dirty_tasks.add task_id

    if (parents = task_info.parents)?
      for parent_id in parents
        # if the parent_id is in the missing parents, we won't deal with it now, since we don't know its own
        # parents, and won't be able to change those as well. We will process it when it's added.
        if self.missing_parents.has parent_id
          return # keep going on the forEach
          
        self.decCriticalChildCount parent_id, counts_to_dec

    return

  _isStartedImmediatelyAfter: (dependent_id, independent_id) ->
    self = @
    tasks_info = self.task_id_to_info
    if not ((dependent_info = tasks_info[dependent_id])? and
        dependent_info.self_start_time? and dependent_info.self_end_time?)
      return false
    if not ((independent_info = tasks_info[independent_id])? and
        independent_info.self_start_time? and independent_info.self_end_time?)
      return false

    end_moment = moment.utc(independent_info.self_end_time).startOf("day")
    if not independent_info.milestone_time?
      end_moment.add(1, "day")
    start_moment = moment.utc(dependent_info.self_start_time).startOf("day")
    return end_moment.isSame start_moment

  isCriticalTask: (task_id) ->
    self = @
    return not _.isEmpty self.task_id_to_info[task_id].critical_path_of_milestones
  
  isCriticalEdge: (dependent_id, independent_id) ->
    self = @
    return self.isCriticalTask(dependent_id) and self.isCriticalTask(independent_id) and self._isStartedImmediatelyAfter dependent_id, independent_id

  hasCriticalChild: (task_id) ->
    self = @
    if (critical_child_count = self.task_id_to_info[task_id]?.critical_child_count)?
      for milestone_task_id, count of critical_child_count
        if count > 0
          return true
    
    return false
  # ------End of Critical path -------- #
