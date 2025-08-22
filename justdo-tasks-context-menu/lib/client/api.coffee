itemsSource = (section_id="default", ignore_listing_condition) ->
  if @itemsGenerator?
    return @itemsGenerator()
  return @reactive_items_list.getList(section_id, ignore_listing_condition)

_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  _immediateInit: ->
    @is_visible = new ReactiveVar(false)

    @_context_item_id_reactive_var = new ReactiveVar(null)
    @_context_item_path_reactive_var = new ReactiveVar(null)
    @_context_field_info_reactive_var = new ReactiveVar(null)

    @_context_field_val_reactive_var = new ReactiveVar(null)
    @_context_dependencies_field_val_reactive_var = new ReactiveVar(null)

    # Track which grid control opened the current context menu
    @_gc_with_opened_context_menu_rv = new ReactiveVar(null)

    # Track all grid control instances that should support context menu
    @_registered_grid_controls = new Set()
    
    # Register the main grid control
    @_register_main_grid_control_tracker = null
    @_registerMainGridControl()

    @sections_reactive_items_list = new JustdoHelpers.ReactiveItemsList() # The "main" domain will be used for the main sections

    @field_val_and_dependencies_vals_tracker = Tracker.autorun =>
      @updateFieldValAndDependenciesReactiveVars()

      return

    @onDestroy =>
      @field_val_and_dependencies_vals_tracker.stop()
      @_register_main_grid_control_tracker.stop()
      return

    @_sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator = (item) =>
      return [
        @_context_item_id_reactive_var.get(),
        @_context_item_path_reactive_var.get(),
        @_context_field_val_reactive_var.get(),
        @_context_dependencies_field_val_reactive_var.get(),
        @_context_field_info_reactive_var.get(),
        @getGridControlWithOpenedContextMenu()
      ]

    @sections_reactive_items_list.registerListingConditionCustomArgsGenerator @_sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator

    @setupCoreMenuSections()

    @_setupHandlers()

    return

  _deferredInit: ->
    if @destroyed
      return

    @context_menu_template_obj =
      JustdoHelpers.renderTemplateInNewNode("tasks_context_menu", {controller: @}, "div")

    $(@context_menu_template_obj.node).addClass("dropdown #{@context_class}")

    @_setupContextMenuEvent()

    @_setupHideConditions()

    return
  
  _setupHandlers: ->
    APP.on "additional-grid-control-created", (grid_control) =>
      @registerGridControl(grid_control)
      return

    # Permission check for bulk update
    @register "pre-bulk-update", (task_ids, field_id, field_val, modifier) ->
      if not (res = APP.justdo_permissions.checkTaskPermissions "task-field-edit.#{field_id}", task_ids)
        JustdoSnackbar.show
          text: "You don't have the necessary permission to perform this action"
      return res
    return

  sectionsItemsSource: (section_id, nested_section_item, ignore_listing_condition) ->
    if not (nested_section_def = _.find this.getMainSections(ignore_listing_condition), (section_def) -> section_def.id == section_id)?
      console.info "Couldn't identify nested_section_def"
      return

    nested_section_items = nested_section_def.itemsSource("default", ignore_listing_condition)

    nested_section_item_def = _.find nested_section_items, (section_def) -> section_def.id == nested_section_item

    if (itemsGenerator = nested_section_item_def?.itemsGenerator)?
      return itemsGenerator()
    else
      return @sections_reactive_items_list.getList(@_getNestedSectionsDomainId(section_id, nested_section_item), ignore_listing_condition)

  updateFieldValAndDependenciesReactiveVars: ->
    if not (field_info = @_context_field_info_reactive_var.get())? or not (task_id = @_context_item_id_reactive_var.get())?
      return

    # For reactivity
    @getGridControlWithOpenedContextMenu()

    field_name = field_info.field_name
    tasks_query_projection = {"#{field_name}": 1}
    if (dependencies_fields = field_info.column_field_schema.grid_dependencies_fields)?
      for dependcy_field in dependencies_fields
        tasks_query_projection[dependcy_field] = 1

    if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: tasks_query_projection}))?
      return

    @_context_field_val_reactive_var.set task_doc[field_name]
    delete task_doc[field_name]
    delete task_doc._id
    @_context_dependencies_field_val_reactive_var.set task_doc

    return

  _setupContextMenuEvent: ->
    $("body").on "contextmenu", ".slick-viewport", (e) =>
      if $(e.target).closest(".editable").length > 0
        # While in edit mode, don't hijack the right click
        return

      # Find which grid control this event belongs to by traversing up the DOM
      gc = @_findGridControlFromEvent(e)

      if not (event_item = gc.getEventItem(e))?
        # Can't find event's item
        return

      if not (event_path = gc.getEventPath(e))?
        # Can't find event's path
        return

      if not (field_info = gc.getEventFormatterDetails(e))?
        # Can't find event's field info
        return

      if event_item._type?
        # We don't show context menu for typed items
        return

      if $(e.target).closest("a").length > 0
        # Don't hijack contextmenu if links are clicked
        return

      e.preventDefault()

      @setGridControlWithOpenedContextMenu gc
      @_context_item_id_reactive_var.set event_item._id
      @_context_item_path_reactive_var.set event_path
      @_context_field_info_reactive_var.set field_info

      @updateFieldValAndDependenciesReactiveVars()

      gc.activateRow(gc.getEventRow(e), 0, false) # false is to avoid scroll into view that will cause the viewport to horizontally jump to the grid's left

      Tracker.flush()

      @_show({of: e})

      @clearAndFocusFirstSectionFilterInMostNestedMenu()

      return

    return

  _setupHideConditions: ->
    # Don't close when clicking inside the context
    $(".#{@context_class}").on "mouseup", (e) ->
      e.stopPropagation()
      
      return

    # Close when an action is clicked
    $(".#{@context_class}").on "click", ".context-action-item", (e) =>
      @hide()

      return

    # Close when the user clicks on esc
    $("body").on "keyup", (e) =>
      if e.which == 27
        @hide()

      return

    $("body").on "mouseup", (e) =>
      if e.which == 1 # 1 == left mouse click
        @hide()

      return

    # Hide the context menu, if the active grid control changes (can happen upon views changes,
    # for example when the browser's back button is pressed, which doesn't trigger the mouse
    # down event), or, if it the active grid gets destroyed (Examples: 1) user is removed from the project,
    # 2) back button brings back to the projects page, etc.)
    prev_grid_uid = null
    Tracker.autorun =>
      # If the active grid control changes or destroy, hide the context menu
      if not (context_gc = @getGridControlWithOpenedContextMenu())?
        @hide()
        return

      grid_uid = context_gc.getGridUid()

      if not prev_grid_uid?
        prev_grid_uid = grid_uid
      
      if prev_grid_uid isnt grid_uid
        @hide()
      
      prev_grid_uid = grid_uid

      return

    Tracker.autorun =>
      # If the active item changes from the item that initiated the opening of the context menu,
      # close the context menu. Only check this for the main grid control to maintain backward compatibility
      context_gc = @getGridControlWithOpenedContextMenu()
      
      if context_gc?.activeItemId() isnt @_context_item_id_reactive_var.get()
          @hide()

      return

    # Hide if the context item id isn't exists (example if it gets removed by another user).
    Tracker.autorun =>
      if (active_item_id = @_context_item_id_reactive_var.get())?
        if not APP.collections.Tasks.findOne(active_item_id, {fields: {_id: 1}})?
          @hide()

      return

    # Hide on grid_control scroll (following gmail behavior)
    Tracker.autorun =>
      context_gc = @getGridControlWithOpenedContextMenu()

      if not context_gc?
        return

      if context_gc._hide_context_on_scroll_initiated
        return
      context_gc._hide_context_on_scroll_initiated = true

      context_gc.container.find(".slick-viewport").on "scroll", => @hide()

      return

    return

  $getNode: ->
    return $(@context_menu_template_obj.node)

  isVisible: ->
    return @is_visible.get()

  _show: (jquery_ui_position_obj) ->
    @is_visible.set(true)

    Tracker.flush()

    if not jquery_ui_position_obj? or not _.isObject(jquery_ui_position_obj)
      jquery_ui_position_obj = {}

    default_jquery_ui_position_obj =
      my: "#{APP.justdo_i18n.getRtlAwareDirection "left"} top"
      at: "#{APP.justdo_i18n.getRtlAwareDirection "left"} bottom"
      of: "body"
      collision: "flipfit"

    jquery_ui_position_obj =
      _.extend default_jquery_ui_position_obj, jquery_ui_position_obj

    @$getNode()
      .addClass("show")
      .find(".dropdown-menu")
      .addClass("show")
      .find(".show-fix").removeClass "show-fix" # "Show-fix" class is coming from tasks_context_menu and help to avoid to close dropdown submenu on mouseleave

    @$getNode().position(jquery_ui_position_obj)

    return

  hide: ->
    is_visible = Tracker.nonreactive => @is_visible.get()

    if not is_visible
      return

    @is_visible.set(false)

    @$getNode().removeClass("show").find(".dropdown-menu").removeClass("show")

    return

  getContextItemId: -> @_context_item_id_reactive_var.get()

  getContextItemObj: (fields) ->
    if (context_item_id = @getContextItemId())?
      # Get the collection from the context grid control, fallback to global Tasks collection
      context_gc = @getGridControlWithOpenedContextMenu()
      collection = context_gc?.collection or APP.collections.Tasks
      
      collection.findOne(context_item_id, {fields})
    else
      return undefined

  _registerSection_conf_scehma: new SimpleSchema
    position: 
      type: Number
    data:
      optional: true
      type: new SimpleSchema
        label:
          type: String
          optional: true
        label_i18n:
          type: String
          optional: true
        hide_border:
          type: Boolean
          optional: true
        display_item_filter_ui:
          type: Boolean
          optional: true
        display_item_filter_ui_placeholder:
          type: String
          optional: true
          defaultValue: ""
        itemsGenerator:
          optional: true
          type: Function
        limit_rendered_items:
          type: Boolean
          optional: true
          defaultValue: false
        limit_rendered_items_initial_items:
          type: Number
          optional: true
          defaultValue: 40
        limit_rendered_items_load_more_items:
          type: Number
          optional: true
          defaultValue: 40
    listingCondition:
      optional: true
      type: Function

  _registerSection: (section_id, domain, conf) ->
    if not conf?
      conf = {}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerSection_conf_scehma,
        conf or {},
        {self: @, throw_on_error: true}
      )
    conf = cleaned_val

    Meteor._ensure conf, "data"

    # Create shallow copy to avoid affecting the original conf obj provided
    conf = _.extend {}, conf,
      domain: domain

    # Create shallow copy to avoid affecting the original data obj provided

    section_items_reactive_items_list = new JustdoHelpers.ReactiveItemsList()
    section_items_reactive_items_list.registerListingConditionCustomArgsGenerator @_sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator

    conf.data = _.extend {}, conf.data,
      reactive_items_list: section_items_reactive_items_list

      itemsSource: itemsSource

    if conf.data.display_item_filter_ui
      conf.data = _.extend {}, conf.data,
        filter_state_rv: new ReactiveVar("")

    @sections_reactive_items_list.registerItem section_id, conf

    return

  registerMainSection: (section_id, conf) -> @_registerSection(section_id, "main", conf)

  unregisterMainSection: (section_id) -> 
    @sections_reactive_items_list.unregisterItem section_id
    return

  getMainSections: (ignore_listing_condition) -> 
    return @sections_reactive_items_list.getList("main", ignore_listing_condition)

  _registerSectionItem_conf_scehma: new SimpleSchema
    position: 
      type: Number
    data:
      optional: true
      type: new SimpleSchema
        label:
          type: "skip-type-check"
        label_i18n:
          type: "skip-type-check"
          optional: true
        label_addendum_template:
          type: String
          optional: true
        op: 
          optional: true
          type: Function
        is_nested_section:
          optional: true
          type: Boolean
        bg_color:
          optional: true
          type: String
        icon_type:
          optional: true
          type: String
          allowedValues: ["none", "feather", "user-avatar"] # ["font-awesome"] might support these two in the future as well.
          defaultValue: "none"
        icon_val:
          optional: true
          type: "skip-type-check"
        icon_class:
          optional: true
          type: "skip-type-check"
        close_on_click:
          optional: true
          type: Boolean
          defaultValue: true
        itemsGenerator:
          optional: true
          type: Function

    listingCondition:
      optional: true
      type: Function
  registerSectionItem: (section_id, item_id, conf) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerSectionItem_conf_scehma,
        conf or {},
        {self: @, throw_on_error: true}
      )
    conf = cleaned_val

    if (sections_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true)?.data?.reactive_items_list)?
      sections_reactive_items_list.registerItem item_id, conf
      return

    throw new Error "Section #{section_id} does not exist."

    return
  
  unregisterSectionItem: (section_id, item_id) ->
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true)?.data?.reactive_items_list)?
      section_reactive_items_list.unregisterItem item_id

    return

  resetSectionItems: (section_id) ->
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true)?.data?.reactive_items_list)?
      section_reactive_items_list.unregisterAllItems()

    return

  _getNestedSectionsDomainId: (section_id, nested_section_item) ->
    return "#{section_id}::#{nested_section_item}"

  registerNestedSection: (section_id, nested_section_item, nested_section_id, conf) ->
    # Ensure section_id exists and nested_section_item exists and is, indeed nested section item
    if (section = @sections_reactive_items_list.getItem(section_id, true))? and 
      (item = section.data.reactive_items_list.getItem(nested_section_item, true))?
        if item.data.is_nested_section == true
          @_registerSection(nested_section_id, @_getNestedSectionsDomainId(section_id, nested_section_item), conf)
        else
          throw new Error "Item #{nested_section_item} must have data.is_nested_section set to true"
    else 
      throw new Error "Item #{@_getNestedSectionsDomainId(section_id, nested_section_item)} does not exist."

    return

  getNestedSections: (section_id, nested_section_item, ignore_listing_condition=false) ->
    return @sectionsItemsSource(section_id, nested_section_item, ignore_listing_condition)

  _getSectionFilterStateRv: (section_id) ->
    return @sections_reactive_items_list.getItem(section_id, true)?.data?.filter_state_rv

  setSectionFilterState: (section_id, state) ->
    # null and empty string are counted as no filter, strings are trimmed.

    if _.isNumber(state)
      state = "#{state}"

    if not state?
      state = ""

    if not _.isString state
      throw new Error "Invalid type"

    state = state.trim()

    if (filter_state_rv = @_getSectionFilterStateRv(section_id))?
      filter_state_rv.set(state)

      return

    throw new Error "Section '#{section_id}' has no filter"

    return

  getSectionFilterState: (section_id) -> # Reactive resource
    if (filter_state_rv = @_getSectionFilterStateRv(section_id))?
      return filter_state_rv.get()

    return ""

  clearAndFocusFirstSectionFilterInMostNestedMenu: ->
    $first_nested_menu_section_filters = $(".section-filter", $(".grid-tree-control-context-menu:visible, .nested-dropdown-menu:visible").last())
    $first_nested_menu_first_section_filter = $first_nested_menu_section_filters.first()

    # If isn't focused already
    if not $first_nested_menu_first_section_filter.is(":focus")
      $first_nested_menu_first_section_filter.focus()
      $first_nested_menu_section_filters.val("") # Clear all filters in the submenu
      $first_nested_menu_section_filters.trigger("keyup") # To update the filter reactive var

    return

  _findGridControlFromEvent: (e) ->
    # Find the grid control container that contains the event target
    $target = $(e.target)
    
    # Look through all tracked grid controls to find which one contains the event target
    for grid_control from @_registered_grid_controls
      if grid_control.container? and $target.closest(grid_control.container).length > 0
        return grid_control
    
    throw @_error "fatal", "Cannot find grid control from event. Please ensure that the grid control is registered with registerGridControl."

  _registerMainGridControl: ->
    # The grid controls from project page grid control mux does not trigger the "additional-grid-control-created" event,
    # and there are multiple grid controls from the grid control mux, so we need to register it with a tracker.
    if @_register_main_grid_control_tracker?
      return

    @_register_main_grid_control_tracker = Tracker.autorun =>
      if (gc = APP.modules.project_page.gridControl())?
        @registerGridControl gc

      return

  registerGridControl: (grid_control) ->
    if not grid_control?
      throw @_error "missing-argument", "Grid Control is required"
      
    if @_registered_grid_controls.has(grid_control)
      return

    @_registered_grid_controls.add(grid_control)
    
    # Auto-cleanup when grid control is destroyed
    grid_control.once "destroyed", =>
      @unregisterGridControl(grid_control)
    
    return

  unregisterGridControl: (grid_control) ->
    @_registered_grid_controls.delete(grid_control)
    return
  
  getGridControlWithOpenedContextMenu: ->
    return @_gc_with_opened_context_menu_rv.get()
  
  setGridControlWithOpenedContextMenu: (grid_control) ->
    @_gc_with_opened_context_menu_rv.set(grid_control)
    return