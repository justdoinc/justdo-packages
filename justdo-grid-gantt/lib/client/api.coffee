_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    
    @fileds_to_trigger_task_change_process = ["start_date", "end_date", "due_date"]
    
    @day =  24 * 3600 * 1000

    start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
    @gantt_coloumn_from_epoch_time_rv = new ReactiveVar (start_of_day_epoch - 5 * @day)
    @gantt_coloumn_to_epoch_time_rv = new ReactiveVar (start_of_day_epoch + 6 * @day - 1000)
  
    @task_id_to_info = {} # Map to relevant information including
                          #   block_start_time: #indicates the beginning of the gantt block
                          #   block_end_time: #indicates the ending of the gantt block
                          #   milestone_time:
                          #   earliest_child_start_time: <>
                          #   latest_chiled_end_time: <>
                          #   alerts: [<structure TBD>,]
                          # (*)all times in epoch
    
    @resetTaskIdToInfo = ->
      self.task_id_to_info = {}
      return
      
    @initTaskIdToInfo = ->
      self.resetTaskIdToInfo()
      if not (core_data = APP.modules.project_page.mainGridControl()?._grid_data?._grid_data_core)?
        return
      for task_id, task_obj of core_data.items_by_id
        self.onTaskChange task_obj
      return # end of initTaskIdToInfo
  
    @onTaskChange = (task_obj) ->
      if not(task_info = self.task_id_to_info[task_obj._id])?
        task_info = {}
        self.task_id_to_info[task_obj._id] = task_info
      
      old_task_info = $.extend {}, task_info
      
      # start time
      if task_obj.start_date?
        task_info.block_start_time = self.dateStringToStartOfDayEpoch task_obj.start_date
      else
        delete task_info.block_start_time
        
      # end time
      if task_obj.end_date?
        task_info.block_end_time = self.dateStringToEndOfDayEpoch task_obj.end_date
      else if task_obj.due_date? and task_obj.start_date
        task_info.block_end_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.block_end_time
        
      # milestone
      if task_obj.due_date?
        task_info.milestone_time = self.dateStringToMidDayEpoch task_obj.due_date
      else
        delete task_info.milestone_time
      
      return # end of onTaskChange
    
    @onTaskRemove = (task_id) ->
      if not self.task_id_to_info[task_id]?
        return
      delete self.task_id_to_info[task_id]
      return
      
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
  