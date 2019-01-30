_.extend JustdoAccounts.prototype,
  _getAvatarUploadPath: (user_id) ->
    return "/accounts-avatars/#{user_id}/"

  _testAvatarUploadPath: (path, user_id) ->
    return new RegExp("\\/accounts-avatars\\/#{user_id}\\/[^\\\\]+$").test(path)
