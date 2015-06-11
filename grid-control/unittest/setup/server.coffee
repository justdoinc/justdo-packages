TestCollections = share.TestCollections

Meteor.methods
  gridDataSeeder: (collection_name, users, items) ->
    options = {}

    if users?
      options.users_count = users

    if items?
      options.items_count = items

    gridDataSeeder TestCollections[collection_name], options