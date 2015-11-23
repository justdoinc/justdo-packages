share.exceptions =
  unkownPath: -> new Meteor.Error("unkown-path", "Path doesn't exist or doesn't belong to the user")
  cantPerformOnRoot: -> new Meteor.Error("cant-perform-on-root", "This operation can't perform on root path")
  loginRequired: -> new Meteor.Error("login-required", "Login required to perform operation")
