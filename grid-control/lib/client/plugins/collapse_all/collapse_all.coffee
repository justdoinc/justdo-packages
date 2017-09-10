_.extend PACK.Plugins,
  collapse_all:
    init: ->
      # Note: @ is the grid_control object

      $el = $("""<div class="collapse-grid-button" title="Collapse all tree" />""")
        .click =>
          @_grid_data.collapseAllPaths()

      $(".slick-header-column:first", @container)
        .append($el)

      return

    destroy: ->
      return