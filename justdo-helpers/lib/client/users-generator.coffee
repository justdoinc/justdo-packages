_.extend JustdoHelpers,
  usersGenerator: (options, cb) ->
    if not JustdoHelpers.isPocPermittedDomains()
      return
      
    return Meteor.call "JDHelperUsersGenerator", options, cb