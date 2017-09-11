setupCollapseAllButton = (grid_control) ->
  $el = $("""<div class="collapse-grid-button" title="Collapse all tree" />""")
    .click =>
      grid_control._grid_data.collapseAllPaths()

  $(".slick-header-column:first", grid_control.container)
    .append($el)

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