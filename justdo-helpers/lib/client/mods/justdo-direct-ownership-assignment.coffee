hook = null

_.extend JustdoHelpers,
  directOwnershipAssignment: (enable=true) ->
    if enable
      if not hook?
        hook = JD.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
          if modifier.$set?.pending_owner_id != null
            modifier.$set.owner_id = modifier.$set?.pending_owner_id
            delete modifier.$set?.pending_owner_id
            return
        JustdoSnackbar.show
          text: "Direct ownership assignment activated."
          duration: 4000
          actionText: "Dismiss"
    else
      if hook?
        hook.remove()
        hook = null
        JustdoSnackbar.show
          text: "Direct ownership assignment deactivated."
          duration: 4000
          actionText: "Dismiss"
    return