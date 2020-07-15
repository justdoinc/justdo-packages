_.extend JustdoHelpers,
  usersGenerator: (options, cb) ->
    if not JustdoHelpers.isPocPermittedDomains()
      return
      
    if not options.project_id:
      options.project_id = APP.modules.project_page.curProj().id
      
    return Meteor.call "JDHelperUsersGenerator", options, cb