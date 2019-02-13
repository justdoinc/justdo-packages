justdo_snackbar_default_options = {
  # text: "Default Text"
  # textColor: "#FFFFFF"
  # width: "auto"
  # showAction: true
  # actionText: "Dismiss"
  actionTextColor: "#c9a6f4"
  # showSecondButton: false
  # secondButtonText: ""
  secondButtonTextColor: "#c9a6f4"
  # backgroundColor: "#323232"'"
  # pos: "bottom-left"
  # duration: 5000
  # customClass: ''
  # onActionClick: (element) -> element.style.opacity = 0
  # onSecondButtonClick: (element) -> return
}

JustdoSnackbar =
  show: (options) ->
    options = _.extend {}, justdo_snackbar_default_options, options

    return Snackbar.show(options)
  close: ->
    return Snackbar.close()
