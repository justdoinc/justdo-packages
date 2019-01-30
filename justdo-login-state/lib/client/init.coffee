_.extend JustdoLoginState.prototype,
  _immediate_init: ->
    # we can't wait with initial_user_state_ready_rv init as it
    # trigger the first call to getLoginState() which we must
    # call *before* Meteor.startup is called, otherwise, non
    # of our Meteor Accounts hooks will be called (called once on startup) 
    @initial_user_state_ready_rv = @getInitialUserStateReadyReactiveVar()

    if @options.setup_global_templates
      @setupGlobalHelpers()

    return

  _init: ->
    return
