# TestFixtures Self-Tests
#
# Tests the TestFixtures coordinator functionality including:
# - Registration
# - Dependency resolution
# - Idempotency
# - Circular dependency detection
# - Get/reset functionality

{expect} = require "chai"

describe "TestFixtures System", ->
  @timeout(10000)
  
  # Use a fresh registry for these tests
  originalRegistry = null
  originalSeeded = null
  originalSeedOrder = null
  
  before ->
    # Save original state
    originalRegistry = TestFixtures._registry
    originalSeeded = TestFixtures._seeded
    originalSeedOrder = TestFixtures._seedOrder
    
    # Reset for clean test
    TestFixtures._registry = {}
    TestFixtures._seeded = {}
    TestFixtures._seedOrder = []
  
  after ->
    # Restore original state
    TestFixtures._registry = originalRegistry
    TestFixtures._seeded = originalSeeded
    TestFixtures._seedOrder = originalSeedOrder
  
  beforeEach ->
    # Reset between tests
    TestFixtures._registry = {}
    TestFixtures._seeded = {}
    TestFixtures._seedOrder = []
  
  describe "register", ->
    it "should register a fixture", ->
      TestFixtures.register "test-fixture",
        dependencies: []
        seed: -> { value: 42 }
      
      expect(TestFixtures.isRegistered("test-fixture")).to.be.true
      expect(TestFixtures.getRegisteredFixtures()).to.include "test-fixture"
    
    it "should allow overwriting a fixture with warning", ->
      TestFixtures.register "overwrite-test",
        dependencies: []
        seed: -> { first: true }
      
      # Register again - should warn but succeed
      TestFixtures.register "overwrite-test",
        dependencies: []
        seed: -> { second: true }
      
      # Seed and check it's the second version
      TestFixtures.ensure("overwrite-test")
      expect(TestFixtures.get("overwrite-test").second).to.be.true
  
  describe "ensure", ->
    it "should seed a fixture and return its data", ->
      TestFixtures.register "seed-test",
        dependencies: []
        seed: -> { value: "seeded" }
      
      result = TestFixtures.ensure("seed-test")
      expect(result.value).to.equal "seeded"
    
    it "should be idempotent - seed only once", ->
      seedCount = 0
      
      TestFixtures.register "idempotent-test",
        dependencies: []
        seed: ->
          seedCount++
          { count: seedCount }
      
      # Call ensure multiple times
      TestFixtures.ensure("idempotent-test")
      TestFixtures.ensure("idempotent-test")
      TestFixtures.ensure("idempotent-test")
      
      # Should only have seeded once
      expect(seedCount).to.equal 1
      expect(TestFixtures.get("idempotent-test").count).to.equal 1
    
    it "should throw error for unknown fixture", ->
      expect(->
        TestFixtures.ensure("nonexistent")
      ).to.throw(/Unknown fixture/)
  
  describe "dependency resolution", ->
    it "should seed dependencies first", ->
      seedOrder = []
      
      TestFixtures.register "dep-parent",
        dependencies: ["dep-child"]
        seed: ->
          seedOrder.push("parent")
          { name: "parent" }
      
      TestFixtures.register "dep-child",
        dependencies: []
        seed: ->
          seedOrder.push("child")
          { name: "child" }
      
      TestFixtures.ensure("dep-parent")
      
      expect(seedOrder).to.deep.equal ["child", "parent"]
    
    it "should handle multi-level dependencies", ->
      seedOrder = []
      
      TestFixtures.register "level-3",
        dependencies: ["level-2"]
        seed: ->
          seedOrder.push("3")
          {}
      
      TestFixtures.register "level-2",
        dependencies: ["level-1"]
        seed: ->
          seedOrder.push("2")
          {}
      
      TestFixtures.register "level-1",
        dependencies: []
        seed: ->
          seedOrder.push("1")
          {}
      
      TestFixtures.ensure("level-3")
      
      expect(seedOrder).to.deep.equal ["1", "2", "3"]
    
    it "should detect circular dependencies", ->
      TestFixtures.register "circular-a",
        dependencies: ["circular-b"]
        seed: -> {}
      
      TestFixtures.register "circular-b",
        dependencies: ["circular-a"]
        seed: -> {}
      
      expect(->
        TestFixtures.ensure("circular-a")
      ).to.throw(/Circular dependency/)
  
  describe "get", ->
    it "should return seeded data", ->
      TestFixtures.register "get-test",
        dependencies: []
        seed: -> { key: "value" }
      
      TestFixtures.ensure("get-test")
      
      result = TestFixtures.get("get-test")
      expect(result.key).to.equal "value"
    
    it "should throw if fixture not seeded", ->
      TestFixtures.register "unseeded-test",
        dependencies: []
        seed: -> {}
      
      expect(->
        TestFixtures.get("unseeded-test")
      ).to.throw(/Fixture not seeded/)
  
  describe "reset", ->
    it "should clear all seeded state", ->
      TestFixtures.register "reset-test",
        dependencies: []
        seed: -> { value: 1 }
      
      TestFixtures.ensure("reset-test")
      expect(TestFixtures.isSeeded("reset-test")).to.be.true
      
      TestFixtures.reset()
      expect(TestFixtures.isSeeded("reset-test")).to.be.false
  
  describe "getSeedOrder", ->
    it "should track order of seeding", ->
      TestFixtures.register "order-a",
        dependencies: []
        seed: -> {}
      
      TestFixtures.register "order-b",
        dependencies: ["order-a"]
        seed: -> {}
      
      TestFixtures.ensure("order-b")
      
      order = TestFixtures.getSeedOrder()
      expect(order).to.deep.equal ["order-a", "order-b"]
