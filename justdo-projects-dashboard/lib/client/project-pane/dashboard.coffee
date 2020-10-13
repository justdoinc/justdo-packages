Template.justdo_projects_dashboard.onCreated ->
  self = @

  @selected_project_owner_id_rv = new ReactiveVar null # null or owner id

  # the following is an autorun that clears the queue of tasks that were updated

  # set the data to collect based on the needs of the main part and the table...
  @autorun =>
    main_part_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    table_part_inetest = APP.justdo_projects_dashboard.table_part_interest.get()

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
    APP.justdo_projects_dashboard.main_part_dirty_rv.set true
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
      main_part_data.projects_field_of_interest[project_id] = tpl_collected_data.fields?[field_of_interest]
      main_part_data.project_objs[project_id] = tpl_instance.data

    self.main_part_data_rv.set main_part_data
    return # end autorun collecting data

  @activeProjectsList = (ignore_owners_part = false) ->
    query =
      "p:dp:is_project": true
      "project_id": JD.activeJustdo({_id: 1})._id
      $or:  [
        "p:dp:is_archived_project": false
      ,
        "p:dp:is_archived_project":
          $exists: false
      ]
    if not ignore_owners_part
      if (owner_id = self.selected_project_owner_id_rv.get())?
        query.owner_id = owner_id
    APP.justdo_projects_dashboard.main_part_dirty_rv.set true
    projects_list = []
    JD.collections.Tasks.find(query).forEach (project) ->
      projects_list.push project
      if (tpl = APP.justdo_projects_dashboard.project_id_to_template_instance[project._id])?
        tpl.data = project

    return projects_list

  # lastly - init and save the system with fields of interest
  @amiplify_base = "justdo-projects-dashboard-#{JD.activeJustdo({_id: 1})._id}"
  @autorun =>
    if APP.justdo_projects_dashboard.main_part_interest.get() == "" # i.e. we didn't init the interest yet
      return
    amplify.store "#{self.amiplify_base}-main", APP.justdo_projects_dashboard.main_part_interest.get()
    amplify.store "#{self.amiplify_base}-table", APP.justdo_projects_dashboard.table_part_interest.get()
    return # end autorun

  #reload on JustDo change
  @autorun =>
    JD.activeJustdo({_id: 1})
    if not (main_interest = amplify.store "#{self.amiplify_base}-main")?
      main_interest = "state"
    APP.justdo_projects_dashboard.main_part_interest.set main_interest

    if not (table_interest = amplify.store "#{self.amiplify_base}-table")?
      table_interest = "state"
    APP.justdo_projects_dashboard.table_part_interest.set table_interest
    self.main_part_data_rv.set {}
    return # end of autorun

  # Print Dashboard
  @printDashboard = ->
    $("body").append """<div class="print-dashboard-overlay"></div>"""
    $(".justdo-projects-dashboard").clone().appendTo(".print-dashboard-overlay")
    window.print()
    $(".print-dashboard-overlay").remove()
    return # end of Print Dashboard

  return # end of onCreated

