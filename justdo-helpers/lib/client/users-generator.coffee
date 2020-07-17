_.extend JustdoHelpers,
  usersGenerator: (options, cb) ->
    if not JustdoHelpers.isPocPermittedDomains()
      return

    default_options =
      project_id: APP.modules.project_page?.curProj()?.id
      
    options = _.extend {}, default_options

    return Meteor.call "JDHelperUsersGenerator", options, cb
