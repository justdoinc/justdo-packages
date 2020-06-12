Template.tasks_context_menu.onCreated ->
  @tasks_context_menu_controller = this.data.controller

  return

Template.tasks_context_menu.helpers
  updatedByOrCreatedBy: ->
    item_obj = @controller.getContextItemObj()

    if not item_obj?
      return false

    return item_obj.updated_by or item_obj.created_by_user_id

  getMainSections: -> 
    return APP.justdo_tasks_context_menu.getMainSections()

  hasNestedSections: (section) ->
    return @is_nested_section == true and APP.justdo_tasks_context_menu.getNestedSections(section.id, @id)?.length > 0

  getNestedSections: (section) ->
    return APP.justdo_tasks_context_menu.getNestedSections section.id, @id

  getLabelValue: ->
    tpl = Template.instance()

    if _.isFunction @label
      call_args = [@].concat(tpl.tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @label.apply(@, call_args)

    if _.isString @label
      return @label

    return undefined

Template.tasks_context_menu.events 
  "click .context-action-item": ->
    tpl = Template.instance()

    if _.isFunction @op
      call_args = [@].concat(tpl.tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @op.apply(@, call_args)

      return

    return
