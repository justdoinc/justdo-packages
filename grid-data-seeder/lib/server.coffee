gridDataSeeder = (items_collection, options) ->
  options = options or {}

  options = _.extend
    users_count: 10
    items_count: 10
  , options

  if options.users_count > 10
    throw Error("gridDataSeeder don't support more than 10 users at the moment")

  Meteor.users.remove({"profile.test_user": true})
  items_collection.remove({})

  users = (
    Accounts.createUser(
      username: "user#{id}"
      email: "user#{id}@gmail.com"
      password: "123456"
      profile: {
        test_user: true
      }
    ) for id in [0...options.users_count]
  )

  order = 0
  getParentsFromId = (id) ->
    # parents are the root ('0') and all the non-empty substring that begins from the
    # first index of the stringified id.
    # Example: 1502 parents are: '0' (root), '1', '15', '150'
    id = String(id)

    parents = {'0': {order: order++}} # 0 means root
    parents_ids = (id.substr(0, i) for i in [1...id.length])

    _.reduce parents_ids, (obj, current_parent) ->
      obj[current_parent] =
        {order: order++}
      return obj
    , parents

  getUsersFromId = (id) ->
    # items belong to a user if one of its digits is the account id
    # Example: 1052 belongs to user1, user0, user5 and user2

    (users[parseInt(id, 10)] for id in _.uniq(String(id).split("")))

  items_collection.insert(
    _id: String(id),
    parents: getParentsFromId(id)
    users: getUsersFromId(id)
    title: "Item #{id}"
    field_a: ""
    field_b: ""
    field_c: ""
    field_d: ""
  ) for id in [1..options.items_count] # begin from 1 since 0 means root

