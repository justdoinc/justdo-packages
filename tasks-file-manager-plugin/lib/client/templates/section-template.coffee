getProjectPageModule = ->
  return APP.modules.project_page

Template.task_pane_tasks_file_manager_section.helpers
  exampleOfAccessingItemDetailsFromCustomHelper: ->
    module = getProjectPageModule()

    custom_details = {
      current_project_id: module.curProj()?.id
      active_item_path: module.activeItemPath()
      # Note: module.activeItemObjFromCollection gets as its first parameter the fields
      # you are interested in, to limit reactivity only to these fields
      active_item_obj: module.activeItemObjFromCollection({title: 1, priority: 1})
    }

    return custom_details

  itemsCount: -> APP.collections.Tasks.find().count()

  activeItemObj: (fields) ->
    if fields?
      proj = {}
      fields = fields.split(',')
      for field in fields
        proj[field] = 1
    obj = APP.modules.project_page.activeItemObj(proj)
    files_obj = APP.collections.TasksAugmentedFields.findOne({
      _id: obj._id
    }, {fields: {files: 1}})
    obj = _.extend obj, files_obj
    return obj