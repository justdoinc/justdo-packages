_.extend JustdoFiles.prototype,
  registerTaskPaneSection: ->
    module = APP.modules.project_page

    # Register the new section manager
    JustdoFilesTaskPaneSection = (options) ->

      # This will be called as a JS constructor (with the `new` word) everytime the
      # task pane is Created by blaze, you can access the instance created under
      # XXX
      # Before we destroy the instance we will call @_destroy() - you can implement
      # such a method if you need one.
      module.TaskPaneSection.call @, options

      return @

    # Note that we register this section under the "JustdoFilesTaskPaneSection" id
    # which we use later
    module.registerTaskPaneSection "JustdoFilesTaskPaneSection", JustdoFilesTaskPaneSection

    # Inherit prototype common to all task pane sections
    # (at the moment it only include a @_destroy() method that does
    # nothing, so we can safely call @_destroy() even if you don't
    # need to implement one).
    Util.inherits JustdoFilesTaskPaneSection, module.TaskPaneSection

    # Each item in the grid can have different item type (examples: default, section
    # header, ticket queue header) here we add the section to the **default** item type
    # task pane tabs list.
    task_pane_sections =
      module.items_types_settings.default.task_pane_sections

    # Note that we change the array in-place, don't create a new array
    # use splice to put between two items
    section_definition =
      id: "justdo-files"
      type: "JustdoFilesTaskPaneSection" # the name of the template derives from the type
      options:
        title: "Files"
        titleInfo: ->
          if not (active_item_obj = module.activeItemObj({"#{JustdoFiles.files_count_task_doc_field_id}": 1}))?
            return ""

          if not (files_count = active_item_obj[JustdoFiles.files_count_task_doc_field_id]) or files_count <= 0
            return ""
          
          return "(#{parseInt(files_count, 10)})"
      section_options: {}

    justdo_files_section_position =
      lodash.findIndex task_pane_sections, (section) -> section.id == "item-activity"

    if not _.any(task_pane_sections, (section) => section.id == "justdo-files")
      if justdo_files_section_position != -1
        # If the item-activity section exist, put the file manager after it
        task_pane_sections.splice(justdo_files_section_position + 1, 0, section_definition)
      else
        task_pane_sections.push section_definition

    return
