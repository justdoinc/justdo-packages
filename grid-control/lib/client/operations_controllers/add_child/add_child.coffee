AddChild = (grid_control, operations_container) ->
  @_grid_control = grid_control
  @_operations_container = operations_container

  @_init()

_.extend AddChild.prototype,
  _init_html: '<button id="addChildController" class="btn btn-primary" type="submit"></button>'

  _container: null

  _init: ->
    @_container = $(@_init_html)

    @_container.html("Add Child")

    @_container.appendTo(@_operations_container)

    @_container.click =>
      @_operation()

    @_updateState()

    @_grid_control._grid.onActiveCellChanged.subscribe (e, args) =>
      @_updateState()

  _updateState: ->
    active_cell = @_grid_control._grid.getActiveCell()

    if active_cell?
      @_container.removeAttr "disabled", true
    else
      @_container.attr "disabled", true

  _operation: ->
    if not(@_container.prop "disabled")
      @_grid_control._grid_data.addChild @_grid_control.getActiveCellPath(), (err, child_id, child_path) =>

        @_grid_control._grid_data.once "rebuild", =>
          Meteor.defer =>
            @_grid_control.activatePath child_path

  destroy: ->
    @_container.remove()

_.extend PACK.OperationControllers,
  AddChild: AddChild
