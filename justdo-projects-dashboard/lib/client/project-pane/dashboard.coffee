Template.justdo_projects_dashboard.onCreated ->
  self = @
  
  # one observer to trigger on all information that we care about
  @observer = null
  
  @triggerProjectsReactivityForTask = (task_id, wait) ->
    if not (gc = APP.modules.project_page.mainGridControl())?
      return
    if  not(gd = gc._grid_data)?
      return
      
    # we need to sample the paths twice - for delete and change operations the path exists only before the timeout,
    # for inserts, the paths exists only after
    timeout = 500 # Daniel - what's a reasonable timeout?
    if (paths = gd.getAllCollectionItemIdPaths(task_id))?
      timeout = 0
    Meteor.setTimeout ->
      if not paths?
        if not (paths = gd.getAllCollectionItemIdPaths(task_id))?
          # we shouldn't get here
          return
      
      for path in paths
        for parent_id in path.split("/")
          if (template_instance = APP.justdo_projects_dashboard.project_id_to_template_instance[parent_id])?
            template_instance.is_dirty_rv.set true
      return # end of settimeout
    ,
      500
    return

  # the following is an autorun that clears the queue of tasks that were updated
  @tasks_queue = []
  @tasks_queue_is_dirty_rv = new ReactiveVar true
  @autorun =>
    if not self.tasks_queue_is_dirty_rv.get()
      return
    _.each self.tasks_queue, (task_id) ->
      self.triggerProjectsReactivityForTask task_id
    self.tasks_queue = []
    self.tasks_queue_is_dirty_rv.set false
    return
  
  @queuTaskForProjectsReactivityChecks = (task_id) ->
    self.tasks_queue.push task_id
    self.tasks_queue_is_dirty_rv.set true
    return
    
  # IMPORTANT: apparently, in meteor observers, one can't call Metero.defer or Meteor.settimeout etc.
  # However, getAllCollectionItemIdPaths does use one of these. Therefore, I created a queue of tasks
  # to deal with, and I trigger cleaning the queue with a dirty bit reactive var.
  @setObserver = ->
    self.stopObserver()
    if (justdo_id = JD.activeJustdo({_id: 1})._id)?
      cursor = JD.collections.Tasks.find
        project_id: justdo_id
      ,
        fields: APP.justdo_projects_dashboard.fields_of_interest_rv.get()
        
      self.observer = cursor.observeChanges
        added: (id, fields)->
          self.queuTaskForProjectsReactivityChecks id
          return
        changed: (id, fields)->
          self.queuTaskForProjectsReactivityChecks id
          return
        removed: (id)->
          self.queuTaskForProjectsReactivityChecks id
          return
    return
    
  @stopObserver = ->
    if self.observer?
      self.observer.stop()
      self.observer = null
    return
    
  # trigger observer reset on justdo change
  @autorun =>
    if (justdo_id = JD.activeJustdo({_id: 1})._id)?
      self.setObserver()
  
  # set the data to collect based on the needs of the main part and the table...
  @autorun =>
    main_part_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    table_part_inetest = APP.justdo_projects_dashboard.table_part_interest. get()
    
    APP.justdo_projects_dashboard.fields_of_interest_rv.set
      "#{main_part_interest}" : 1
      "#{table_part_inetest}" : 1
      
    
    field_options = {}
    if not (gc = APP.modules.project_page.mainGridControl())?
      return
    
    table_field_obj = gc.getSchemaExtendedWithCustomFields()[table_part_inetest]
    field_options[table_part_inetest] = table_field_obj
    main_field_obj = gc.getSchemaExtendedWithCustomFields()[main_part_interest]
    field_options[main_part_interest] = main_field_obj
    APP.justdo_projects_dashboard.field_ids_to_grid_values.set field_options
    return
  
  @main_part_data_rv = new ReactiveVar {}
  
  # collect the data for the main part
  @autorun =>
    # trigger and clear dirty bit
    
    if not APP.justdo_projects_dashboard.main_part_dirty_rv.get()
      return
    APP.justdo_projects_dashboard.main_part_dirty_rv.set false
    
    field_of_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values.get()[field_of_interest]?.grid_values)?
      return
    
    
    main_part_data =
      number_of_projects: 0
      total_tasks: 0
      projects_count_by_project_manager: {} # structure of <user_id>: <count>
      projects_field_of_interest: {}  # structure of <project_id>:
                                      #                 <field_option_id>: <count>
      field_options: field_options
      project_objs: {}                # structure of <project_id>: <project_doc?
    
    
    for project_id, tpl_instance of APP.justdo_projects_dashboard.project_id_to_template_instance
      tpl_collected_data = tpl_instance.collected_data_rv.get()
      main_part_data.number_of_projects += 1
      main_part_data.total_tasks += tpl_collected_data.tasks_count
      project_owner = tpl_instance.data.owner_id
      if not main_part_data.projects_count_by_project_manager[project_owner]?
        main_part_data.projects_count_by_project_manager[project_owner] = 0
      main_part_data.projects_count_by_project_manager[project_owner] += 1
      main_part_data.projects_field_of_interest[project_id] = tpl_collected_data.fields[field_of_interest]
      main_part_data.project_objs[project_id] = tpl_instance.data
      
    self.main_part_data_rv.set main_part_data
    return # end autorun collecting data
    
  # lastly - init the system with fields of interest
  APP.justdo_projects_dashboard.main_part_interest.set "BbJpRcsmTZuBALLhk"
  APP.justdo_projects_dashboard.table_part_interest.set "BbJpRcsmTZuBALLhk"
  return # end of onCreated

Template.justdo_projects_dashboard.onDestroyed ->
  @stopObserver()
  return

