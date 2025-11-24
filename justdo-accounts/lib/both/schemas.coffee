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
      
      deactivated_at:
        optional: true

        type: Date
        autoValue: ->
          deactivated_field = @field("deactivated")
          if not deactivated_field.isSet
            # Prevent direct update
            return @unset()

          if deactivated_field.value is true
            # Setting user as deacticated
            return new Date()
          else
            # Unsetting user as deactivated, clear this related meta field.
            return {$unset: 1}

      deactivated_by:
        optional: true

        type: String
        autoValue: ->
          deactivated_field = @field("deactivated")
          if not deactivated_field.isSet
            # Prevent direct update
            return @unset()

          if deactivated_field.value is true
            # Setting user as deacticated
            return @value
          else
            # Unsetting user as deactivated, clear this related meta field.
            return {$unset: 1}

      is_proxy:
        optional: true

        type: Boolean
      
      proxy_created_at:
        optional: true

        type: Date

        autoValue: ->
          # Auto-set upon insert
          if @field("is_proxy").value is true
            if @isInsert
              return new Date()
            else if @isUpsert
              return {$setOnInsert: new Date()}

          # Prevent other modifications
          return @unset()

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
      label_i18n: "first_name_schema_label"
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
      label_i18n: "last_name_schema_label"
      type: String
      max: 50
      regEx: /\S/ # at least one non-space char
    profile_pic:
      optional: true

      label: "Profile pic"
      label_i18n: "profile_pic_schema_label"
      type: String
      max: 1000
      # regEx: SimpleSchema.RegEx.Url, since we save SVGs here as well, might not be url
    date_format:
      label: "Date Format"
      label_i18n: "date_format_schema_label"
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
      label_i18n: "time_format_schema_label"
      type: Boolean
      optional: true # If undefined/null, should use the machine's locale
      defaultValue: null

    first_day_of_week:
      label: "First day of week"
      label_i18n: "first_day_of_week_schema_label"
      type: Number
      defaultValue: 1
      allowedValues: [0, 1, 2, 3, 4, 5, 6] # Follows JS Date.getDay() - 0 is Sunday

    timezone:
      optional: true

      label: "Timezone"
      label_i18n: "timezone_schema_label"
      type: String

    avatar_fg:
      optional: true

      label: "Avatar Foreground"
      label_i18n: "avatar_fg_schema_label"
      type: String

      regEx: /^#[0-9a-f]{3}([0-9a-f]{3})?$/i

    avatar_bg:
      optional: true

      label: "Avatar Background"
      label_i18n: "avatar_bg_schema_label"
      type: String

      regEx: /^#[0-9a-f]{3}([0-9a-f]{3})?$/i
    
    lang:
      optional: true

      label: "Preferred Language"
      label_i18n: "lang_schema_label"
      type: String

    unsubscribe_from_all_email_notifications:
      label: "Disable all email notifications"
      label_i18n: "unsubscribe_from_all_email_notifications_schema_label"
      type: Boolean
      optional: true

  get_user_public_info_options_schema: new SimpleSchema
    email:
      label: "Email"
      label_i18n: "email_schema_label"
      type: String
      regEx: JustdoHelpers.common_regexps.email

    ignore_invited:
      label: "Ignore users with no password (consider them non-existing)"
      label_i18n: "ignore_invites_schema_label"
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


