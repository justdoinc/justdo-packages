# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

# XXX IMPORTANT! there's a serious terminology confusion that one day should be fixed
# "sections" should be used for the registered templates "tabs" are for the
# current active available sections together with other meta-data (such as title)

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  #
  # tabs status
  #

  # active_tabs holds the current tabs available for the active grid item type
  active_tabs = module.current_task_pane_tabs = new ReactiveVar null, (a, b) -> a == b
  # Holds the id of the selected section
  selected_tab_id = module.current_task_pane_selected_tab_id = new ReactiveVar null

  #
  # Sections api
  #
  _.extend module,
    items_types_settings: {} # Stores the settings for items types check
                             # builtin-sections-to-item-types.coffee to learn more

    items_types_settings_dep: new Tracker.Dependency()

    invalidateItemsTypesSettings: ->
      @items_types_settings_dep.changed()

    #
    # Get sections for current active grid item type
    #
    getActiveGridItemType: ->
      # Returns the active grid item type, reactive to presented grid control changes
      # (mux) and active item changes
      #
      # Returns undefined if grid control not ready, no item selected
      #
      # "default" will be returned for items with no type
      # "fallback" will be returned if item type is not a registered type / no tabs were assigned to it

      # get current grid_control (reactive)
      if not (grid_control = module.gridControl())?
        # If there's no grid unset sections

        return

      # get current path (reactive)
      if not (current_path = grid_control.getCurrentPath())?
        # If there's grid but no item selected, unset sections

        return

      # find item type
      current_row = grid_control.getCurrentRowNonReactive()
      current_item_type = grid_control._grid_data.getItemType(current_row)

      if not current_item_type?
        if not JD.activeItemId()?
          # Sometimes, the grid internal data structure might be out-dated for few ticks, until the updates
          # from the minimongo observer are processed by it.
          # 
          # That means that if an item is removed, it might still be regarded by the grid data structure as existing, while
          # if plugins developers would try to access it from the minimongo it wouldn't be there - and execeptions
          # and bugs (and confusion) will follow.
          # 
          # JD.activeItemId() is looking in minimongo for the active item, and will return null if the active item
          # isn't there. In such cases, we don't want to load the "default" task pane to avoid plugins developers
          # to run into the issue described in the previous paragraph.
          return "fallback"

        current_item_type = "default"
      if not (current_item_type of module.items_types_settings)
        if current_item_type is "ticket-queue-caption"
          if JD.activeItemId()?
            # A ticket queue whose task item shared with the current user -> show normal task pane
            current_item_type = "default"
          else
            # A ticket queue whose task item isn't shared with the current user -> show fallback
            current_item_type = "fallback"
        else # An unknown current_item_type that we don't have special treatment for
          current_item_type = "fallback"

      return current_item_type

    #
    # Set the task pane item type for the task pane,
    # which we set and initiate the task pane tabs according to
    #
    setTaskPaneItemType: (item_type) ->
      # Get item type settings
      item_type_settings = module.items_types_settings[item_type]
      module.items_types_settings_dep.depend() # on changes to the module.item_types_settings, we want to load the correct tabs set

      task_pane_sections = item_type_settings.task_pane_sections

      # init tabs
      _tabs = []
      Tracker.nonreactive ->
        # Run in a nonreactive mode to avoid sections init procedures invalidating
        # the entire sections reactive var.
        for section_settings in task_pane_sections
          _tabs.push
            id: section_settings.id
            options: section_settings.options
            type: section_settings.type
            section_manager:
              new module.task_pane_sections_types[section_settings.type](section_settings.section_options)

      active_tabs.set _tabs


    #
    # Set the current section and get info about the current section
    #
    setCurrentTaskPaneSectionId: (section_id) ->
      selected_tab_id.set(section_id)

    getCurrentTaskPaneSectionId: ->
      # Reutrns the current section id if part of current toolbar sections
      if not (current_sections = active_tabs.get())? or current_sections.length == 0
        # No sections, nothing to check
        return null

      if (current_section_id = selected_tab_id.get())?
        # If we have current_section_id, try to find it in sections,
        # this is our current section if it's there
        for section in current_sections
          if section.id == current_section_id
            return current_section_id

      # If there's no set current_section_id, or if the current_section_id
      # is not part of sections, return the first of the current sections
      return current_sections[0].id

    getCurrentTaskPaneSectionObj: ->
      if not (current_section_id = @getCurrentTaskPaneSectionId())?
        return null

      # If getCurrentTaskPaneSectionId returned section_id, we know
      # for sure that sections contains it and is not empty
      for section in active_tabs.get()
        if section.id == current_section_id
          return section

    getCurrentTaskPaneSectionTemplate: ->
      if (current_section_obj = @getCurrentTaskPaneSectionObj())?
        return "task_pane_#{JustdoHelpers.camelCaseTo("_", current_section_obj.type)}_section" 

      return null

    #
    # Destroy procedures
    #
    destroyAndInitCurrentTaskPaneSections: ->
      Tracker.nonreactive ->
        if (current_sections = active_tabs.get())?
          for section_obj in current_sections
            section_obj.section_manager._destroy()

        active_tabs.set null

  #
  # task_pane_sections_types registrar
  #
  module.task_pane_sections_types = {}

  module.registerTaskPaneSection = (section_id, constructor) ->
    module.task_pane_sections_types[section_id] = constructor

  #
  # TaskPaneSection proto
  #
  TaskPaneSection = (options) ->
    return @

  module.TaskPaneSection = TaskPaneSection

  _.extend TaskPaneSection.prototype,
    #
    # _destroy
    #
    _destroy: ->
      # Called when it's time for the section manager to relase the
      # resources it is using
      return

    #
    # getNotificationsCount
    #
    getNotificationsCount: ->
      # Should be a reactive resource, returning the amount of notifications
      # pending in this section.
      # Will be used to signal the user attention is needed in the section.
