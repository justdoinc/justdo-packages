options_schema = new SimpleSchema
  project_id: 
    type: String

  admins_count: 
    type: Number

    defaultValue: 100

  members_count: 
    type: Number

    defaultValue: 100

  guests_count: 
    type: Number

    defaultValue: 100

lorem_arr = JustdoHelpers.lorem_ipsum_arr

Meteor.methods
  "JDHelperUsersGenerator": (options) ->
    check options, Object

    if not JustdoHelpers.isPocPermittedDomains()
      return

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        options_schema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if not (project = APP.collections.Projects.findOne(options.project_id))?
      throw new Error "project-not-found"

    members = project.members
    dummy_users = []
    dummy_users_ids = []
    new_user = ->
      id = Random.id()
      dummy_users.push
        _id: id
        createdAt: new Date()
        services:
          password:
            bcrypt: "$2a$10$EFtzeNp017erAtaCKKlK9OcADZc5FUj46KBdaPfsmGqg/hdcJC/2G"  # default password: P@$$w0rd
        emails:
          [
            address: "#{id}@qq.com"
            verified: true
          ]
        profile:
          first_name: lodash.sample(lorem_arr)
          last_name: lodash.sample(lorem_arr)

      dummy_users_ids.push id

      return id

    for i in [1...options.admins_count]
      members.push 
        user_id: new_user()
        is_admin: true
    
    for i in [1...options.members_count]
      members.push 
        user_id: new_user()
        is_admin: false

    for i in [1...options.guests_count]
      members.push 
        user_id: new_user()
        is_admin: false
        is_guest: true

    # Insert users
    Meteor.users.rawCollection().insertMany dummy_users

    # Add users to project
    APP.collections.Projects.update options.project_id,
      $set:
        members: members

    return
  
    

      