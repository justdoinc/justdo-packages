_.extend JustdoHelpers,
  getDateMsOffset: (ms_offset, date) ->
    # Returns a new date offsetted ms_offset milliseconds from date
    # if date isn't provided, we'll use the current date

    if not date?
      date = new Date()

    date = new Date(date)

    date.setMilliseconds(date.getMilliseconds() + ms_offset)

    return date

  negativeDateOrNow: (date) ->
    # Avoid clock differences between server and client to result
    # in future time description such as "In few seconds" by moment.js .
    if (new Date()) < date
      return new Date()

    return date