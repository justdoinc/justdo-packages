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

  datesMax: (...dates) ->
    dates = _.map dates, (date) -> date?.valueOf() or 0

    return new Date(Math.max(...dates))

  datesMin: (...dates) ->
    dates = _.filter(_.map(dates, (date) -> date?.valueOf() or 0), (date) -> date != 0)

    if _.isEmpty(dates)
      dates = [0]

    return new Date(Math.min(...dates))
