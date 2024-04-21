TestCol = new Mongo.Collection "test-col"

removeTestUsers = -> Meteor.users.remove({"profile.test_user": true})
countTestUsers = -> Meteor.users.find({"profile.test_user": true}).count()

createNonTestUser = -> Accounts.createUser({username: "non-test", email: "non-test@gmail.com", password: "123456"})
countNonTestUser = -> Meteor.users.find({username: "non-test"}).count()
removeNonTestUser = -> Meteor.users.remove({username: "non-test"})

resetTestCol = -> TestCol.remove({})
countTestCol = -> TestCol.find({}).count()

Tinytest.add 'gridDataSeeder - is defined, and is object', (test) ->
  test.isTrue _.isFunction(gridDataSeeder)

Tinytest.add 'gridDataSeeder - test users reseted correctly, no regular users removed', (test) ->
  removeNonTestUser()
  removeTestUsers()

  createNonTestUser()
  
  test.equal countNonTestUser(), 1

  test.equal countTestUsers(), 0

  gridDataSeeder TestCol

  test.equal countTestUsers(), 10

  gridDataSeeder TestCol

  test.equal countTestUsers(), 10

  gridDataSeeder TestCol,
    users_count: 4

  test.equal countTestUsers(), 4

  test.equal countNonTestUser(), 1

  removeTestUsers()
  removeNonTestUser()

Tinytest.add 'gridDataSeeder - test items reseted correctly', (test) ->
  resetTestCol()

  test.equal countTestCol(), 0

  gridDataSeeder TestCol

  test.equal countTestCol(), 10

  gridDataSeeder TestCol,
    items_count: 100

  test.equal countTestCol(), 100

  resetTestCol()
