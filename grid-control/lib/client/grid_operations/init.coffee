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
    for opId, op_struct of PACK.GridOperations
      do (opId, op_struct) =>
        @[opId] = =>
          prereq = op_struct.prereq.call @
          if _.isEmpty prereq
            op_struct.op.apply @, arguments
          else
            throw @_error "unfulfilled-prereq", prereq

        @[opId].prereq = => op_struct.prereq.call @