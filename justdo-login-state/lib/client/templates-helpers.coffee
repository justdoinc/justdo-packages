_.extend JustdoLoginState.prototype,
  setupGlobalHelpers: ->
    self = @

    Template.registerHelper "loginStateIs", (...args) ->
      self.loginStateIs.apply self, args

    Template.registerHelper "initialUserStateReady", ->
      self.initial_user_state_ready_rv.get()

    Template.registerHelper "isInitialLoginState", ->
      self.isInitialLoginState()
      