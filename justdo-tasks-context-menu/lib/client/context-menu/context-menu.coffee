Template.tasks_context_menu.onCreated ->
  @tasks_context_menu_controller = @data.controller

  return

Template.tasks_context_menu.helpers
  getMainSections: -> 
    return APP.justdo_tasks_context_menu.getMainSections()

  updatedByOrCreatedBy: ->
    item_obj = @controller.getContextItemObj()

    if not item_obj?
      return false

    return item_obj.updated_by or item_obj.created_by_user_id

Template.tasks_context_section.onCreated ->
  return

Template.tasks_context_section.helpers
  hasNestedSections: (section) -> @is_nested_section is true

  getNestedSections: (parent_section_id, nested_section_id) ->
    tpl = Template.instance()

    return APP.justdo_tasks_context_menu.getNestedSections parent_section_id, nested_section_id

Template.tasks_context_section.events
  "mouseover .context-nested-section-item": (e) ->
    $item = $(e.target).closest(".context-nested-section-item")

    # Credit: https://stackoverflow.com/questions/18955334/collision-detection-in-bootstrap-dropdown
    $menu = $item.find(".dropdown-menu")
    if $menu != null and $menu.length == 1
      $menu.position
        of: $item
        my: "left top"
        at: "right top"
        collision: "flipfit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          element.element.css
            top: new_position.top - 8
            left: new_position.left

    return

  "click .context-nested-section-item": (e) ->
    if $(e.target).closest(".context-action-item").hasClass("context-nested-section-item")
      # Stop propagation to avoid closing the context-menu when the sub-menu item clicked (to be in-line with
      # common behaviour of UI).
      e.stopPropagation()

    return

  "click .context-action-item": (e) ->
    tpl = Template.instance()

    if _.isFunction @op
      call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @op.apply(@, call_args)

      return

    return

Template.tasks_context_menu_label.helpers
  getLabelValue: ->
    tpl = Template.instance()

    if _.isFunction @label
      call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @label.apply(@, call_args)

    if _.isString @label
      return @label

    return undefined

Template.tasks_context_menu_icon.helpers
  getIconValValue: ->
    tpl = Template.instance()

    if _.isFunction @icon_val
      call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @icon_val.apply(@, call_args)

    if _.isString @icon_val
      return @icon_val

    return undefined