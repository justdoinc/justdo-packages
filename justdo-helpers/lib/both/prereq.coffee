_.extend JustdoHelpers,
  prepareOpreqArgs: (prereq) ->
    return if prereq? then prereq else {}