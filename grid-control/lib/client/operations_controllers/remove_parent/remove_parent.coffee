RemoveParent = (grid_control, operations_container) ->
  @_grid_control = grid_control
  @_operations_container = operations_container

  @_init()

_.extend RemoveParent.prototype,
  _init_html: '<button id="RemoveParentController" class="btn btn-primary" type="submit"></button>'

  _container: null

  _init: ->
    @_container = $(@_init_html)

    @_container.html("Remove")

    @_container.appendTo(@_operations_container)

    @_container.click =>
      @_operation()

    @_updateState()

    @_grid_control._grid.onActiveCellChanged.subscribe (e, args) =>
      @_updateState()

  _updateState: ->
    active_cell = @_grid_control._grid.getActiveCell()

    if active_cell? and not @_grid_control._grid_data.getItemHasChild(active_cell.row)
      @_container.removeAttr "disabled", true
    else
      @_container.attr "disabled", true

  _operation: ->
    if not(@_container.prop "disabled")
      @_grid_control._grid_data.removeParent(@_grid_control.getActiveCellPath())
      @_grid_control._grid.resetActiveCell()

  destroy: ->
    @_container.remove()

_.extend PACK.OperationControllers,
  RemoveParent: RemoveParent
