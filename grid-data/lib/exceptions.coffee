share.exceptions =
  unkownPath: -> new Meteor.Error("unkown-path", "Path doesn't exist or doesn't belong to the user")
  loginRequired: -> new Meteor.Error("login-required", "Login required to perform operation")
