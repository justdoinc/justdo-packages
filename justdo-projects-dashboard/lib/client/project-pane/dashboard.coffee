Template.justdo_projects_dashboard.onCreated ->
  self = @
  
  # one observer to trigger on all information that we care about
  @observer = null
  @selected_project_owner_id_rv = new ReactiveVar null # null or owner id
  
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
    APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.set field_options
    return
  
  @main_part_data_rv = new ReactiveVar {}
  
  # collect the data for the main part
  @autorun =>
    # trigger and clear dirty bit
    
    if not APP.justdo_projects_dashboard.main_part_dirty_rv.get()
      return
    APP.justdo_projects_dashboard.main_part_dirty_rv.set false
    
    field_of_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[field_of_interest]?.grid_values)?
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
    
  @activeProjectsList = (ignore_owners_part = false) ->
    query =
      "p:dp:is_project": true
      $or:  [
        "p:dp:is_archived_project": false
      ,
        "p:dp:is_archived_project":
          $exists: false
      ]
    if not ignore_owners_part
      if (owner_id = self.selected_project_owner_id_rv.get())?
        query.owner_id = owner_id
      
    return JD.collections.Tasks.find(query).fetch()
    
    
  # lastly - init and save the system with fields of interest
  @amiplify_base = "justdo-projects-dashboard-#{JD.activeJustdo({_id: 1})._id}"
  @autorun =>
    if APP.justdo_projects_dashboard.main_part_interest.get() == "" # i.e. we didn't init the interest yet
      return
    amplify.store "#{self.amiplify_base}-main", APP.justdo_projects_dashboard.main_part_interest.get()
    amplify.store "#{self.amiplify_base}-table", APP.justdo_projects_dashboard.table_part_interest.get()
    return # end autorun
  
  if not (main_interest = amplify.store "#{self.amiplify_base}-main")?
    main_interest = "state"
  APP.justdo_projects_dashboard.main_part_interest.set main_interest
  
  if not (table_interest = amplify.store "#{self.amiplify_base}-table")?
    table_interest = "state"
  APP.justdo_projects_dashboard.table_part_interest.set table_interest
  
  return # end of onCreated

Template.justdo_projects_dashboard.onDestroyed ->
  @stopObserver()
  return

Template.justdo_projects_dashboard.onRendered ->
  @autorun =>
    
    field_of_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    grid_values =  APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()
    if not (field_options = grid_values[field_of_interest]?.grid_values)?
      return
      
    field_label = grid_values[field_of_interest].label
    main_part_data = Template.instance().main_part_data_rv.get()
  
    common_charts_width = 300
    
    #######################################################
    # chart 1 - the projects count by the field of interest
    #######################################################
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
      color = null
      
      if option_id == ""
        count = field_type_count.undefined
        title = "(Unselected)"
        color = "#ebead1"
        
      if option_id == "nil" # there is inconsistency here - the state field has 'nil' and all others ""
        title = "(Unselected)"
        color = "#ebead1"
  
      if option.bg_color?
        color = "##{option.bg_color}"
  
      if count > 0
        series_obj =
          y: count
          name: title
        if color?
          series_obj.color = color
        data.push series_obj
    
    chart =
      chart:
        type: 'pie'
        width: common_charts_width
        options3d:
          enabled: true
          alpha: 35
      title:
        text: "Projects"
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
  
    #######################################################
    # chart 2 - per project breakdown of options
    #######################################################
    
    projects = {} # structure:  <project_id>:
                  #               <option_id>: <count>
    
    # generate a list of project ids sorted by project name
    projects_list = []
    for project_id, project_obj of main_part_data.project_objs
      projects_list.push
        id: project_id
        title: project_obj.title
    projects_list = _.sortBy projects_list, (item) -> item.title.toUpperCase()
    
    categories = []
    
    for item in projects_list
      projects[item.id] = {}
      categories.push item.title
      for option_id, option of field_options
        if not (count = main_part_data.projects_field_of_interest[item.id]?[option_id])?
          count = 0
        projects[item.id][option_id] = count
    
    series = []
    for option_id, option of field_options
      if option_id != ""
        data = []
        for item in projects_list
          data.push projects[item.id][option_id]
        
        series_obj =
          name: option.txt
          data: data
          animation: false
          
        if option.bg_color?
          series_obj.color = "##{option.bg_color}"
          
        series.push series_obj
        
    chart =
      chart:
        type: "column"
        width: common_charts_width
        options3d:
          enabled: true
          alpha: 15
          beta: 15
          viewDistance: 25
          depth: 40
        
      title:
        text: "#{field_label}"
        
      xAxis:
        categories: categories
        labels:
          skew3d: true
          style:
            fontSize: "16px"
    
      yAxis:
        allowDecimals: false
        min: 0
        reversedStacks: false
        title:
          enabled: false
          # text: ""
          # skew3d: true
      
      tooltip:
        headerFormat: "<b>{point.key}</b><br>"
        pointFormat: """<span style="color:{series.color}">\u25CF</span> {series.name}: {point.y} / {point.stackTotal}"""
        
      plotOptions:
        column:
          stacking: "normal"
          depth: 40
      
      series: series
     
    Highcharts.chart "justdo-projects-dashboard-chart-2", chart
  
    #######################################################
    # chart 3 - per project owner breakdown of options
    #######################################################
  
    owners = {} # structure:  <owner id>:
                #               <option_id>: <count>
    
    # generate a list of owner ids sorted by owner name
    owners_list = []
    owners_found = new Set()
    for project_id, project_obj of main_part_data.project_objs
      if owners_found.has project_obj.owner_id
        continue
      else
        owners_found.add project_obj.owner_id
        owners_list.push
          id: project_obj.owner_id
          name: JustdoHelpers.displayName(project_obj.owner_id)
    owners_list = _.sortBy owners_list, (owner) -> owner.name.toUpperCase()
    
    for project_id, project_obj of main_part_data.project_objs
      owner_id = project_obj.owner_id
      if not owners[owner_id]?
        owners[owner_id] = {}
      for option_id, option of field_options
        if not owners[owner_id][option_id]?
          owners[owner_id][option_id] = 0
        if not (count = main_part_data.projects_field_of_interest[project_id]?[option_id])?
          count = 0
        owners[owner_id][option_id] += count
      
    categories = []
    for owner in owners_list
      categories.push owner.name
      
    series = []
    for option_id, option of field_options
      if option_id != ""
        data = []
        for owner in owners_list
          data.push owners[owner.id][option_id]
        series_obj =
          name: option.txt
          data: data
          animation: false
        if option.bg_color?
          series_obj.color = "##{option.bg_color}"
        series.push series_obj
  
    chart =
      chart:
        type: "bar"
        width: common_charts_width
        options3d:
          enabled: true
          alpha: 15
          beta: 15
          viewDistance: 25
          depth: 40
    
      title:
        text: "owners"
    
      xAxis:
        categories: categories
        labels:
          skew3d: true
          style:
            fontSize: "16px"
    
      yAxis:
        allowDecimals: false
        min: 0
        reversedStacks: false
        title:
          enabled: false
    
      tooltip:
        headerFormat: "<b>{point.key}</b><br>"
        pointFormat: """<span style="color:{series.color}">\u25CF</span> {series.name}: {point.y} / {point.stackTotal}"""
    
      plotOptions:
        series:
          stacking: "normal"
          depth: 40
    
      series: series
      
    Highcharts.chart "justdo-projects-dashboard-chart-3", chart
    return # end of autorun
  return

