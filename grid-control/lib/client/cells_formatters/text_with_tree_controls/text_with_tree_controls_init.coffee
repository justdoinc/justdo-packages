_.extend PACK.FormattersInit,
  textWithTreeControls: ->
    @_grid.onClick.subscribe (e, args) =>
      if $(e.target).hasClass("grid-tree-control-toggle")
        @_grid_data.toggleItem args.row

        e.stopImmediatePropagation()
