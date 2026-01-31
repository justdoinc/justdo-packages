# TestFixtures - A modular test data seeding system
#
# This coordinator allows packages to register fixtures with dependencies,
# and test suites to explicitly request the fixtures they need.
#
# Usage:
#   # In a fixture file (e.g., your-package/tests/server/fixtures.app-test.coffee):
#   TestFixtures.register "your-feature",
#     dependencies: ["users", "projects"]
#     seed: ->
#       # Create test data...
#       return { item1, item2 }
#
#   # In a test file:
#   describe "My Tests", ->
#     before ->
#       TestFixtures.ensure("your-feature")
#     
#     it "should do something", ->
#       data = TestFixtures.get("your-feature")
#       # Use data.item1, data.item2...
#
# Features:
# - Dependency resolution (fixtures specify their dependencies)
# - Idempotent seeding (each fixture seeds only once per test run)
# - Circular dependency detection
# - Debug helpers for troubleshooting

TestFixtures =
  _registry: {}      # { id: { dependencies: [], seed: Function, seededData: null } }
  _seeded: {}        # { id: true/false } - tracks what's been seeded this run
  _seedOrder: []     # Tracks order in which fixtures were seeded (for debugging)
  _seeding: {}       # { id: true } - tracks fixtures currently being seeded (for circular detection)

  # Register a fixture
  # @param id [String] Unique identifier for the fixture
  # @param options [Object]
  #   - dependencies: [Array<String>] IDs of fixtures this one depends on
  #   - seed: [Function] Function that creates the test data, returns data object
  register: (id, options) ->
    if @_registry[id]?
      console.warn "[TestFixtures] Warning: Overwriting existing fixture: #{id}"
    
    @_registry[id] =
      dependencies: options.dependencies or []
      seed: options.seed
      seededData: null
    
    console.log "[TestFixtures] Registered fixture: #{id}"

  # Ensure a fixture (and its dependencies) are seeded
  # @param id [String] The fixture ID to ensure
  # @return [Object] The seeded data from the fixture
  ensure: (id) ->
    # Already seeded this run - return cached data
    return @_registry[id].seededData if @_seeded[id]
    
    fixture = @_registry[id]
    unless fixture?
      throw new Error("[TestFixtures] Unknown fixture: #{id}. Available: #{Object.keys(@_registry).join(', ')}")
    
    # Check for circular dependency
    if @_seeding[id]
      throw new Error("[TestFixtures] Circular dependency detected: #{id} is already being seeded")
    
    # Mark as currently seeding
    @_seeding[id] = true
    
    try
      # Recursively ensure dependencies first
      for depId in fixture.dependencies
        @ensure(depId)
      
      # Seed this fixture
      console.log "[TestFixtures] Seeding fixture: #{id}"
      startTime = Date.now()
      
      try
        fixture.seededData = fixture.seed()
      catch error
        console.error "[TestFixtures] Error seeding fixture '#{id}':", error
        throw error
      
      @_seeded[id] = true
      @_seedOrder.push(id)
      
      elapsed = Date.now() - startTime
      console.log "[TestFixtures] Seeded fixture: #{id} (#{elapsed}ms)"
      
      return fixture.seededData
    finally
      # Clear seeding flag
      delete @_seeding[id]

  # Get data from an already-seeded fixture
  # @param id [String] The fixture ID
  # @return [Object] The seeded data
  get: (id) ->
    unless @_seeded[id]
      throw new Error("[TestFixtures] Fixture not seeded: #{id}. Call TestFixtures.ensure('#{id}') first.")
    @_registry[id].seededData

  # Check if a fixture has been seeded
  # @param id [String] The fixture ID
  # @return [Boolean]
  isSeeded: (id) ->
    @_seeded[id] is true

  # Check if a fixture is registered
  # @param id [String] The fixture ID
  # @return [Boolean]
  isRegistered: (id) ->
    @_registry[id]?

  # Get list of all registered fixture IDs
  # @return [Array<String>]
  getRegisteredFixtures: ->
    Object.keys(@_registry)

  # Get list of seeded fixtures in order they were seeded
  # @return [Array<String>]
  getSeedOrder: ->
    @_seedOrder.slice() # Return copy

  # Get dependencies for a fixture
  # @param id [String] The fixture ID
  # @return [Array<String>] List of dependency IDs
  getDependencies: (id) ->
    fixture = @_registry[id]
    unless fixture?
      throw new Error("[TestFixtures] Unknown fixture: #{id}")
    fixture.dependencies.slice() # Return copy

  # Reset seeded state (useful for testing the fixture system itself)
  # Note: With METEOR_LOCAL_DIR reset, this is typically not needed
  reset: ->
    @_seeded = {}
    @_seedOrder = []
    @_seeding = {}
    for id, fixture of @_registry
      fixture.seededData = null
    console.log "[TestFixtures] Reset all fixture state"

  # Debug helper - print status of all fixtures
  debug: ->
    console.log "[TestFixtures] Status:"
    console.log "  Registered: #{Object.keys(@_registry).join(', ')}"
    console.log "  Seeded: #{Object.keys(@_seeded).filter((k) => @_seeded[k]).join(', ')}"
    console.log "  Seed order: #{@_seedOrder.join(' -> ')}"

# Make globally available
@TestFixtures = TestFixtures
