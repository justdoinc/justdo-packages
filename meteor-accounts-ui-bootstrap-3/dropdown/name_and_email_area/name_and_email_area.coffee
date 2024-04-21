Template._loginDropdownNameAndEmailArea.helpers
  currentUser: -> Meteor.user({fields: {_id: 1, "profile.first_name": 1, "profile.last_name": 1, all_emails_verified: 1}})

Template._loginDropdownNameAndEmailArea.events
  "click .verify-your-email": ->
    APP.justdo_email_verification_prompt.showEmailVerificationRequiredDialog()

    return