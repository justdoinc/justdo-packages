Template.justdo_recaptcha.helpers
  supported: -> APP.justdo_recaptcha.supported

  site_key: -> APP.justdo_recaptcha.v2_checkbox_site_key

Template.justdo_recaptcha.onCreated ->
  if not APP.justdo_recaptcha.supported
    console.warn "justdo-recaptcha: Recaptcha is not supported on this environment, can't display."

    return

  recaptcha_url = "https://www.google.com/recaptcha/api.js?hl=#{APP.justdo_recaptcha.hl}"

  $.ajax
    dataType: "script"
    cache: true
    url: recaptcha_url

  return
