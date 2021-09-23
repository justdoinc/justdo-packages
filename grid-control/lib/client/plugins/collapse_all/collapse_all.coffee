default_options = {
  expand_all_max: 75
}

setupCollapseAllButton = (grid_control) ->
  # Options are passed to the standard grid_control options argument upon init of the constructor.

  options = _.extend {}, default_options, grid_control.options # apply actual options passed by the user

  $el = $("""<div class="grid-state-button collapse-grid-button" title="Collapse all tree"><svg><use xlink:href="/layout/icons-feather-sprite.svg#minus"></use></svg></div>""")
    .click =>
      grid_control._grid_data.collapseAllPaths()

  $(".slick-header-column:first", grid_control.container)
    .prepend($el)

  $el = $("""<div class="grid-state-button expand-grid-button" jd-tt="expand-grid"><svg><use xlink:href="/layout/icons-feather-sprite.svg#plus"></use></svg></div>""")
    .click =>
      grid_control.expandDepth({max_items: options.expand_all_max})

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
