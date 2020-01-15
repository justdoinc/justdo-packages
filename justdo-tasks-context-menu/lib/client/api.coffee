_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  _immediateInit: ->
    @_context_item_id_reactive_var = new ReactiveVar(null)

    @context_menu_template_obj =
      JustdoHelpers.renderTemplateInNewNode("tasks_context_menu", {controller: @}, "div")

    $(@context_menu_template_obj.node).addClass("dropdown #{@context_class}")

    @_setupHideConditions()

    return

  _deferredInit: ->
    if @destroyed
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

    $("body").on "mouseup", =>
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