Template.justdo_projects_dashboard.onRendered ->
  self = @
  @autorun =>
    main_part_data = self.main_part_data_rv.get()
    field_of_interest = APP.justdo_projects_dashboard.main_part_interest.get()
    grid_values =  APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()
    if not (field_options = grid_values[field_of_interest]?.grid_values)?
      return

    if $("#justdo-projects-dashboard-chart-1").length == 0
      return

    field_label = grid_values[field_of_interest].label

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
        if /^#/.test option.bg_color
          color = "#{option.bg_color}"
        else
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

      exporting:
        enabled: false

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
        title: if project_obj.title? and project_obj.title != "" then project_obj.title else "##{project_obj.seqId}"
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
          if /^#/.test option.bg_color
            series_obj.color = "#{option.bg_color}"
          else
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

      exporting:
        enabled: false

      legend:
        align: "left"
        verticalAlign: "bottom"
        floating: false
        y: 20

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
          if /^#/.test option.bg_color
            series_obj.color = "#{option.bg_color}"
          else
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

      exporting:
        enabled: false

      legend:
        enabled: false

      title:
        text: "project owners"

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
    return ret

  projectsOwnersList: ->
    projects = Template.instance().activeProjectsList(true)
    owners_set = new Set()
    owners_list = []
    for project in projects
      owner_id = project.owner_id
      if not owners_set.has owner_id
        owners_set.add owner_id
        owner = Meteor.users.findOne owner_id
        owners_list.push owner
    return owners_list
    # return _.sortBy owners_list, name

  numberOfProjects: ->
    return Template.instance().main_part_data_rv.get().number_of_projects

  isProjectsModuleEnabled: ->
    return true # In Jul 2nd 2020 projects became a built-in feature
    # if (curProj = APP.modules.project_page.curProj())?
    #   return curProj.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)
    # return false

  readyToDisplayCharts: ->
    return true # XXX this one had a purpose before, now no more, code remains commented out to help clean properly
    # # this one blocks until there are projects loaded and highcharts is ready and the projects module is installed
    # if Template.instance().activeProjectsList().length > 0
    #   if APP.justdo_highcharts._highchart_loaded_rv.get()
    #     if (curProj = APP.modules.project_page.curProj())?
    #       return curProj.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)
    # return false

  totalNumberOfTasks: ->
    return Template.instance().main_part_data_rv.get().total_tasks

  activeProjects: ->
    list = Template.instance().activeProjectsList()
    list = _.sortBy list, (project) -> project.title?.toUpperCase()
    return list

  tableFieldsOfInterestTitles: ->
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[APP.justdo_projects_dashboard.table_part_interest. get()]?.grid_values)?
      return []
    ret = []
    for option_id, option of field_options
      if option.txt? and option.txt != ""
        ret.push option.txt
    return ret

  columnWidthPercent: ->
    if not (field_options = APP.justdo_projects_dashboard.field_ids_to_grid_values_rv.get()[APP.justdo_projects_dashboard.table_part_interest. get()]?.grid_values)?
      return 0
    return (100 - 50)/ ((_.size field_options) - 1)


Template.justdo_projects_dashboard.events
  "click .justdo-projects-dashboard-owner-selector a": (e,tpl) ->
    e.preventDefault()
    user_object = Blaze.getData(e.target)
    if user_object?
      $(".justdo-projects-dashboard-owner-selector button").text(JustdoHelpers.displayName(user_object._id))
      tpl.selected_project_owner_id_rv.set user_object._id
    else
      $(".justdo-projects-dashboard-owner-selector button").text("All Members")
      tpl.selected_project_owner_id_rv.set null
    return

  "click .justdo-projects-dashboard-field-selector a": (e,tpl) ->
    # for now changing the main part interest will change also the table.
    # in the future we could control both independently
    e.preventDefault()
    APP.justdo_projects_dashboard.main_part_interest.set this.id
    APP.justdo_projects_dashboard.table_part_interest.set this.id
    return

Template.justdo_projects_dashboard_project_line.onCreated ->
  # The @data here is the task(project) object
  self = @
  APP.justdo_projects_dashboard.project_id_to_template_instance[@data._id] = @

  @collected_data_rv = new ReactiveVar {}
  @is_dirty_rv = new ReactiveVar true

  @autorun (computation) =>
    if not (gc = APP.modules.project_page.mainGridControl())?
      return
    if not (gd = gc._grid_data)?
      return
    
    gd._grid_data_core.invalidateOnCollectionItemDescendantsChanges @data._id,
      tracked_fields: [APP.justdo_projects_dashboard.table_part_interest.get()]
      
    @is_dirty_rv.set true

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
    if (grid_data = APP.modules.project_page.getGridControlMux()?.getMainGridControl(true)?._grid_data)?
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
  ownerDoc: ->
    Meteor.users.findOne(@owner_id)

  formatDate: (date)->
    return JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(date)

  barProgress: ->
    if not (subtasks = Template.instance().collected_data_rv.get().tasks_count)?
      return 0
    if subtasks == 0
      return 0
    return 100 * this.count / subtasks

  displayData: ->
    if this.count > 0
      return true
    return false

  numberOfSubtasks: ->
    if (subtasks = Template.instance().collected_data_rv.get().tasks_count)?
      return subtasks
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
        if not (color = option.bg_color)?
          color = "c3dafc"
        ret.push
          count: count
          bg_color: color

    return ret

  titleOrTaskSeqId: ->
    item = Template.instance().data
    if item.title? and item.title != ""
      return item.title
    else
      return "##{item.seqId}"

Template.justdo_projects_dashboard_project_line.events
  "click a": (e) ->
    e.preventDefault()
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateTabWithSectionsState "sub-tree", {global: {"root-item": this._id}}
    return
