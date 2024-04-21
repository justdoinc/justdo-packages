hook = null

_.extend JustdoHelpers,
  directOwnershipAssignment: (enable=true, options) ->
    if options?
      {show_snackbar} = options

    if enable
      if not hook?
        hook = JD.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
          if modifier.$set?.pending_owner_id?
            modifier.$set.owner_id = modifier.$set?.pending_owner_id
            delete modifier.$set?.pending_owner_id
            return
    else
      if hook?
        hook.remove()
        hook = null

    if show_snackbar isnt false
      JustdoSnackbar.show
        text: "Direct ownership assignment #{if enable then "activated" else "deactivated"}."
        duration: 4000

    return
