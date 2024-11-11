_.extend JustdoUserActivePosition.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      logPos: (pos) ->
        # SECURITY: pos is checked inside logPos

        @unblock() # No need to block the next method from executing...

        return self.logPos(pos, @userId)

    return
