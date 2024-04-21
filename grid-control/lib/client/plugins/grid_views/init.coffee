_.extend PACK.Plugins,
  grid_views:
    init: ->
      # Note: @ is the grid_control object

      @_setupColumnsReordering()

      @_initFilters()

      @_setupColumnsManagerContextMenu()

      @on "columns-headers-dom-rebuilt", =>
        @_setupColumnsManagerContextMenu()

      # Track changes to columns resize, the only view-altering operation
      # implemented in the slick grid level, and triger the grid-view-change
      # event when it happens
      @_grid.onColumnsResized.subscribe (e,args) =>
        @emit "grid-view-change", @getView()

    destroy: ->
      @_destroyColumnsManagerContextMenu()