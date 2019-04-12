_ = lodash

_.extend TasksFileManagerPlugin.prototype,
  registerTaskPaneSection: ->
    module = APP.modules.project_page

    # Add our common template helpers to your template
    Template.task_pane_tasks_file_manager_section.helpers module.template_helpers

    # Register the new section manager
    TasksFileManager = (options) ->

      # This will be called as a JS constructor (with the `new` word) everytime the
      # task pane is Created by blaze, you can access the instance created under
      # XXX
      # Before we destroy the instance we will call @_destroy() - you can implement
      # such a method if you need one.
      module.TaskPaneSection.call @, options

      return @

    # Note that we register this section under the "TasksFileManager" id
    # which we use later
    module.registerTaskPaneSection "TasksFileManager", TasksFileManager

    # Inherit prototype common to all task pane sections
    # (at the moment it only include a @_destroy() method that does
    # nothing, so we can safely call @_destroy() even if you don't
    # need to implement one).
    Util.inherits TasksFileManager, module.TaskPaneSection

    # Each item in the grid can have different item type (examples: default, section
    # header, ticket queue header) here we add the section to the **default** item type
    # task pane tabs list.
    task_pane_sections =
      module.items_types_settings.default.task_pane_sections

    # Note that we change the array in-place, don't create a new array
    # use splice to put between two items
    section_definition = 
      id: "tasks-file-manager"
      type: "TasksFileManager" # the name of the template derives from the type
      options:
        title: "Files"
        titleInfo: ->
          if not (active_item_obj = module.activeItemObj({"files.id": 1}))?
            return ""

          if not (files = active_item_obj.files) or files.length <= 0
            return ""
          
          return "(#{parseInt(files.length, 10)})"
      section_options: {}

    tasks_file_manager_section_position =
      _.findIndex task_pane_sections, (section) -> section.id == "item-activity"

    if tasks_file_manager_section_position != -1
      # If the item-activity section exist, put the file manager after it
      task_pane_sections.splice(tasks_file_manager_section_position + 1, 0, section_definition)
    else
      task_pane_sections.push section_definition

    return