_.extend JustdoCalendarView.prototype,
  registerTaskPaneSection: ->
    module = APP.modules.project_page

    # Register the new section manager
    JustdoCalendarViewTaskPaneSection = (options) ->

      # This will be called as a JS constructor (with the `new` word) everytime the
      # task pane is Created by blaze, you can access the instance created under
      # XXX
      # Before we destroy the instance we will call @_destroy() - you can implement
      # such a method if you need one.
      module.TaskPaneSection.call @, options

      return @

    # Note that we register this section under the "JustdoCalendarViewTaskPaneSection" id
    # which we use later
    module.registerTaskPaneSection "JustdoCalendarViewTaskPaneSection", JustdoCalendarViewTaskPaneSection

    # Inherit prototype common to all task pane sections
    # (at the moment it only include a @_destroy() method that does
    # nothing, so we can safely call @_destroy() even if you don't
    # need to implement one).
    Util.inherits JustdoCalendarViewTaskPaneSection, module.TaskPaneSection

    # Each item in the grid can have different item type (examples: default, section
    # header, ticket queue header) here we add the section to the **default** item type
    # task pane tabs list.
    task_pane_sections =
      module.items_types_settings.default.task_pane_sections

    # Note that we change the array in-place, don't create a new array
    # use splice to put between two items
    section_definition =
      id: "justdo-calendar-view"
      type: "JustdoCalendarViewTaskPaneSection" # the name of the template derives from the type
      options:
        title: "TAB NAME"
        titleInfo: -> "(0)" # Can be a reactive resource
      section_options: {}

    justdo_calendar_view_section_position =
      lodash.findIndex task_pane_sections, (section) -> section.id == "item-activity"

    Tracker.autorun =>
      if APP.modules.project_page.curProj()?.isCustomFeatureEnabled(JustdoCalendarView.project_custom_feature_id)
        if not _.any(task_pane_sections, (section) => section.id == "justdo-calendar-view")
          if justdo_calendar_view_section_position != -1
            # If the item-activity section exist, put the file manager after it
            task_pane_sections.splice(justdo_calendar_view_section_position + 1, 0, section_definition)
          else
            task_pane_sections.push section_definition

          APP.modules.project_page.invalidateItemsTypesSettings()

      else
        index = -1
        _.find task_pane_sections, (section, i) =>
          if section.id == "justdo-calendar-view"
            index = i
            return true

        if index != -1

          task_pane_sections.splice index, 1
          APP.modules.project_page.invalidateItemsTypesSettings()

    return
