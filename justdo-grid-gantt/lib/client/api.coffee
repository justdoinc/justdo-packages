_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
  
    @_states_manager = {}
    
    @fields_to_trigger_task_change_process = ["start_date", "end_date", "due_date", "parents"]
    
    @day =  24 * 3600 * 1000

    start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
    @gantt_coloumn_from_epoch_time_rv = new ReactiveVar (start_of_day_epoch - 5 * @day)
    @gantt_coloumn_to_epoch_time_rv = new ReactiveVar (start_of_day_epoch + 6 * @day - 1000)
    @grid_gantt_column_width = -1
    @grid_gantt_column_index = 0
  
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
      # APP.modules.project_page.gridControl()._grid_data.once "rebuild", ->
      #   self.processGanttDirtyTasks()
      #   return
    
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
      self.refreshArrows 1,10
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
        
      return
      
    @processTaskChange = (task_obj) ->
      if not(task_info = self.task_id_to_info[task_obj._id])?
        console.error "grid-gantt - unidentified task changed"
        # task_info =
        #   parents: Object.keys task_obj.parents
        # self.task_id_to_info[task_obj._id] = task_info
        # self.gantt_dirty_tasks.add task_obj._id
        
      
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
      return
  
    @processTaskParentUpdate = (task_id) ->
      if not (old_task_info = self.task_id_to_info[task_id])?
        console.error "grid-gantt - task not found (parents-update)"
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
      day = 1000 * 60 * 60 * 24
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
      from_epoch = self.gantt_coloumn_from_epoch_time_rv.get()
      to_epoch = self.gantt_coloumn_to_epoch_time_rv.get()
      return delta_pixels / self.grid_gantt_column_width * (to_epoch - from_epoch)
    
      
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
  
  _deferredInit: ->
    self = @
    
    if @destroyed
      return
    
    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    
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

          controller = JustdoHelpers.renderTemplateInNewNode("justdo_grid_gantt_controller")
          APP.justdo_grid_gantt.controller_node = $(controller.node)
          $("body").append(APP.justdo_grid_gantt.controller_node)
  
          # trigger observer reset on justdo change
          self.core_data_events_triggering_computation = Tracker.autorun =>
            if (justdo_id = JD.activeJustdo({_id: 1})?._id)?
              Tracker.nonreactive =>
                self.initTaskIdToInfo()
              if (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
                core_data.on "data-changes-queue-processed", self.processChangesQueue
              # note: (Daniel - please confirm) - when the user changes to a different JustDo, the mainGridControl object
              # is deleted, and with it grid_data_core and the event emitter, so there is no need to explicitly call
              # core_data.off(...)
            else
              self.resetTaskIdToInfo()
            return
    
        destroyer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.pseudo_field_id

          if APP.justdo_grid_gantt.controller_node?
            APP.justdo_grid_gantt.controller_node.remove()
            APP.justdo_grid_gantt.controller_node
            
          if self.core_data_events_triggering_computation?
            self.core_data_events_triggering_computation.stop()
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
    
  is_gantt_column_displayed_rv: new ReactiveVar false
  