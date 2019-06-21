PACK.GridOperations = {}
# GridOperations structure:
# {
#   opId: {
#     op: -> operation
#     prereq: -> prereq generator, read more on operations_prereq.coffee
#   }  
# }
#
# @_load_grid_operations() will add to the grid_control object a new method
# for each listed operation. The method will be named after its opId (hance
# lowerCamelCase).
#
# The operation method will call prereq() to make sure prereq are fulfilled,
# otherwise an `unfulfilled-prereq` error will be thrown (with prereq issues
# in the exception details).
#
# If all prereq are fulfilled (empty object returned from prereq())
# op() will be called with the arguments passed to the method.
#
# @_load_grid_operations() also add to each created method function object
# a reference to the prereq func.
#
# Inside both op and prereq this is the grid_control object.
#
# Note:
# 1. opId should be lowerCamelCased.

_.extend GridControl.prototype,
  _load_grid_operations: ->
    @_custom_grid_operations_pre_requirements = {}

    for opId, op_struct of PACK.GridOperations
      do (opId, op_struct) =>
        @[opId] = =>
          prereq = @[opId].prereq.call @
          if _.isEmpty prereq
            op_struct.op.apply @, arguments
          else
            throw @_error "unfulfilled-prereq", prereq

        @[opId].prereq = =>
          prereq = op_struct.prereq.call @

          for customPrereq in @getCustomGridOperationPreReq(opId)
            prereq = customPrereq(prereq)

          return prereq

  getCustomGridOperationPreReq: (opId) ->
    # Returns a shallow copy of opId custom prereqs
    if not @_custom_grid_operations_pre_requirements[opId]?
      return []

    return @_custom_grid_operations_pre_requirements[opId].slice() # slice to create a copy

  registerCustomGridOperationPreReq: (opId, prereq) ->
    if not _.isFunction prereq
      throw @_error "invalid-argument", "registerCustomGridOperationPreReq: prereq has to be a function"

    if not @_custom_grid_operations_pre_requirements[opId]?
      @_custom_grid_operations_pre_requirements[opId] = []

    registry = @_custom_grid_operations_pre_requirements[opId]

    if prereq in registry
      return

    registry.push prereq

    return

  unregisterCustomGridOperationPreReq: (opId, prereq) ->
    if not _.isFunction prereq
      throw @_error "invalid-argument", "registerCustomGridOperationPreReq: prereq has to be a function"

    if not @_custom_grid_operations_pre_requirements[opId]?
      console.warn "registerCustomGridOperationPreReq: No custom prereq is registered for opId"

      return

    @_custom_grid_operations_pre_requirements[opId] =
      _.without @_custom_grid_operations_pre_requirements[opId], prereq

    return
