_.extend JustdoI18n.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods 
      getProofreaderDoc: (options) ->
        return self.getProofreaderDoc options

    return