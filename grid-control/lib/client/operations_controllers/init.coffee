PACK.OperationControllers = {}

_.extend GridControl.prototype,
  _operation_controllers: null
  _init_operation_controllers: ->
    @_operation_controllers = {}

    for operation_controller_name, operation_controller of PACK.OperationControllers
      @_operation_controllers[operation_controller_name] =
        new operation_controller(@, @operations_container)
