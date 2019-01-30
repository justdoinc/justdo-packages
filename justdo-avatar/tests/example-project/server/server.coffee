Meteor.startup ->
  Meteor.users.remove {}

  createUsers = (i) -> 
    Accounts.createUser
      email: "user#{i}@email.com"
      password: "123456"
      profile:
        first_name: "first#{i}"
        last_name: "last#{i}"

  createUsers(i) for i in [0..5]