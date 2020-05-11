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

Template.tasks_context_menu.events 
  "click .context-action-item": ->
    if _.isFunction @op
      @op()

      return

