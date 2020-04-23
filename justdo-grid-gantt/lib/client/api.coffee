_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    
    @fileds_to_trigger_task_change_process = ["start_date", "end_date", "due_date"]
    
    @day =  24 * 3600 * 1000

    start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
    @gantt_coloumn_from_epoch_time_rv = new ReactiveVar (start_of_day_epoch - 5 * @day)
    @gantt_coloumn_to_epoch_time_rv = new ReactiveVar (start_of_day_epoch + 6 * @day - 1000)
  
    @task_id_to_info = {} # Map to relevant information including
                          #   self_start_time: #indicates the beginning of the gantt block for the task
                          #   self_end_time: #indicates the ending of the gantt block for the task
                          #   milestone_time:
                          #   earliest_child_start_time: # the earliest child task start time
                          #   latest_child_end_time: # the latest child task end time
                          #   alerts: [<structure TBD>,]
                          # (*)all times in epoch
    @gantt_dirty_tasks = new Set()
    
    @resetTaskIdToInfo = ->
      self.task_id_to_info = {}
      return
      
    @initTaskIdToInfo = ->
      self.resetTaskIdToInfo()
      if not (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
        return
      for task_id, task_obj of core_data.items_by_id
        self.onTaskChange task_obj
        
      self.processGanttDirtyTasks()
      return # end of initTaskIdToInfo
    
    @processChangesQueue = (queue) =>
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      for [msg_type, [task_id, data]] in queue.queue
        if msg_type == "update"
          for field in data
            if field in self.fileds_to_trigger_task_change_process
              self.onTaskChange core_data.items_by_id[task_id]
              break
        else if msg_type == "add"
          self.onTaskChange data
        else if msg_type == "remove"
          self.onTaskRemove task_id
        else
          console.error "justdo-grid-gantt unhandled msg type", msg_type
    
      self.processGanttDirtyTasks()
    
      return # end of process changes queue
  
    @processGanttDirtyTasks = () ->
      if not (column_index = JustdoHelpers.sameTickCacheGet("column_index"))?
        gc = APP.modules.project_page.gridControl()
        column_index = gc.getFieldIdToColumnIndexMap()[JustdoGridGantt.pseudo_field_id]
        JustdoHelpers.sameTickCacheSet("column_index", column_index)
        
      if not (tree_indices = JustdoHelpers.sameTickCacheGet("tree_indices"))?
        gc = APP.modules.project_page.gridControl()
        tree_indices = gc._grid_data._items_ids_map_to_grid_tree_indices
        JustdoHelpers.sameTickCacheSet("tree_indices", tree_indices)
      
      if column_index?
        self.gantt_dirty_tasks.forEach (task_id) ->
          if task_id != "0" # this the mother of all root tasks. Daniel - I need guidance if change is needed
            if (rows = tree_indices[task_id])?
              for row in rows
                APP.modules.project_page.gridControl()._grid.updateCell(row, column_index)
          return # end of for each
      
      self.gantt_dirty_tasks.clear()
      return # end of process gantt dirty tasks
  
    @onTaskChange = (task_obj) ->
      if not(task_info = self.task_id_to_info[task_obj._id])?
        task_info = {}
        self.task_id_to_info[task_obj._id] = task_info
      
      old_task_info = $.extend {}, task_info
      
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
        self.onStartTimeChange task_obj._id, task_info, old_task_info
  
      # checking end_time change
      if task_info.self_end_time != old_task_info.self_end_time
        self.onEndTimeChange task_obj._id, task_info, old_task_info
      
      #checking milestone
      if task_info.milestone_time != old_task_info.milestone_time
        self.onMilestoneTimeChange task_obj._id, task_info, old_task_info
      
      
      return # end of onTaskChange
    
    @onTaskRemove = (task_id) ->
      if not (old_task_info = self.task_id_to_info[task_id])?
        return
      
      if old_task_info.self_start_time?
        self.onStartTimeChange task_id, {}, old_task_info
      if old_task_info.self_end_time?
        self.onEndTimeChange StartTimeChange task_id, {}, old_task_info
      if old_task_info.milestone_time?
        self.onMilestoneTimeChange() task_id, {}, old_task_info
        
      delete self.task_id_to_info[task_id]
      return
  
    @onStartTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      # for the value of the earliest child, we take the minimum of the start_time and the earliest_child_start_time
      start_time = self.earliestOfSelfStartAndEarliestChildStart task_info
      old_start_time = self.earliestOfSelfStartAndEarliestChildStart old_task_info
      
      # loop on all parents to update the earliest child task
      core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core
      if (parents = core_data.items_by_id?[task_id]?.parents)?
        for parent_id of parents
          parent_changed = false
          parent_task_info = self.getOrCreateTaskInfoObject parent_id
          old_parent_task_info = _.extend {}, parent_task_info
          
          # we have 4 cases to cover: new start_time, start_time removed, start_time increased, start_time decreased
  
          # 1. new start_time
          if start_time? and not old_start_time
            if not parent_task_info.earliest_child_start_time?
              parent_task_info.earliest_child_start_time = start_time
              parent_changed = true
            else # parent early child exists
              if start_time < parent_task_info.earliest_child_start_time
                parent_task_info.earliest_child_start_time = start_time
                parent_changed = true
              # else - do noting because both start time is new but bigger than existing parent earliest child stark
          
          # 2. start_time removed
          else if not start_time? and old_start_time
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
              parent_changed = self.recalculateEarliestChildTime parent_id
              
          else if not start_time and not old_start_time # we should never get here, so alert if we do:
            console.error "grid-gantt: unresolved start change"
          
          if parent_changed
            self.onStartTimeChange parent_id, parent_task_info, old_parent_task_info
        
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
  
    @getOrCreateTaskInfoObject = (task_id) ->
      if not (task_info = self.task_id_to_info[task_id])?
        task_info = {}
        self.task_id_to_info[task_id] = task_info
      return task_info
      
    @onEndTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      console.log ">>>> on end change", task_info, old_task_info
      return
      
    @onMilestoneTimeChange = (task_id, task_info, old_task_info) ->
      self.gantt_dirty_tasks.add task_id
      console.log ">>>>> on milstone change", task_info, old_task_info
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
      if time < epoch_start or time > epoch_end or epoch_end <= epoch_start
        return undefined
      return (time - epoch_start) / (epoch_end - epoch_start) * width_in_pixels
      
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
    
  
  
  _deferredInit: ->
    self = @
    
    if @destroyed
      return
    
    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    
    # trigger observer reset on justdo change
    Tracker.autorun =>
      if (justdo_id = JD.activeJustdo({_id: 1})?._id)?
        self.initTaskIdToInfo()
        if (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
          core_data.on "data-changes-queue-processed", self.processChangesQueue
          # note: (Daniel - please confirm) - when the user changes to a different JustDo, the mainGridControl object
          # is deleted, and with it grid_data_core and the event emitter, so there is no need to explicitly call
          # core_data.off(...)
      else
        self.resetTaskIdToInfo()
      return
    
    return
  
  
  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoGridGantt.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoGridGantt.project_custom_feature_id})

  setupCustomFeatureMaintainer: ->
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
              grid_dependencies_fields: JustdoGridGantt.gantt_field_grid_dependencies_fields
              default_width: 400

          controller = JustdoHelpers.renderTemplateInNewNode("justdo_grid_gantt_controller")
          APP.justdo_grid_gantt.controller_node = $(controller.node)
          $("body").append(APP.justdo_grid_gantt.controller_node)

        destroyer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.pseudo_field_id

          if APP.justdo_grid_gantt.controller_node?
            APP.justdo_grid_gantt.controller_node.remove()
            APP.justdo_grid_gantt.controller_node
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
    
  is_gantt_column_displayed_rv: new ReactiveVar false
  