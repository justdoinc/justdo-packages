setupCollapseAllButton = (grid_control) ->
  $el = $("""<div class="grid-state-button collapse-grid-button" title="Collapse all tree"><svg><use xlink:href="/layout/icons-feather-sprite.svg#minus"></use></svg></div>""")
    .click =>
      grid_control._grid_data.collapseAllPaths()

  $(".slick-header-column:first", grid_control.container)
    .prepend($el)

  $el = $("""<div class="grid-state-button expand-grid-button" jd-tt="expand-grid"><svg><use xlink:href="/layout/icons-feather-sprite.svg#plus"></use></svg></div>""")
    .click =>
      grid_control.expandDepth()

      return

  $(".slick-header-column:first", grid_control.container)
    .prepend($el)

  return

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
