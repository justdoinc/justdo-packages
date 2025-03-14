_.extend MeetingsManagerPlugin.prototype,
  registerTaskPaneSection: ->
    self = @
    project_page_module = APP.modules.project_page

    # Add our common template helpers to your template
    Template.task_pane_meetings_manager_section.helpers project_page_module.template_helpers

    # Register the new section manager
    MeetingsManager = (options) ->

      # This will be called as a JS constructor (with the `new` word) everytime the
      # task pane is Created by blaze, you can access the instance created under
      # XXX
      # Before we destroy the instance we will call @_destroy() - you can implement
      # such a method if you need one.
      project_page_module.TaskPaneSection.call @, options

      return @

    # Note that we register this section under the "MeetingsManager" id
    # which we use later
    project_page_module.registerTaskPaneSection "MeetingsManager", MeetingsManager

    # Inherit prototype common to all task pane sections
    # (at the moment it only include a @_destroy() method that does
    # nothing, so we can safely call @_destroy() even if you don't
    # need to implement one).
    Util.inherits MeetingsManager, project_page_module.TaskPaneSection

    # Each item in the grid can have different item type (examples: default, section
    # header, ticket queue header) here we add the section to the **default** item type
    # task pane tabs list.
    task_pane_sections =
      project_page_module.items_types_settings.default.task_pane_sections

    # Note that we change the array in-place, don't create a new array
    # use splice to put between two items
    section_definition =
      id: "meetings-manager"
      type: "MeetingsManager" # the name of the template derives from the type
      options:
        title: "Meetings"
        titleInfo: ->
          task_id = JD.activeItemId()

          if not task_id?
            return

          if not (task = APP.collections.Tasks.findOne task_id, {fields: {[MeetingsManagerPlugin.task_meetings_cache_field_id]: 1}})?
            return
            
          meeting_ids = new Set(task[MeetingsManagerPlugin.task_meetings_cache_field_id])

          if task.created_from_meeting_id?
            meeting_created = self.meetings_manager.meetings.findOne(task.created_from_meeting_id, {fields: {_id: 1}})
            if meeting_created?
              meeting_ids.add meeting_created._id          

          if meeting_ids.size > 0
            return """<div class="task-pane-tab-title-info bg-primary text-white">#{meeting_ids.size}</div>"""

          return ""
          
      section_options: {}

    meetings_manager_section_position =
      lodash.findIndex task_pane_sections, (section) -> section.id == "item-activity"

    Tracker.autorun =>
      enabled = APP.modules.project_page.curProj()?.isCustomFeatureEnabled("meetings_module")

      if enabled
        # if not self.meetings_for_task_comp?
        #   Tracker.nonreactive =>
        #     self.meetings_for_task_comp = Tracker.autorun =>
        #       task_id = JD.activeItemId()
        #       self.meetings_manager.subscribeToMeetingsForTask task_id
        #       return

        #     return

        if not _.any(task_pane_sections, (section) => section.id == "meetings-manager")
          if meetings_manager_section_position != -1
            # If the item-activity section exist, put the file manager after it
            task_pane_sections.splice(meetings_manager_section_position + 1, 0, section_definition)
          else
            task_pane_sections.push section_definition

          APP.modules.project_page.invalidateItemsTypesSettings()

      else
        # if self.meetings_for_task_comp?
        #   self.meetings_for_task_comp.stop()
        #   self.meetings_for_task_comp = null
        index = -1
        _.find task_pane_sections, (section, i) =>
          if section.id == "meetings-manager"
            index = i
            return true

        if index != -1

          task_pane_sections.splice index, 1
          APP.modules.project_page.invalidateItemsTypesSettings()


      # XXX daniel how to make this reactive

    return
