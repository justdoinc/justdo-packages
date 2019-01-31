Template._loginDropdownNameAndEmailArea.events
  "click .verify-your-email": ->
    APP.justdo_email_verification_prompt.showEmailVerificationRequiredDialog()

    return