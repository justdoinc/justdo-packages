TestCaseOptionsSchema = new SimpleSchema
  setUp: # setUp will get the test context as its first argument, it can modify the context as needed
    type: Function
    optional: true

  tearDown: # tearDown will get the test context as its first argument, it can modify the context as needed
    type: Function
    optional: true

TestCase = (name, options={}) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      TestCaseOptionsSchema,
      options,
      {throw_on_error: true}
    )
  @options = cleaned_val

  @tests = []

  @name = name

  return @

_.extend TestCase.prototype,
  testContextInvarient: {
    log: ->
      console.trace()

      return

    assert: (condition, failure_message) ->
      if not condition
        @failed += 1

        console.log("❌ Failed assertion: #{failure_message}")
        @log()

      return
    
    assertEqual: (expected, actual) ->
      @assert expected == actual, "Expected #{expected} to be equal to #{actual}"

      return
  }

  addTest: (name, test) ->
    @tests.push {name, test}

  getTestContext: ->
    context = Object.create(@testContextInvarient)

    context.failed = 0

    return context

  setUp: (context) ->
    if @options.setUp?
      @options.setUp(context)

    return

  tearDown: (context) ->
    if @options.tearDown?
      @options.tearDown(context)

    return

  run: ->
    failed = 0
    for {name, test} in @tests
      context = @getTestContext()

      @setUp(context)
      test.call(context)
      @tearDown(context)

      if context.failed == 0
        console.log("✅ Test `#{name}' passed")
      else
        console.log("❌ Test `#{name}' failed")
        failed += 1

    if failed == 0
      console.log("✅ `#{@name}`: #{@tests.length} tests passed")
    else
      console.log("❌ `#{@name}`: #{failed}/#{@tests.length} tests failed")

    return

_.extend JustdoHelpers,
  newTestCase: (name, options={}) ->
    return new TestCase(name, options)