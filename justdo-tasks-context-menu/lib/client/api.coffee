_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  _immediateInit: ->
    @_context_item_id_reactive_var = new ReactiveVar(null)
    @sections_reactive_items_list = new JustdoHelpers.ReactiveItemsList() # The "main" domain will be used for the main sections

    @setupCoreMenuSections()

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

  _setupContextMenuEvent: ->
    $("body").on "contextmenu", ".slick-viewport", (e) =>
      if $(e.target).closest(".editable").length > 0
        # While in edit mode, don't hijack the right click
        return

      if not (gc = APP.modules.project_page.gridControl())?
        # Can't find the active grid obj
        return

      if not (event_item = gc.getEventItem(e))?
        # Can't find event's item
        return

      if event_item._type?
        # We don't show context menu for typed items
        return

      e.preventDefault()
      gc.activateRow(gc.getEventRow(e))
      @show(event_item._id, {of: e})

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
    Tracker.autorun =>
      # If the active grid control changes or destroy, hide the context menu
      APP.modules.project_page.gridControl()

      @hide()

      return

    Tracker.autorun =>
      # If the active item changes from the item that initiated the opening of the context menu,
      # close the context menu.
      if JD.activeItem({_id: 1})?._id != @_context_item_id_reactive_var.get()
        @hide()

      return

    # Hide if the context item id isn't exists (example if it gets removed by another user).
    Tracker.autorun =>
      if (active_item_id = @_context_item_id_reactive_var.get())?
        if not APP.collections.Tasks.findOne(active_item_id)?
          @hide()

      return

    # Hide on grid_control scroll (following gmail behavior)
    Tracker.autorun =>
      gc = APP.modules.project_page.gridControl()

      if not gc?
        return

      if gc._hide_context_on_scroll_initiated
        return
      gc._hide_context_on_scroll_initiated = true

      gc.container.find(".slick-viewport").on "scroll", => @hide()

      return

    return

  $getNode: ->
    return $(@context_menu_template_obj.node)

  show: (item_id, jquery_ui_position_obj) ->
    if not item_id? or not _.isString(item_id)
      console.error "JustdoTasksContextMenu: @show(): item_id is required"

      return

    if not jquery_ui_position_obj? or not _.isObject(jquery_ui_position_obj)
      jquery_ui_position_obj = {}

    default_jquery_ui_position_obj =
      my: "left top"
      at: "left bottom"
      of: "body"

    jquery_ui_position_obj =
      _.extend default_jquery_ui_position_obj, jquery_ui_position_obj

    @_context_item_id_reactive_var.set item_id
 
    @$getNode()
      .addClass("show")
      .find(".dropdown-menu")
      .addClass("show")

    @$getNode().position(jquery_ui_position_obj)

    return

  hide: ->
    @$getNode().removeClass("show").find(".dropdown-menu").removeClass("show")

    return

  getContextItemId: -> @_context_item_id_reactive_var.get()

  getContextItemObj: -> @tasks_collection.findOne(@getContextItemId())

  _registerSection_conf_scehma: new SimpleSchema
    position: 
      type: Number
    data:
      optional: true
      type: new SimpleSchema
        label:
          type: String
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

    Meteor._ensure conf, "data" # It is very unlikely that we won't have data object, as it is needed to set a label for the section

    # Create shallow copy to avoid affecting the original conf obj provided
    conf = _.extend {}, conf,
      domain: domain

    # Create shallow copy to avoid affecting the original data obj provided
    conf.data = _.extend {}, conf.data,
      reactive_items_list: new JustdoHelpers.ReactiveItemsList()

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
          type: String
        op: 
          optional: true
          type: Function
        is_nested_section:
          optional: true
          type: Boolean
        icon_type:
          optional: true
          type: String
          allowedValues: ["feather"] # ["user-avatar", "font-awesome"] might support these two in the future as well.
        icon_val:
          optional: true
          type: String
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
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true).data.reactive_items_list)?
      section_reactive_items_list.unregisterItem item_id

    return

  _getNestedSectionsDomainId: (section_id, nested_section_item) ->
    return "#{section_id}::#{nested_section_item}"

  registerNestedSection: (section_id, nested_section_item, nested_section_id, conf) ->
    # Ensure section_id exists and nested_section_item exists and is, indeed nested section item
    if (section = @sections_reactive_items_list.getItem section_id)? and 
      (item = section.data.reactive_items_list.getItem nested_section_item)?
        if item.data.is_nested_section == true
          @_registerSection(nested_section_id, @_getNestedSectionsDomainId(section_id, nested_section_item), conf)
        else
          throw new Error "Item #{nested_section_item} must have data.is_nested_section set to true"
    else 
      throw new Error "Item #{@_getNestedSectionsDomainId(section_id, nested_section_item)} does not exist."

    return

  getNestedSections: (section_id, nested_section_item, ignore_listing_condition=false) ->
    return @sections_reactive_items_list.getList(@_getNestedSectionsDomainId(section_id, nested_section_item), ignore_listing_condition)