# here we will hold a list of fields that we want to collect data of
fields_of_interest_rv = new ReactiveVar
  state: 1

project_id_to_template_instance = {}

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
      if not (paths)?
        if not (paths = gd.getAllCollectionItemIdPaths(task_id))?
          # we shouldn't get here
          return
      
      for path in paths
        for parent_id in path.split("/")
          if (template_instance = project_id_to_template_instance[parent_id])?
            template_instance.is_dirty_rv.set true
      return # end of settimeout
    ,
      500
    return

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
        fields: fields_of_interest_rv.get()
        
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

Template.justdo_projects_dashboard_project_line.onCreated ->
  # The @data here is the task(project) object
  self = @
  project_id_to_template_instance[@data._id] = @
  
  @collected_data_rv = new ReactiveVar {}
  @is_dirty_rv = new ReactiveVar true
  
  @autorun =>
    # trigger reactivity and transform to our needs
    fields_of_interest = {}
    _.each fields_of_interest_rv.get(), (field_id) ->
      fields_of_interest[field_id] = {}
    
    # for now we re-iterate on every refresh. todo: improve performance
    if (grid_data = APP.modules.project_page?.gridData())?
      if (path = grid_data.getCollectionItemIdPath(@data._id))?
        #trigger if marked so by the mother ship
        if not self.is_dirty_rv.get()
          return
        self.is_dirty_rv.set false
        
        collected_data =
          tasks_count: 0
          fields: fields_of_interest
        
        grid_data.each path, (section, item_type, item_obj) ->
          collected_data.tasks_count += 1
          # todo next - collect fields data
          return #and of each grid_data iterator
        
        self.collected_data_rv.set collected_data
    
    return # end of autorun
  return

Template.justdo_projects_dashboard_project_line.onDestroyed ->
  delete project_id_to_template_instance[@data._id]
  
Template.justdo_projects_dashboard_project_line.helpers
  ownerName: ->
    return JustdoHelpers.displayName(@owner_id)
  
  formatDate: (date)->
    return JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(date)
    
  numberOfSubtasks: ->
    if (count = Template.instance().collected_data_rv.get().tasks_count)?
      return count
    return ""