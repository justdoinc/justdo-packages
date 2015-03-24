PACK.jquery_events.push(
  {
    # React to click on toggle button while on edit mode.
    # Note: on edit mode @_grid.onClick.subscribe doesn't emit, hence
    # /cells_formatters/text_with_tree_controls/text_with_tree_controls_init.coffee
    # have no effect and we need to define the behavior again
    #
    # Event propegation is blocked if not on edit mode, hence the following
    # have no effect outside edit mode.
    args: ['click', '.grid-tree-control-toggle']
    handler: (e) ->
      @_grid_data.toggleItem @_grid.getCellFromEvent(e).row
      e.stopImmediatePropagation()
  }
)
