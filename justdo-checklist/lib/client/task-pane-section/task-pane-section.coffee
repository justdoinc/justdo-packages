APP.justdo_highcharts.requireHighcharts()

countCheckedLeafes = (task)->
  ret =
    count: 1
    checked: 0
  if task['p:checklist:is_checked'] == true or
      task['p:checklist:total_count'] and (task['p:checklist:total_count'] == task['p:checklist:checked_count'])
    ret.checked = 1
  APP.collections.Tasks.find({"parents.#{task._id}":{$exists:true}}).forEach (doc)=>
    subTasks = countCheckedLeafes(doc)
    ret.count += subTasks.count
    ret.checked += subTasks.checked

  return ret


renderChart = (active_item)->
  # if non of the task in the path is a checklist, no need to mark anything
  path = APP.modules.project_page.gridControl().getCurrentPath()
  if not APP.collections.Tasks.findOne({_id: {$in:path.split('/')},'p:checklist:is_checklist':true})
    $('#checklist_chart_container').hide()
    return
  $('#checklist_chart_container').show()

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

  APP.collections.Tasks.find({"parents.#{active_item._id}":{$exists:true}}).forEach (doc)=>
    ret = countCheckedLeafes(doc)

    if doc.title
      categories.push doc.title
    else
      categories.push ""

    checked.data.push ret.checked
    unchecked.data.push ret.count-ret.checked

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

Template.task_pane_justdo_checklist_task_pane_section_section.helpers
  isChecklist: ->
    if APP.modules.project_page.activeItemObj({"p:checklist:is_checklist":true})['p:checklist:is_checklist']==true
      return true
    return false

  isHighchartsReady: -> APP.justdo_highcharts.isHighchartLoaded()

Template.task_pane_justdo_checklist_task_pane_section_section.onCreated ->

  return

Template.task_pane_justdo_checklist_task_pane_section_section.onRendered ->
  @autorun =>
    renderChart(APP.modules.project_page.activeItemObj())





Template.task_pane_justdo_checklist_task_pane_section_section.events
  "click .checklist-on-off-switch": (e, tpl) ->
    Meteor.call "jdchToggleChecklistSwitch", APP.modules.project_page.activeItemObj()._id
