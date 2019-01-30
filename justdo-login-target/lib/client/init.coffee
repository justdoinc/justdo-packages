if Meteor.users?
  # accounts-base edits the hash part of the url if one of
  # its tokens receiving endpoints is called (email-verification/enrollment/password reset)
  throw new Meteor.Error("packages-load-order-issue", "justdo-login-target package must be loaded before the accounts-base package - reorder your package.js folder")

original_hash = window.location.hash

# We expect target to come in a pseusdo get-params-like query string
# section of the hash param, exapmle: http://x.com/#x?b=d&target=xyz&fad=c
hash_target_regex = /([?&])target=([^&]+?)(?:(&)(.*))?$/i

result = hash_target_regex.exec(original_hash)

original_target = null
if result?
  try
    original_target = result[2]
    original_target_word_array = CryptoJS.enc.Base64.parse(original_target)
    original_target = original_target_word_array.toString(CryptoJS.enc.Utf8)
  catch e
    console.error "Couldn't parse provided login target, skipping"

    original_target = null

  # get rid of the target section of the hash query-string
  # to avoid interfering other packages (such as accounts-base)
  new_hash = original_hash.replace hash_target_regex, (match, pre_delimiter, target, post_delimiter, rest) ->
    if not _.isEmpty rest
      # if there are more parts to the hash query string, remove only the target part, keep the
      # query-string valid
      return pre_delimiter + rest
    else
      # If there are no more parts to the hash query string, remove the query
      # string section altogether
      return ""

  window.location.hash = new_hash

_.extend JustdoLoginTarget.prototype,
  _init: ->
    try
      @setTargetUrl(original_target)
    catch e
      undefined # Just prevent breaking, do nothing 
