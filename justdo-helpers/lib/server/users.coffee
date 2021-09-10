_.extend JustdoHelpers,
  getUsersByEmail: (users_ids, options) ->
    if not options?
      options =
        require_verified_email: false
        query_options: {}
        extended_query: {}

    if _.isString(users_ids)
      users_ids = [users_ids]

    check users_ids, [String]

    if _.isEmpty(users_ids)
      return []

    if not options.require_verified_email
      query =
        "emails.address": 
          $in: users_ids
    else
      query =
        "emails":
          $elemMatch:
            address: $in: users_ids
            verified: true

    if _.isObject(options.extended_query)
      _.extend query, options.extended_query

    return Meteor.users.find(query, options.query_options).fetch()
