Meteor.publish null, ->
  @added("JustdoSystem", "android-min-version", {build: 1})
  @added("JustdoSystem", "ios-min-version", {build: 1})

  @ready()

  return
