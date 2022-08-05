PointedLimitedStack = (options) ->
  @pointer = -1
  @stack = []
  @size = options?.size or 10

  return @

_.extend PointedLimitedStack.prototype,
  push: (hash) ->
    if @pointer != (@stack.length - 1) # If @pointer is not in the tip remove everything after it.
      @stack = @stack.slice(0, @pointer + 1)

    @stack.push hash
    @pointer += 1

    if @stack.length > @size
      @stack.shift()
      @pointer -= 1

    return

  replaceHead: (hash) ->
    @stack[@pointer] = hash

    return

  matchBackwardAndResetHeadIfFound: (hash) ->
    for i in [@stack.length - 1..0]
      if @stack[i] == hash
        @pointer = i

        return true

    return false

  getStack: ->
    return @stack

  getStackPointer: ->
    return @pointer

  getStackHead: ->
    return @stack[@pointer]

JustdoHelpers.PointedLimitedStack = PointedLimitedStack