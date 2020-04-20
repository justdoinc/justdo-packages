_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    @day =  24 * 3600 * 1000

    start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
    @gantt_coloumn_from_epoch_time_rv = new ReactiveVar (start_of_day_epoch - 5 * @day)
    @gantt_coloumn_to_epoch_time_rv = new ReactiveVar (start_of_day_epoch + 6 * @day - 1000)
  
    @task_id_to_info = {}
    @seq_id_to_task_id = {}
    @task_seqId_to_dependies = {} # a dictionary of seqId to Set of tasks ids
    @task_id_to_child_tasks = {}  # a dictionary of task_id to Set of direct children ids
    
    @onTaskAdded = (task_obj) ->
      console.log ">>>> task added", task_obj.seqId
      self.task_id_to_info[task_obj._id] =
        task_obj: task_obj
        grid_rows: []
        gantt_data:
          earliest_child_start_time: null
          latest_chiled_end_time: null
          alerts: []
      self.seq_id_to_task_id[task_obj.seqID] = task_obj._id
      # adding parents
      for parent_id, data of task_obj.parents
        if not(set = self.task_id_to_child_tasks[parent_id])?
          set = new Set()
          self.task_id_to_child_tasks[parent_id] = set
        set.add task_obj._id
      # adding dependies
      for task_seq in APP.justdo_dependencies?.dependentTasksBySeqNumber task_obj
          if not (set = self.task_seqId_to_dependies[task_seq])?
            set = new Set()
            self.task_seqId_to_dependies[task_seq] = set
          set.add task_obj._id
      return
  
    @onTaskChanged = (new_task_obj, old_task_obj) ->
      # dealing with change of parents:
      new_task_parents = Object.keys new_task_obj.parents
      old_task_parents = Object.keys old_task_obj.parents
      # for parents added
      _.each new_task_parents, (new_parent_id) ->
        if new_parent_id not in old_task_parents
          if not (set = self.task_id_to_child_tasks[new_parent_id])?
            set = new Set()
            self.task_id_to_child_tasks[new_parent_id] = set
          set.add new_task_obj._id
      # for parents removed
      _.each old_task_parents, (old_parent_id) ->
        if old_parent_id not in new_task_parents
          if (set = self.task_id_to_child_tasks[new_parent_id])?
            set.delete old_parent_id
      # dependency changes
      new_tasks_dependencies = APP.justdo_dependencies?.dependentTasksBySeqNumber new_task_obj
      old_tasks_dependencies = APP.justdo_dependencies?.dependentTasksBySeqNumber old_task_obj
      # for dependency added
      _.each new_tasks_dependencies, (new_dep_seq_number) ->
        if new_dep_seq_number not in old_tasks_dependencies
          if not (set = self.task_seqId_to_dependies[new_dep_seq_number])?
            set = new Set()
            self.task_seqId_to_dependies[new_dep_seq_number] = set
          set.add new_task_obj._id
      # for dependent removed
      _.each old_tasks_dependencies, (old_dep_seq_number) ->
        if old_dep_seq_number not in new_tasks_dependencies
          if (set = self.task_seqId_to_dependies[old_dep_seq_number])?
            set.delete new_task_obj._id
        
      return
  
    @onTaskRemoved = (task_obj) ->
      delete self.task_id_to_info[task_obj._id]
      delete self.seq_id_to_task_id[task_obj.seqID]
      # parents
      for parent_id, data of task_obj.parents
        if (set = self.task_id_to_child_tasks[parent_id])?
          set.delete task_obj._id
      #dependies
      for task_seq in APP.justdo_dependencies?.dependentTasksBySeqNumber task_obj
        if (set = self.task_seqId_to_dependies[task_seq])?
          set.delete task_obj._id
      return
  
    @setObserver = (justdo_id)->
      self.stopObserver()
      fields =
        _id: 1
        from_date: 1
        end_date: 1
        due_date: 1
        justdo_task_dependencies: 1
        parents: 1
        seqId: 1
        
      cursor = JD.collections.Tasks.find
        project_id: justdo_id
      ,
        fields: fields
    
      self.observer = cursor.observe
        added: (task_obj)->
          self.onTaskAdded task_obj
          return
        changed: (new_task_obj, old_task_obj)->
          self.onTaskChanged new_task_obj, old_task_obj
          return
        removed: (task_obj)->
          self.onTaskRemoved task_obj
          return
      console.log ">>>> observer set"
      return
  
    @stopObserver = ->
      if self.observer?
        self.observer.stop()
      self.observer = null
      self.task_id_to_info = {}
      self.seq_id_to_task_id = {}
      self.task_seqId_to_dependies = {}
      self.task_id_to_child_tasks = {}
      console.log ">>>>>> observer stopped"
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
          self.setObserver justdo_id
      else
        self.stopObserver()
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
  