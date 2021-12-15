_.extend JustdoDbMigrations.prototype,
  registerTaskPaneSection: ->
    module = APP.modules.project_page

    # Register the new section manager
    JustdoDbMigrationsTaskPaneSection = (options) ->

      # This will be called as a JS constructor (with the `new` word) everytime the
      # task pane is Created by blaze, you can access the instance created under
      # XXX
      # Before we destroy the instance we will call @_destroy() - you can implement
      # such a method if you need one.
      module.TaskPaneSection.call @, options

      return @

    # Note that we register this section under the "JustdoDbMigrationsTaskPaneSection" id
    # which we use later
    module.registerTaskPaneSection "JustdoDbMigrationsTaskPaneSection", JustdoDbMigrationsTaskPaneSection

    # Inherit prototype common to all task pane sections
    # (at the moment it only include a @_destroy() method that does
    # nothing, so we can safely call @_destroy() even if you don't
    # need to implement one).
    Util.inherits JustdoDbMigrationsTaskPaneSection, module.TaskPaneSection

    # Each item in the grid can have different item type (examples: default, section
    # header, ticket queue header) here we add the section to the **default** item type
    # task pane tabs list.
    task_pane_sections =
      module.items_types_settings.default.task_pane_sections

    # Note that we change the array in-place, don't create a new array
    # use splice to put between two items
    section_definition =
      id: "justdo-db-migrations"
      type: "JustdoDbMigrationsTaskPaneSection" # the name of the template derives from the type
      options:
        title: JustdoDbMigrations.task_pane_tab_label
        titleInfo: -> "" # Can be a reactive resource, for number wrap with: <div class="task-pane-tab-title-info bg-primary text-white">0</div>
      section_options: {}

    justdo_db_migrations_section_position =
      lodash.findIndex task_pane_sections, (section) -> section.id == "item-activity"

    Tracker.autorun =>
      if APP.modules.project_page.curProj()?.isCustomFeatureEnabled(JustdoDbMigrations.project_custom_feature_id)
        if not _.any(task_pane_sections, (section) => section.id == "justdo-db-migrations")
          if justdo_db_migrations_section_position != -1
            # If the item-activity section exist, put the file manager after it
            task_pane_sections.splice(justdo_db_migrations_section_position + 1, 0, section_definition)
          else
            task_pane_sections.push section_definition

          APP.modules.project_page.invalidateItemsTypesSettings()

      else
        index = -1
        _.find task_pane_sections, (section, i) =>
          if section.id == "justdo-db-migrations"
            index = i
            return true

        if index != -1

          task_pane_sections.splice index, 1
          APP.modules.project_page.invalidateItemsTypesSettings()

    return
