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
    field_options[table_part_inetest] = table_field_obj.grid_values
  
    main_field_obj = gc.getSchemaExtendedWithCustomFields()[main_part_interest]
    field_options[main_part_interest] = main_field_obj.grid_values
  
    APP.justdo_projects_dashboard.field_ids_to_grid_values.set field_options
    return
  
  # lastly - init the system with fields of interest
  APP.justdo_projects_dashboard.main_part_interest.set "tzBEyvnXM8f8eiGGx"
  APP.justdo_projects_dashboard.table_part_interest.set "tzBEyvnXM8f8eiGGx"
  return # end of onCreated

Template.justdo_projects_dashboard.onDestroyed ->
  @stopObserver()
  return

Template.justdo_projects_dashboard.helpers
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
    field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values.get()[APP.justdo_projects_dashboard.table_part_interest. get()]
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
    field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values.get()[field_of_interest]
    collected_data_for_field = Template.instance().collected_data_rv.get().fields[field_of_interest]
    ret = []
    for option_id, option of field_options
      if option.txt? and option.txt != ""
        if not (count = collected_data_for_field[option_id])?
          count = 0
        ret.push
          count: count
    return ret
    
    
    