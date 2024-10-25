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

  # Taken from https://github.com/compute-io/dot/blob/master/lib/index.js
  arrayDotProduct: (x, y) ->
    if (not _.isArray x) or (not _.isArray y)
      throw new Meteor.Error "invalid-argument", "arrayDotProduct: Both args must be arrays"
    
    if _.size(x) isnt _.size(y)
      throw new Meteor.Error "invalid-argument", "arrayDotProduct: Both array must be of equal length"

    sum = 0

    for num_x, i in x
      num_y = y[i]
      sum += num_x * num_y

    return sum
  
  # Taken from https://github.com/compute-io/l2norm/blob/master/lib/index.js
  arrayL2Norm: (arr) ->
    if not _.isArray arr
      throw new Meteor.Error "invalid-argument", "arrayL2Norm: Argument must be an array"

    t = 0
    s = 1
    r = null

    i = 0
    for val in arr
      abs = Math.abs val
      if abs > t
        r = t / val
        s = 1 + s * r * r
        t = abs
      else
        r = val / t
        s = s + r * r
  
    return t * Math.sqrt s
  
  # Taken from https://github.com/compute-io/cosine-similarity/blob/master/lib/index.js
  cosineSimilarity: (x, y) ->
    if (not _.isArray x) or (not _.isArray y)
      throw new Meteor.Error "invalid-argument", "cosineSimilarity: Both args must be arrays"

    if _.size(x) isnt _.size(y)
      throw new Meteor.Error "invalid-argument", "arrayDotProduct: Both array must be of equal length"

    a = @arrayDotProduct x, y
    b = @arrayL2Norm x
    c = @arrayL2Norm y

    return a / (b * c)

