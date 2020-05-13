_.extend JustdoHelpers,
  usersGenerator: (options, cb) ->
    return Meteor.call "JDHelperUsersGenerator", options, cb