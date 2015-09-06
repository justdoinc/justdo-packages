TestCol = share.TestCol

Meteor.publish "testCol", ->
  TestCol.find()

Meteor.methods
  gridDataSeeder: (users, items) ->
    options = {}

    if users?
      options.users_count = users

    if items?
      options.items_count = items

    gridDataSeeder TestCol, options

allow_rule = (uid, post) -> parseInt(post._id, 10) % 2 == 0 # can edit even numbers
TestCol.allow
  insert: allow_rule
  update: allow_rule
  remove: allow_rule

grid_data_com = new GridDataCom TestCol

grid_data_com.initDefaultGridAllowDenyRules()

grid_data_com.setupGridPublication()