Template.justdo_projects_dashboard.helpers

  selectedFieldLabel: ->
    main_part_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[main_part_interest]
    if (ret = field_options?.label)?
      return ret
    return ""
    
  gridOptionFields: ->
    if not (gc = APP.modules.project_page.mainGridControl())?
      return []
    ret = []
    for field_id, field_options of gc.getSchemaExtendedWithCustomFields()
      if field_options.grid_column_formatter == "keyValueFormatter"
        ret.push
          id: field_id
          options: field_options
    console.log ret
    return ret
  
  projectsOwnersList: ->
    projects = Template.instance().activeProjectsList(true)
    owners_set = new Set()
    owners_list = []
    for project in projects
      owner_id = project.owner_id
      if not owners_set.has owner_id
        owners_set.add owner_id
        owners_list.push
          id: owner_id
          name: JustdoHelpers.displayName(owner_id)
    return _.sortBy owners_list, name

  numberOfProjects: ->
    return Template.instance().main_part_data_rv.get().number_of_projects

  totalNumberOfTasks: ->
    return Template.instance().main_part_data_rv.get().total_tasks
    
  activeProjects: ->
    list = Template.instance().activeProjectsList()
    list = _.sortBy list, (project) -> project.title.toUpperCase()
    return list
  
  tableFieldsOfInterestTitles: ->
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[APP.justdo_projects_dashboard.table_part_interest. get()]?.grid_values)?
      return []
    ret = []
    for option_id, option of field_options
      if option.txt? and option.txt != ""
        ret.push option.txt
    return ret

Template.justdo_projects_dashboard.events
  "click .justdo-projects-dashboard-owner-selector a": (e,tpl) ->
    if this.name?
      $(".justdo-projects-dashboard-owner-selector button").text(this.name)
      tpl.selected_project_owner_id_rv.set this.id
    else
      $(".justdo-projects-dashboard-owner-selector button").text("All Managers")
      tpl.selected_project_owner_id_rv.set null
    return
  
  "click .justdo-projects-dashboard-field-selector a": (e,tpl) ->
    # for now changing the main part interest will change also the table.
    # in the future we could control both independently
    APP.justdo_projects_dashboard.main_part_interest.set this.id
    APP.justdo_projects_dashboard.table_part_interest.set this.id
    return

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
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[field_of_interest]?.grid_values)?
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
    
    
    