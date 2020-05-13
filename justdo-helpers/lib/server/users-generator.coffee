faker = require "faker"

options_schema = new SimpleSchema
  project_id: 
    type: String
  # task_ids: 
  #   type: [String]
  admins_count: 
    type: Number
  members_count: 
    type: Number
  guests_count: 
    type: Number

Meteor.methods
  "JDHelperUsersGenerator": (options) ->
    options = _.extend {},
      # task_ids: []
      admins_count: 10
      members_count: 10
      guests_count: 10
    , options

    options_schema.validate options

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
          fisrt_name: faker.name.firstName()
          last_name: faker.name.lastName()

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

    # Add users to tasks
    # for task_id in options.task_ids
    #   task = APP.collections.Tasks.findOne task_id
    #   if task?.project_id == options.project_id
    #     APP.collections.Tasks.update task_id,
    #       $set: 
    #         users: task.users.concat dummy_users_ids

    return
  
    

      