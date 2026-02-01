# TestManifest Self-Tests
#
# Tests the TestManifest coordinator functionality including:
# - Registration with mocha_tests fields
# - Configuration filtering
# - Env var merging
# - Fixture collection

{expect} = require "chai"

describe "TestManifest System", ->
  @timeout(10000)
  
  # Use a fresh registry for these tests
  originalRegistry = null
  
  before ->
    originalRegistry = TestManifest._registry
    TestManifest._registry = {}
  
  after ->
    TestManifest._registry = originalRegistry
  
  beforeEach ->
    TestManifest._registry = {}
  
  describe "register", ->
    it "should register a package manifest with mocha_tests", ->
      TestManifest.register "test-pkg",
        configurations: [
          { id: "basic", mocha_tests: ["Test Suite"], primary: true }
        ]
        fixtures: ["users"]
      
      expect(TestManifest.hasPackage("test-pkg")).to.be.true
      expect(TestManifest.getRegisteredPackages()).to.include "test-pkg"
    
    it "should register a package manifest with multiple test suites", ->
      TestManifest.register "multi-test-pkg",
        configurations: [
          {
            id: "basic"
            mocha_tests: ["Server Suite", "API Suite"]
            primary: true
          }
        ]
        fixtures: []
      
      manifest = TestManifest.getPackage("multi-test-pkg")
      config = manifest.configurations[0]
      expect(config.mocha_tests).to.deep.equal ["Server Suite", "API Suite"]
    
    it "should require at least one configuration", ->
      expect(->
        TestManifest.register "no-config",
          configurations: []
          fixtures: ["users"]
      ).to.throw(/at least one configuration/)
    
    it "should require configuration id", ->
      expect(->
        TestManifest.register "no-id",
          configurations: [
            { mocha_tests: ["Test Suite"] }  # Missing id
          ]
      ).to.throw(/missing required 'id' field/)
    
    it "should require at least one mocha_tests entry", ->
      expect(->
        TestManifest.register "no-tests",
          configurations: [
            { id: "basic", mocha_tests: [] }
          ]
      ).to.throw(/at least one mocha_tests entry/)
  
  describe "getPackage", ->
    it "should return the registered manifest", ->
      TestManifest.register "get-test",
        configurations: [
          { id: "enabled", mocha_tests: ["Tests"], primary: true }
        ]
        fixtures: ["users", "projects"]
        apps: ["web-app"]
      
      manifest = TestManifest.getPackage("get-test")
      expect(manifest.fixtures).to.deep.equal ["users", "projects"]
      expect(manifest.apps).to.deep.equal ["web-app"]
    
    it "should return undefined for unknown package", ->
      expect(TestManifest.getPackage("unknown")).to.be.undefined
  
  describe "getConfigurations", ->
    beforeEach ->
      TestManifest.register "pkg-a",
        configurations: [
          { id: "enabled", mocha_tests: ["A Tests"], primary: true }
          { id: "disabled", mocha_tests: ["A Disabled"], isolation_only: true }
        ]
        fixtures: ["users"]
      
      TestManifest.register "pkg-b",
        configurations: [
          { id: "full", mocha_tests: ["B Tests"], primary: true }
          { id: "minimal", mocha_tests: ["B Minimal"] }
        ]
        fixtures: ["projects"]
    
    it "should return all configurations by default", ->
      configs = TestManifest.getConfigurations(["pkg-a"])
      expect(configs.length).to.equal 1  # isolation_only excluded by default
      expect(configs[0].id).to.equal "enabled"
    
    it "should include isolation_only when requested", ->
      configs = TestManifest.getConfigurations(["pkg-a"], { includeIsolation: true })
      expect(configs.length).to.equal 2
      
      configIds = configs.map((c) -> c.id)
      expect(configIds).to.include "enabled"
      expect(configIds).to.include "disabled"
    
    it "should filter to primary only when requested", ->
      configs = TestManifest.getConfigurations(["pkg-b"], { primaryOnly: true })
      expect(configs.length).to.equal 1
      expect(configs[0].id).to.equal "full"
    
    it "should add packageId to each config", ->
      configs = TestManifest.getConfigurations(["pkg-a", "pkg-b"])
      
      for config in configs
        expect(config.packageId).to.exist
    
    it "should preserve mocha_tests in returned configs", ->
      configs = TestManifest.getConfigurations(["pkg-a"])
      expect(configs[0].mocha_tests).to.deep.equal ["A Tests"]
  
  describe "mergeEnvVars", ->
    it "should merge comma-separated env vars", ->
      configs = [
        { env: { BESPOKE_PACKS: "zim" } }
        { env: { BESPOKE_PACKS: "chat" } }
      ]
      
      result = TestManifest.mergeEnvVars(configs)
      
      # BESPOKE_PACKS should be merged
      expect(result.env.BESPOKE_PACKS).to.include "zim"
      expect(result.env.BESPOKE_PACKS).to.include "chat"
      expect(result.conflicts.length).to.equal 0
    
    it "should detect conflicts for non-mergeable vars", ->
      configs = [
        { env: { SOME_VAR: "value1" } }
        { env: { SOME_VAR: "value2" } }
      ]
      
      result = TestManifest.mergeEnvVars(configs)
      
      expect(result.conflicts.length).to.equal 1
      expect(result.conflicts[0].var).to.equal "SOME_VAR"
    
    it "should not report conflict for same values", ->
      configs = [
        { env: { SAME_VAR: "same" } }
        { env: { SAME_VAR: "same" } }
      ]
      
      result = TestManifest.mergeEnvVars(configs)
      
      expect(result.conflicts.length).to.equal 0
      expect(result.env.SAME_VAR).to.equal "same"
  
  describe "getFixtures (package-level, deprecated)", ->
    beforeEach ->
      TestManifest.register "fixture-pkg-1",
        configurations: [{ id: "test", mocha_tests: ["T"], primary: true }]
        fixtures: ["users", "projects"]
      
      TestManifest.register "fixture-pkg-2",
        configurations: [{ id: "test", mocha_tests: ["T"], primary: true }]
        fixtures: ["users", "custom"]  # users is duplicate
    
    it "should collect unique fixtures from packages", ->
      fixtures = TestManifest.getFixtures(["fixture-pkg-1", "fixture-pkg-2"])
      
      expect(fixtures).to.include "users"
      expect(fixtures).to.include "projects"
      expect(fixtures).to.include "custom"
      
      # Should not have duplicates
      userCount = fixtures.filter((f) -> f is "users").length
      expect(userCount).to.equal 1
  
  describe "getConfigurationFixtures", ->
    beforeEach ->
      TestManifest.register "config-fixture-pkg",
        configurations: [
          {
            id: "enabled"
            mocha_tests: ["Enabled Tests"]
            fixtures: ["users", "projects", "feature"]  # Config-specific
            primary: true
          }
          {
            id: "disabled"
            mocha_tests: ["Disabled Tests"]
            fixtures: ["users"]  # Minimal fixtures
            isolation_only: true
          }
        ]
      
      TestManifest.register "fallback-pkg",
        configurations: [
          { id: "test", mocha_tests: ["Tests"], primary: true }
          # No config-level fixtures
        ]
        fixtures: ["users", "projects"]  # Package-level fallback
    
    it "should return config-specific fixtures", ->
      fixtures = TestManifest.getConfigurationFixtures("config-fixture-pkg", "enabled")
      
      expect(fixtures).to.deep.equal ["users", "projects", "feature"]
    
    it "should return different fixtures for different configs", ->
      enabledFixtures = TestManifest.getConfigurationFixtures("config-fixture-pkg", "enabled")
      disabledFixtures = TestManifest.getConfigurationFixtures("config-fixture-pkg", "disabled")
      
      expect(enabledFixtures).to.deep.equal ["users", "projects", "feature"]
      expect(disabledFixtures).to.deep.equal ["users"]
    
    it "should fall back to package-level fixtures if config has none", ->
      fixtures = TestManifest.getConfigurationFixtures("fallback-pkg", "test")
      
      expect(fixtures).to.deep.equal ["users", "projects"]
    
    it "should return empty array for unknown package", ->
      fixtures = TestManifest.getConfigurationFixtures("unknown-pkg", "test")
      
      expect(fixtures).to.deep.equal []
    
    it "should return empty array for unknown config", ->
      fixtures = TestManifest.getConfigurationFixtures("config-fixture-pkg", "unknown")
      
      expect(fixtures).to.deep.equal []
    
    it "should return a copy, not the original array", ->
      fixtures1 = TestManifest.getConfigurationFixtures("config-fixture-pkg", "enabled")
      fixtures1.push("modified")
      
      fixtures2 = TestManifest.getConfigurationFixtures("config-fixture-pkg", "enabled")
      expect(fixtures2).to.not.include "modified"
  
  describe "getFixturesForConfigs", ->
    beforeEach ->
      TestManifest.register "multi-config-pkg",
        configurations: [
          {
            id: "enabled"
            mocha_tests: ["Tests"]
            fixtures: ["users", "feature-a"]
            primary: true
          }
          {
            id: "alternative"
            mocha_tests: ["Alt Tests"]
            fixtures: ["users", "feature-b"]
          }
        ]
    
    it "should collect unique fixtures from multiple configs", ->
      configs = [
        { packageId: "multi-config-pkg", id: "enabled" }
        { packageId: "multi-config-pkg", id: "alternative" }
      ]
      
      fixtures = TestManifest.getFixturesForConfigs(configs)
      
      expect(fixtures).to.include "users"
      expect(fixtures).to.include "feature-a"
      expect(fixtures).to.include "feature-b"
      
      # users should not be duplicated
      userCount = fixtures.filter((f) -> f is "users").length
      expect(userCount).to.equal 1
  
  describe "installation detection", ->
    it "should detect packages that require installation", ->
      TestManifest.register "needs-install",
        installation:
          apps: ["web-app"]
        configurations: [{ id: "test", mocha_tests: ["T"], primary: true }]
        fixtures: []
      
      TestManifest.register "no-install",
        configurations: [{ id: "test", mocha_tests: ["T"], primary: true }]
        fixtures: []
      
      expect(TestManifest.requiresInstallation("needs-install")).to.be.true
      expect(TestManifest.requiresInstallation("no-install")).to.be.false
    
    it "should return installation config", ->
      TestManifest.register "install-config",
        installation:
          apps: ["web-app", "landing-app"]
        configurations: [{ id: "test", mocha_tests: ["T"], primary: true }]
        fixtures: []
      
      install = TestManifest.getInstallation("install-config")
      expect(install.apps).to.deep.equal ["web-app", "landing-app"]
