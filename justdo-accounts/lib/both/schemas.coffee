_.extend JustdoAccounts.prototype,
  _attachSchema: ->
    Meteor.users.attachSchema
      emails:
        optional: true 
        # In the first phase of oauth based registration
        # user might be created by Meteor without our
        # control, therefore, without this field.
        # Thus, we must set it to optional.

        type: [Object] # In fact, it is an array, but, sandboxed... We don't want to worry about future changes.
        blackbox: true

      profile:
        type: JustdoAccounts.user_profile_schema

      createdAt:
        type: Date

      invited_by:
        optional: true

        type: String

      users_allowed_to_edit_pre_enrollment:
        optional: true

        type: [String]

      services:
        optional: true

        type: Object
        blackbox: true

      signed_legal_docs:
        optional: true

        type: Object

      deactivated:
        optional: true

        type: Boolean

      is_proxy:
        optional: true

        type: Boolean

      "signed_legal_docs.terms_conditions":
        optional: true

        type: JustdoAccounts.standard_legal_doc_structure

      "signed_legal_docs.privacy_policy":
        optional: true

        type: JustdoAccounts.standard_legal_doc_structure

      "_profile_pic_metadata":
        optional: true

        type: Object

      "_profile_pic_metadata.url":
        type: String

      "_profile_pic_metadata.id":
        type: String

    return

 # note that schemas aren't prototype properties !!!
 # This is a legacy approach - don't follow it as example!
_.extend JustdoAccounts,
  user_profile_schema: new SimpleSchema
    first_name:
      optional: true 
      # In the first phase of oauth based registration
      # user might be created by Meteor without our
      # control, therefore, without this field.
      # Thus, we must set it to optional.

      label: "First name"
      type: String
      max: 50
      regEx: /\S/ # at least one non-space char
    last_name:
      optional: true 
      # In the first phase of oauth based registration
      # user might be created by Meteor without our
      # control, therefore, without this field.
     # Thus, we must set it to optional.

      label: "Last name"
      type: String
      max: 50
      regEx: /\S/ # at least one non-space char
    profile_pic:
      optional: true

      label: "Profile pic"
      type: String
      max: 1000
      # regEx: SimpleSchema.RegEx.Url, since we save SVGs here as well, might not be url
    date_format:
      label: "Date Format"
      type: String
      defaultValue: "YYYY-MM-DD"
      allowedValues: [
        "YYYY-MM-DD"
        "DD/MM/YYYY"
        "DD-MM-YYYY"
        "DD.MM.YYYY"
        "MM/DD/YYYY"
        "MM-DD-YYYY"
        "MM.DD.YYYY"
      ]

    use_am_pm:
      label: "Time format"
      type: Boolean
      optional: true # If undefined/null, should use the machine's locale
      defaultValue: null

    first_day_of_week:
      label: "First day of week"
      type: Number
      defaultValue: 1
      allowedValues: [0, 1, 2, 3, 4, 5, 6] # Follows JS Date.getDay() - 0 is Sunday

    timezone:
      optional: true

      label: "Timezone"
      type: String

    avatar_fg:
      optional: true

      label: "Avatar Foreground"
      type: String

      regEx: /^#[0-9a-f]{6}$/i

    avatar_bg:
      optional: true

      label: "Avatar Background"
      type: String

      regEx: /^#[0-9a-f]{6}$/i

  get_user_public_info_options_schema: new SimpleSchema
    email:
      label: "Email"
      type: String
      regEx: JustdoHelpers.common_regexps.email

    ignore_invited:
      label: "Ignore users with no password (consider them non-existing)"
      type: Boolean
      optional: true
      defaultValue: false

  standard_legal_doc_structure: new SimpleSchema
    datetime_signed:
      type: Date

    version:
      type: Object
      optional: true

    "version.version":
      type: String

    "version.date":
      type: String
      optional: true


