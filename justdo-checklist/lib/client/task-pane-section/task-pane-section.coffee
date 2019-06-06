APP.justdo_highcharts.requireHighcharts()

Template.task_pane_justdo_checklist_task_pane_section_section.helpers
  isChecklist: ->
    if APP.modules.project_page.activeItemObj({"p:checklist:is_checklist":true})?['p:checklist:is_checklist']==true
      return true
    return false

  isHighchartsReady: -> APP.justdo_highcharts.isHighchartLoaded()

  showChart: -> Template.instance().show_chart_reactive_var.get()

Template.task_pane_justdo_checklist_task_pane_section_section.onCreated ->
  @show_chart_reactive_var = new ReactiveVar false
  return

Template.task_pane_justdo_checklist_task_pane_section_section.onRendered ->    
  @autorun =>
    path = APP.modules.project_page.gridControl().getCurrentPath()
    if not path?
      return
     # if non of the task in the path is a checklist, no need to mark anything
    checklist_task = APP.collections.Tasks.findOne
      _id:
        $in: path.split "/"
      "p:checklist:is_checklist" : true
          
    if not checklist_task?
      @show_chart_reactive_var.set false
    else
      @show_chart_reactive_var.set true

  @autorun (computation) =>
    active_item_id = APP.modules.project_page.activeItemId()

    if not active_item_id? or @show_chart_reactive_var.get() == false
      return

    categories = []
    checked =
      name: 'checked'
      data: []
      color: 'green'
    unchecked =
      name: 'unchecked'
      data: []
      color: 'lightgray'

    $("#checklist_chart_container").html ""

    subtasks_ids = []
    ret_data = {}
    APP.collections.Tasks.find
      "parents.#{active_item_id}":
        $exists: true
      ,
        fields:
          title: 1
          "p:checklist:is_checked": 1
          "p:checklist:total_count": 1
          "p:checklist:checked_count": 1
          "parents": 1
    .forEach (task) =>
      if task.title?
        categories.push task.title
      else
        categories.push ""
      subtasks_ids.push task._id

      ret_data[task._id] = 
        checked: 0
        unchecked: 0

    ancestor_cache = {}

    find_ancestor = (task_id) =>            
      if not ancestor_cache[task_id]?
        cursor = APP.collections.Tasks.find
          _id: task_id
          ,
            fields:
              "p:checklist:is_checked": 1
              "p:checklist:total_count": 1
              "p:checklist:checked_count": 1
              "parents": 1
            limit: 1
            reactive: false
        task = cursor.fetch()[0]
        if task._id in subtasks_ids
          ancestor = task._id
        else if (immediate_parent_id = Object.keys(task.parents)[0]) == "0" or immediate_parent_id == 0
          ancestor = 0
        else if not immediate_parent_id? # task.parents is a empty object bug
          Tracker.autorun =>
            task = APP.collections.Tasks.findOne
              _id: task_id
              ,
                fields:
                  parents: 1
            if Object.keys(task.parents).length != 0
              Tracker.currentComputation.stop()
              computation.invalidate()
          throw new Meteor.Error "task.parents is a empty object"
        else
          ancestor = find_ancestor(immediate_parent_id)
          if ancestor != 0
            cursor.reactive = true
            cursor._depend
              addedBefore: true
              removed: true
              changed: true
              movedBefore: true
            cursor.reactive = false
        
        ancestor_cache[task._id] = ancestor   
         
      return ancestor_cache[task_id]
    
    all_subtasks_ids = []

    try 
      APP.collections.Tasks.find
        project_id: APP.modules.project_page.curProj().id  
        ,
          reactive: false
      .forEach (task) => 
        if (ancestor = find_ancestor(task._id)) != 0
          all_subtasks_ids.push task._id
          if task["p:checklist:is_checked"] == true or task["p:checklist:total_count"]? and (task["p:checklist:total_count"] == task["p:checklist:checked_count"])
            ret_data[ancestor].checked++
          else
            ret_data[ancestor].unchecked++
    catch e
      if e.error == "task.parents is a empty object"
        return
      throw e

    for i, data of ret_data
      checked.data.push data.checked
      unchecked.data.push data.unchecked
    
    $("#checklist_chart_container").highcharts
      chart:
        type: 'bar'
        animation: false
      title:
        text: 'Checklist Status'
      xAxis:
        categories: categories
      yAxis:
        tickInterval: 1
      legend:
        reversed: true
      plotOptions:
        series:
          stacking: 'normal'
          animation: false
      series: [unchecked,checked]
    
    return

Template.task_pane_justdo_checklist_task_pane_section_section.events
  "click .checklist-on-off-switch": (e, tpl) ->
    Meteor.call "jdchToggleChecklistSwitch", APP.modules.project_page.activeItemObj()._id
