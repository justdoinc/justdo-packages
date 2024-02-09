_.extend JustdoHelpers,
  # Code taken from lodash@4.17.21 https://github.com/lodash/lodash/blob/4.17.21/lodash.js#L5476
  roundNumber: (number, precision) ->
    if _.isString number
      number = +number
    check number, Number
    precision = parseInt precision, 10 # Ensure precision is an integer
    check precision, Number
    
    precision = if precision == null then 0 else Math.min(precision, 292)
    if precision and isFinite(number)
      # Shift with exponential notation to avoid floating-point issues.
      # See [MDN](https://mdn.io/round#Examples) for more details.
      pair = "#{number}e".split("e")
      value = Math.round "#{pair[0]}e#{+pair[1] + precision}"
      pair = "#{value}e".split("e")
      return +"#{pair[0]}e#{+pair[1] - precision}"

    return Math.round number
