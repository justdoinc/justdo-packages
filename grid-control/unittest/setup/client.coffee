initData = (users, items) ->
  Meteor.call "gridDataSeeder", users, items

initData()
