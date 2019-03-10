Template.checklist_grid_mark.helpers

  mark: ->
    task = APP.collections.Tasks.findOne({_id:this.task_id})

    if not task
      return '<i class="fa fa-question-circle slick-prevent-edit" aria-hidden="true"></i>'

    # if non of the task in the path is a checklist, no need to mark anything
    if not APP.collections.Tasks.findOne({_id: {$in:this.path.split('/')},'p:checklist:is_checklist':true})
      return ""

    # if checked
    else if task['p:checklist:is_checked']
      return '<i class="fa fa-check slick-prevent-edit" aria-hidden="true" style="color:green"></i>'

    # if implied as checked
    else if task['p:checklist:total_count'] and (task['p:checklist:total_count'] == task['p:checklist:checked_count'])
      return '<i class="fa fa-check-square slick-prevent-edit" aria-hidden="true" style="color:green"></i>'

    # if implied as partially checked
    else if (task['p:checklist:checked_count'] and task['p:checklist:checked_count'] > 0) or
             task['p:checklist:has_partial'] == true
      return '<i class="fa fa-check-square slick-prevent-edit" aria-hidden="true" style="color:silver"></i>'

    # else empty square
    else
      return '<i class="fa fa-square-o slick-prevent-edit" aria-hidden="true" ></i>'


    return ""


Template.checklist_grid_mark.events
  "click .p-jd-checklist": (e, tpl) ->
      Meteor.call "flipCheckItemSwitch", tpl.data.task_id
