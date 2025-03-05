Template._loginDropdownEditAvatarColorsBtn.events
  "click .edit-avatar-colors": (e) -> 
    APP.accounts.editUserAvatarColor Meteor.userId(), (err) ->
      if err?
        JustdoSnackbar.show
          text: "Failed to edit avatar colors: \n#{err.reason}"
      return
    
    return