_.extend JustdoHelpers,
  getUsersByEmail: (emails, options) ->
    if not options?
      options =
        require_verified_email: false
        query_options: {}
        extended_query: {}

    if _.isString(emails)
      emails = [emails]

    check emails, [String]

    if _.isEmpty(emails)
      return []

    if not options.require_verified_email
      query =
        "emails.address": 
          $in: emails
    else
      query =
        "emails":
          $elemMatch:
            address: $in: emails
            verified: true

    if _.isObject(options.extended_query)
      _.extend query, options.extended_query

    return Meteor.users.find(query, options.query_options).fetch()
