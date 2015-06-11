initData = (users, items) ->
  Meteor.call "gridDataSeeder", "default", users, items

initData()
