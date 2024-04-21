GridControl.installFormatterExtension
  formatter_name: "statusFieldFormatter"
  extended_formatter_name: "defaultFormatter"
  custom_properties: {
    defaultHoverCaption: (friendly_args) ->
      if not (status_by = friendly_args.doc.status_by)? or not (status_updated_at = friendly_args.doc.status_updated_at)?
        return undefined
      
      return JustdoHelpers.displayName(Meteor.users.findOne(status_by)) + " | " + JustdoHelpers.getDateTimeStringInUserPreferenceFormat(status_updated_at, false)

    defaultFooter: (friendly_args) ->
      if not (status_by = friendly_args.doc.status_by)? or not (status_updated_at = friendly_args.doc.status_updated_at)?
        return undefined
      
      if not (status = friendly_args.doc.status)? or not _.isString(status) or _.isEmpty(status.trim())
        # As of writing, when the status is cleared we clear the status_by and status_updated_at
        return undefined

      return """#{JustdoHelpers.displayName(Meteor.users.findOne(status_by)) + " | " + JustdoHelpers.getDateTimeStringInUserPreferenceFormat(status_updated_at, false)}"""
  }