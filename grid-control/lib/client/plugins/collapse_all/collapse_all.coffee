EXPAND_TO_LEVEL_LIMIT = 3

setupCollapseAllButton = (grid_control) ->
  menu_items = grid_control.getCollapseExpandMenuItems()
  collapse_all_menu_item = menu_items.collapse_all
  expand_all_menu_item = menu_items.expand_all

  $el = $("""<div class="grid-state-button collapse-grid-button" title="#{TAPi18n.__ collapse_all_menu_item.label}"><svg><use xlink:href="/layout/icons-feather-sprite.svg#minus"></use></svg></div>""")
    .click =>
      collapse_all_menu_item.action()
      return

  $(".slick-header-column:first", grid_control.container)
    .prepend($el)

  $el = $("""<div class="grid-state-button expand-grid-button" jd-tt="expand-grid"><svg><use xlink:href="/layout/icons-feather-sprite.svg#plus"></use></svg></div>""")
    .click =>
      expand_all_menu_item.action()
      return

  $(".slick-header-column:first", grid_control.container)
    .prepend($el)

  return

_.extend GridControl.prototype,
  getCollapseExpandMenuItems: ->
    grid_control = @

    collapse_expand_menu_items =
      collapse_all:
        label: TAPi18n.__ "collapse_all_tasks_label"
        action: -> grid_control.collapseAll()

      expand_all:
        label: TAPi18n.__ "expand_all_tasks_label"
        action: -> grid_control.expandDepth()

      expand_to_level:
        label: TAPi18n.__ "expand_levels_label"
        sub_items: [1..EXPAND_TO_LEVEL_LIMIT].map (level) ->
          ret = 
            label: level
            action: -> grid_control.expandDepth({depth: level})
          return ret

    return collapse_expand_menu_items

_.extend PACK.Plugins,
  collapse_all:
    init: ->
      # Note: @ is the grid_control object

      setupCollapseAllButton(@)

      @on "columns-headers-dom-rebuilt", =>
        setupCollapseAllButton(@)

      return

    destroy: ->
      return
