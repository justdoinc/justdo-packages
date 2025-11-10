APP.justdo_tooltips.registerTooltip
  id: "field-description"
  template: "field_description_tooltip"

Template.field_description_tooltip.onCreated ->
  @getTooltipOriginatingEvent = ->
    return @data.tooltip_controller.tooltip_originating_event

  return

Template.field_description_tooltip.helpers
  fieldDescription: ->
    tpl = Template.instance()
    tooltip_originating_event = tpl.getTooltipOriginatingEvent()

    if not (gc = GridControl.getRegisteredGridControlFromEvent tooltip_originating_event)
      return

    {row, cell} = gc._grid.getCellFromEvent tooltip_originating_event
    {doc, field, value} = gc.getFriendlyCellArgs row, cell

    description = gc.getFieldDescription(field, value)
    
    if _.isFunction description
      description = description(doc, value)

    return description or ""