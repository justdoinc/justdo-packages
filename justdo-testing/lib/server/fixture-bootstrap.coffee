# fixture-bootstrap.coffee
# Auto-seeds fixtures based on TEST_FIXTURES environment variable
#
# This runs at server startup (in test mode) and seeds all fixtures
# specified in the current configuration's manifest.
#
# The test runner passes TEST_FIXTURES as a comma-separated list of fixture IDs.
# Example: TEST_FIXTURES="users,projects,zim"
#
# HOW IT WORKS:
# 1. Creates a dedicated Barriers instance for fixture synchronization
# 2. At Meteor.startup, seeds all fixtures from TEST_FIXTURES
# 3. Marks barrier as resolved when seeding completes (or fails)
# 4. Tests use TestFixtures.beforeHook() to wait for seeding
#
# FAIL-FAST: If seeding fails, the error is stored and barrier is resolved
# immediately. Tests receive the error and fail with a clear message.

if Meteor.isServer and (Meteor.isTest or Meteor.isAppTest)
  BARRIER_ID = "test-fixtures-seeded"
  DEFAULT_TIMEOUT = 120000  # 2 minutes - allows for heavy fixture seeding (10k+ records)
  
  # Create dedicated barriers instance for fixtures (not shared with hooks_barriers)
  TestFixtures._barriers = new JustdoHelpers.Barriers
    missing_barrier_timeout: DEFAULT_TIMEOUT
  
  # Track seeding state for fail-fast
  TestFixtures._seedingError = null
  TestFixtures._seedingComplete = false
  
  # Get TEST_FIXTURES from environment
  _testFixtureIds = []
  testFixtures = process.env.TEST_FIXTURES
  
  if testFixtures?.length > 0
    _testFixtureIds = testFixtures.split(',').map((f) -> f.trim()).filter((f) -> f.length > 0)
  
  if _testFixtureIds.length > 0
    TestLogger.log "[TestFixtures]", "Auto-seeding #{_testFixtureIds.length} fixture(s): #{_testFixtureIds.join(', ')}"
    
    Meteor.startup ->
      APP.getEnv ->
        startTime = Date.now()
        seededCount = 0
        skippedCount = 0
        
        try
          for fixtureId, index in _testFixtureIds
            stepNum = index + 1
            
            if TestFixtures.isRegistered(fixtureId)
              TestLogger.log "[TestFixtures]", "(#{stepNum}/#{_testFixtureIds.length}) Seeding '#{fixtureId}'..."
              fixtureStart = Date.now()
              TestFixtures.ensure(fixtureId)
              duration = Date.now() - fixtureStart
              TestLogger.log "[TestFixtures]", "(#{stepNum}/#{_testFixtureIds.length}) ✓ '#{fixtureId}' seeded (#{duration}ms)"
              seededCount++
            else
              TestLogger.warn "[TestFixtures]", "(#{stepNum}/#{_testFixtureIds.length}) ⚠ '#{fixtureId}' not registered, skipping"
              skippedCount++
          
          totalDuration = Date.now() - startTime
          TestLogger.log "[TestFixtures]", "Auto-seeding complete - Seeded: #{seededCount}, Skipped: #{skippedCount}, Total: #{totalDuration}ms"
          
          TestFixtures._seedingComplete = true
          TestFixtures._barriers.markBarrierAsResolved(BARRIER_ID)
        catch err
          # FAIL-FAST: Store error and resolve barrier immediately
          totalDuration = Date.now() - startTime
          TestLogger.error "[TestFixtures]", "Auto-seeding FAILED after #{totalDuration}ms (#{seededCount}/#{_testFixtureIds.length} seeded)"
          TestLogger.error "[TestFixtures]", "Error: #{err.message}"
          
          TestFixtures._seedingError = err
          TestFixtures._seedingComplete = true
          TestFixtures._barriers.markBarrierAsResolved(BARRIER_ID)  # Resolve, not reject
  else
    # No fixtures to seed - mark complete immediately
    Meteor.startup ->
      TestFixtures._seedingComplete = true
      TestFixtures._barriers.markBarrierAsResolved(BARRIER_ID)
