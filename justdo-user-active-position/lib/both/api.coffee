_.extend JustdoUserActivePosition.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  onGridUserActivePositionEnabled: -> @on_grid_user_active_position_enabled

  isUserShowingActivePosition: (user) ->
    if _.isString(user)
      user_doc = Meteor.users.findOne(user, {fields: {"justdo_user_active_position.show_user_active_position": 1}})
    else
      user_doc = user
    
    if not user_doc?
      return false

    return not user_doc.justdo_user_active_position?.hide_user_active_position