Template.justdo_projects_dashboard.onRendered ->
  @autorun =>
    
    field_of_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    grid_values =  APP.justdo_projects_dashboard.field_ids_to_grid_values.get()
    if not (field_options = grid_values[field_of_interest]?.grid_values)?
      return
    field_label = grid_values[field_of_interest].label
      
    main_part_data = Template.instance().main_part_data_rv.get()
    
    # chart 1 - the projects count by the field of interest
    field_type_count =
      undefined: 0
    for project_id, project_obj of main_part_data.project_objs
      if not (field_option_id = project_obj[field_of_interest])?
        field_type_count.undefined += 1
      else
        if not field_type_count[field_option_id]
          field_type_count[field_option_id] = 0
        field_type_count[field_option_id] += 1
    
    data = []
    for option_id, option of field_options
      title = option.txt
      count = field_type_count[option_id] or 0
      color = "##{option.bg_color}"
      if option_id == ""
        count = field_type_count.undefined
        title = "Unselected"
        color = "#ebead1"
      
      if count > 0
        data.push
          y: count
          name: title
          color: color
    
    chart =
      chart:
        type: 'pie'
        width: 350
        options3d:
          enabled: true
          alpha: 35
      title:
        text: "Projects by #{field_label}"
      plotOptions:
        pie:
          innerSize: 100
          depth: 45
        
      series: [
        name: ""
        animation: false
        dataLabels:
          distance: -20
        data: data
      ]
    Highcharts.chart "justdo-projects-dashboard-chart-1", chart
    chart.chart =
      type: 'column'
      width: 350
      options3d:
        enabled: true
        alpha: 15
        beta: 15
        viewDistance: 25
        depth: 40
      
    chart.options3d =
      enabled: true
      alpha: 15
      beta: 15
      viewDistance: 25
      depth: 40
    chart.plotOptions.column =
      stacking: 'normal'
      depth: 40
    chart.xAxis =
      labels:
        skew3d: true
        style:
          fontSize: '16px'
        
    Highcharts.chart "justdo-projects-dashboard-chart-2", chart
    chart.chart =
      type: 'bar'
      width: 350
      
      
    Highcharts.chart "justdo-projects-dashboard-chart-3", chart
    return # end of autorun
  return

Template.justdo_projects_dashboard.helpers
  
  numberOfProjects: ->
    return Template.instance().main_part_data_rv.get().number_of_projects
  totalNumberOfTasks: ->
    return Template.instance().main_part_data_rv.get().total_tasks
    
  activeProjects: ->
    query =
      "p:dp:is_project": true
      $or:  [
        "p:dp:is_archived_project": false
      ,
        "p:dp:is_archived_project":
          $exists: false
      ]
    return JD.collections.Tasks.find query
  
  tableFieldsOfInterestTitles: ->
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values.get()[APP.justdo_projects_dashboard.table_part_interest. get()]?.grid_values)?
      return []
    ret = []
    for option_id, option of field_options
      if option.txt? and option.txt != ""
        ret.push option.txt
    return ret


Template.justdo_projects_dashboard_project_line.onCreated ->
  # The @data here is the task(project) object
  self = @
  APP.justdo_projects_dashboard.project_id_to_template_instance[@data._id] = @
  
  @collected_data_rv = new ReactiveVar {}
  @is_dirty_rv = new ReactiveVar true
  
  @collectData = (grid_data, path, fields_of_interest) ->
    
    # in the collected data, the .fields is in the form of
    # .fields:
    #   <field_id>:
    #     <field_option_id>: <count>
    
    collected_data =
      tasks_count: 0
      fields: fields_of_interest
    
    grid_data.each path, (section, item_type, item_obj) ->
      collected_data.tasks_count += 1
      for field_id, field_data of collected_data.fields
        if not (field_value = item_obj[field_id])?
          field_data.undefined += 1
        else
          if not field_data[field_value]?
            field_data[field_value] = 0
          field_data[field_value] += 1
      return #and of each grid_data iterator
    self.collected_data_rv.set collected_data
    APP.justdo_projects_dashboard.main_part_dirty_rv.set true
    return
  
  @autorun =>
    # trigger reactivity and transform to our needs
    fields_of_interest = {}
    
    for field_id, field_data of APP.justdo_projects_dashboard.fields_of_interest_rv.get()
      fields_of_interest[field_id] =
        undefined: 0
        
    # for now we re-iterate on every refresh. todo: improve performance
    if (grid_data = APP.modules.project_page?.gridData())?
      if (path = grid_data.getCollectionItemIdPath(@data._id))?
        #trigger if marked so by the mother ship
        if not self.is_dirty_rv.get()
          return
        self.is_dirty_rv.set false
        self.collectData grid_data, path, fields_of_interest
    return # end of autorun
  return

Template.justdo_projects_dashboard_project_line.onDestroyed ->
  delete APP.justdo_projects_dashboard.project_id_to_template_instance[@data._id]
  APP.justdo_projects_dashboard.main_part_dirty_rv.set true
  return
  
Template.justdo_projects_dashboard_project_line.helpers
  ownerName: ->
    return JustdoHelpers.displayName(@owner_id)
  
  formatDate: (date)->
    return JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(date)
    
  numberOfSubtasks: ->
    if (count = Template.instance().collected_data_rv.get().tasks_count)?
      return count
    return ""
  
  columnsData: ->
    field_of_interest = APP.justdo_projects_dashboard.table_part_interest.get()
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values.get()[field_of_interest]?.grid_values)?
      return
    if not (collected_data_for_field = Template.instance().collected_data_rv.get().fields?[field_of_interest])?
      return
    ret = []
    for option_id, option of field_options
      if option.txt? and option.txt != ""
        if not (count = collected_data_for_field[option_id])?
          count = 0
        ret.push
          count: count
    return ret
    
    
    