_meteor_error_listeners = new Set()

orgMeteorError = Meteor.Error
Meteor.Error = (error, reason, details) ->
  _meteor_error_listeners.forEach (listener) ->
    listener(error, reason, details)

    return

  return orgMeteorError.apply(@, arguments)

  
APP.addMeteorErrorListener = (listener) ->
  if _meteor_error_listeners.has listener
    return false

  _meteor_error_listeners.add listener
  return true

APP.removeMeteorErrorListener = (listener) ->
  return _meteor_error_listeners.delete listener

_show_snackbar_on_errors = {}
_show_snackbar_on_errors_regex = {}
APP.addMeteorErrorListener (error, reason, details) ->
  if (err_msg_cb = _show_snackbar_on_errors[error])?
    if err_msg_cb != false
      err_msg = err_msg_cb error, reason, details
    else
      err_msg = reason or error
    JustdoSnackbar.show
      text: err_msg
  else
    for regex, err_msg_cb of _show_snackbar_on_errors_regex
      if new RegExp(regex).test error
        if err_msg_cb != false
          err_msg = err_msg_cb error, reason, details
        else
          err_msg = reason or error
        JustdoSnackbar.show
          text: err_msg
  
  return

APP.showSnackbarOnErrors = (error_codes, err_msg_cb=false) ->
  if not _.isArray error_codes
    error_codes = [error_codes]

  for error_code in error_codes
    if _.isRegExp error_code
      _show_snackbar_on_errors_regex[error_code.source] = err_msg_cb
    else if _.isString error_code
      _show_snackbar_on_errors[error_code] = err_msg_cb
  
  return