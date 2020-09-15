_.extend JustdoDependencies.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    self = @
  
    @alertOrThrow = (error_type)->
      if Meteor.isClient
        JustdoSnackbar.show
          text: self._errors_types[error_type]
      else
        throw self._error error_type
      return

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return