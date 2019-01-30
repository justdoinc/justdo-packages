helpers = share.helpers

default_options =
  # expired_token_state_delay sets the time in ms we wait when
  # an expired token received by the reset/enroll/verify processes
  # and as a result we are in getLoginState's *-expired state.
  # Once the expired_token_state_delay time pass, we call the
  # reset/enroll/verify done callback to continue the regular
  # auto login procedures that were blocked by these processes 
  expired_token_state_delay: 6000

  # Relevant only for client, if set to true, the global templates
  # helpers defined in client/tepmlates-helpers.coffee will be
  # installed.
  setup_global_templates: true

JustdoLoginState = (options) ->
  EventEmitter.call this

  @logger = Logger.get("justdo-login-state")

  @options = _.extend {}, default_options, options

  @_immediate_init()

  # Keep for testing purposes
  # if Meteor.isClient
  #   Tracker.autorun =>
  #     console.log @getLoginState()
  #     console.log @isInitialLoginState()

  Meteor.defer =>
    @_init()

  return @

Util.inherits JustdoLoginState, EventEmitter

_.extend JustdoLoginState.prototype,
  _error: JustdoHelpers.constructor_error