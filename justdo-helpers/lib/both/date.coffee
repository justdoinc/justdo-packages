_.extend JustdoHelpers,
  getDateTimestamp: (date) -> (date or (new Date())).valueOf()

  datesMsDiff: (date1, date2) ->
    # Returns ms value of: date1 - date2
    return JustdoHelpers.getDateTimestamp(date1) - JustdoHelpers.getDateTimestamp(date2)

  timeSinceDateMs: (date) ->
    return JustdoHelpers.datesMsDiff(new Date(), date)

  getEpochDate: ->
    return new Date(0)

  getDateMsOffset: (ms_offset, date) ->
    # Returns a new date offsetted ms_offset milliseconds from date
    # if date isn't provided, we'll use the current date

    if not date?
      date = new Date()

    date = new Date(date)

    date.setMilliseconds(date.getMilliseconds() + (ms_offset or 0))

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

  secondsToHumanReadable = (seconds) ->
    minutes_in_second = 60
    hours_in_second = 60 * minutes_in_second
    days_in_second = 24 * hours_in_second

    days = Math.floor(seconds / days_in_second)
    hours = Math.floor((seconds % days_in_second) / hours_in_second)
    minutes = Math.floor((seconds % hours_in_second) / minutes_in_second)
    remaining_seconds = seconds % minutes_in_second

    # Create strings to hold the formatted time
    day_str = if days > 0 then days + " day" + (if days > 1 then "s" else "") else ""
    hour_str = if hours > 0 then hours + " hour" + (if hours > 1 then "s" else "") else ""
    minute_str = if minutes > 0 then minutes + " minute" + (if minutes > 1 then "s" else "") else ""
    second_str = if remaining_seconds > 0 then remaining_seconds + " second" + (if remaining_seconds > 1 then "s" else "") else ""

    # Combine the formatted strings with commas and "and"
    time_array = [day_str, hour_str, minute_str, second_str].filter (str) -> str.length > 0
    if time_array.length is 0
      return "0 seconds"
    else if time_array.length is 1
      return time_array[0]
    else
      last_element = time_array.pop()
      joined_time = time_array.join(", ")
      return joined_time + " and " + last_element
