# Based on: https://stackoverflow.com/questions/19519535/detect-if-browser-tab-is-active-or-user-has-switched-away

JustdoHelpers.isTabVisible = do ->
  # Can be called in two forms:
  # 1: isTabVisible(handler) - handler will be called on tab visiblity changes
  # 2: isTabVisible() - will return true if tab visible, false otherwise
  keys = 
    hidden: 'visibilitychange'
    webkitHidden: 'webkitvisibilitychange'
    mozHidden: 'mozvisibilitychange'
    msHidden: 'msvisibilitychange'
    # state_key: event_key

  for state_key, event_key of keys
    `stateKey = stateKey`
    if state_key of document
      break

  return (changes_handler) ->
    if changes_handler?
      document.addEventListener event_key, changes_handler

    return not document[state_key]