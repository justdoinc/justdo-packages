APP.justdo_tooltips.registerTooltip
  id: "expand-grid"
  template: "expand_grid_tooltip"
  hide_delay: 350

Template.expand_grid_tooltip.onCreated ->
  @grid_control = APP.modules.project_page.gridControl()

  if not (expand_menu_items_definition = @grid_control.getCollapseExpandMenuItems?())?
    return

  @expand_all_item_definition = expand_menu_items_definition.expand_all
  @expand_to_level_item_definition = expand_menu_items_definition.expand_to_level

  @tooltip_controller = @data.tooltip_controller

  return

Template.expand_grid_tooltip.helpers
  expandAllDef: ->
    tpl = Template.instance()
    return tpl.expand_all_item_definition

  expandToLevelDef: ->
    tpl = Template.instance()
    return tpl.expand_to_level_item_definition

  levels: ->
    return [1, 2, 3]

Template.expand_grid_tooltip.events
  "click .expand-grid-all": (e, tpl) ->
    tpl.expand_all_item_definition.action()

    return

  "click .expand-grid-level": (e, tpl) ->
    level = parseInt($(e.currentTarget).attr("level"), 10)

    tpl.expand_to_level_item_definition.sub_items[level - 1]?.action()

    return

  "click .dropdown-item": (e, tpl) ->
    tpl.tooltip_controller.closeTooltip()

    return

  "mouseenter .expand-grid-item": (e, tpl) ->
    $item = $(e.target).closest(".expand-grid-item")

    if $item.hasClass "dropdown-submenu"
      $(".expand-grid-dropdown .levels-menu").fadeIn()
    else
      $(".expand-grid-dropdown .levels-menu").fadeOut()

    return
