AddTopLevelItem = (grid_control, operations_container) ->
  @_grid_control = grid_control
  @_operations_container = operations_container

  @_init()

_.extend AddTopLevelItem.prototype,
  _init_html: '<button id="addTopLevelItemController" class="btn btn-primary" type="submit"></button>'

  _container: null

  _init: ->
    @_container = $(@_init_html)

    @_container.html("Add Top Level Item")

    @_container.appendTo(@_operations_container)

    @_container.click =>
      @_operation()

    @_updateState()

    @_grid_control._grid.onActiveCellChanged.subscribe (e, args) =>
      @_updateState()

  _updateState: -> true

  _operation: ->
    @_grid_control._grid_data.addChild "/", {}, (err, child_id, child_path) =>
      @_grid_control.once "rebuild_ready", =>
        @_grid_control.activatePath child_path

  destroy: ->
    @_container.remove()

_.extend PACK.OperationControllers,
  AddTopLevelItem: AddTopLevelItem
