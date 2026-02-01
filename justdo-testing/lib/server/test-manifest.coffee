# TestManifest - Package test configuration coordinator
#
# Allows packages to declare their test configurations, including:
# - Required environment variables
# - Mocha test suites to run (filtered via MOCHA_GREP)
# - Fixtures to seed (can be per-configuration or package-level)
# - Installation requirements (for non-symlinked packages)
#
# Usage:
#   # In your-package/tests/test-manifest.coffee:
#   TestManifest.register "your-package",
#     configurations: [
#       {
#         id: "enabled"
#         env: { YOUR_FEATURE: "true" }
#         mocha_tests: ["Your Feature Tests"]
#         fixtures: ["users", "projects", "your-feature"]  # Config-specific fixtures
#         primary: true
#       }
#       {
#         id: "disabled"
#         env: { YOUR_FEATURE: "false" }
#         mocha_tests: ["Your Feature Not Available"]
#         fixtures: ["users"]  # Minimal fixtures for disabled tests
#         isolation_only: true
#       }
#     ]
#     fixtures: ["users"]  # Optional: fallback for configs without fixtures
#
# Fixture resolution:
# - If a configuration has a `fixtures` array, use those fixtures
# - Otherwise, fall back to package-level `fixtures` array
# - This allows different test configurations to seed different data
#
# The test runner reads these manifests to:
# - Determine which env vars to set
# - Filter Mocha tests via MOCHA_GREP
# - Know which fixtures to seed for each configuration
# - Handle package installation if needed

TestManifest =
  _registry: {}  # { packageId: manifest }

  # Register a package's test manifest
  # @param packageId [String] Unique identifier (usually package folder name)
  # @param manifest [Object]
  #   - configurations: [Array<Object>] List of test configurations
  #     - id: [String] Configuration ID
  #     - env: [Object] Environment variables to set
  #     - mocha_tests: [Array<String>] Mocha test suite names
  #     - primary: [Boolean] Include when testing with other packages
  #     - isolation_only: [Boolean] Only run when testing this package alone
  #   - fixtures: [Array<String>] Fixture IDs to ensure before tests
  #   - apps: [Array<String>] Which apps have this package ("web-app", "landing-app")
  #   - installation: [Object] For non-symlinked packages
  #     - apps: [Array<String>] Which apps to install to for testing
  register: (packageId, manifest) ->
    if @_registry[packageId]?
      console.warn "[TestManifest] Warning: Overwriting existing manifest: #{packageId}"
    
    # Validate manifest structure
    unless manifest.configurations?.length > 0
      throw new Error("[TestManifest] Package '#{packageId}' must have at least one configuration")
    
    for config in manifest.configurations
      unless config.id?
        throw new Error("[TestManifest] Configuration in '#{packageId}' missing required 'id' field")
      
      # Validate test fields - require mocha_tests
      unless config.mocha_tests?.length > 0
        throw new Error("[TestManifest] Configuration '#{config.id}' in '#{packageId}' must have at least one mocha_tests entry")
    
    @_registry[packageId] = manifest
    console.log "[TestManifest] Registered manifest: #{packageId} (#{manifest.configurations.length} configs)"

  # Get a package's manifest
  # @param packageId [String] The package ID
  # @return [Object] The manifest
  getPackage: (packageId) ->
    @_registry[packageId]

  # Check if a package has a manifest registered
  # @param packageId [String] The package ID
  # @return [Boolean]
  hasPackage: (packageId) ->
    @_registry[packageId]?

  # Get all registered package IDs
  # @return [Array<String>]
  getRegisteredPackages: ->
    Object.keys(@_registry)

  # Get configurations for a set of packages
  # @param packageIds [Array<String>] Package IDs to get configs for
  # @param options [Object]
  #   - primaryOnly: [Boolean] Only return primary configs (default: false)
  #   - includeIsolation: [Boolean] Include isolation_only configs (default: false)
  # @return [Array<Object>] List of configuration objects with packageId added
  getConfigurations: (packageIds, options = {}) ->
    configs = []
    
    for packageId in packageIds
      manifest = @_registry[packageId]
      unless manifest?
        console.warn "[TestManifest] Unknown package: #{packageId}"
        continue
      
      for config in manifest.configurations
        # Skip isolation_only unless explicitly requested
        if config.isolation_only and not options.includeIsolation
          continue
        
        # Skip non-primary when primaryOnly is set
        if options.primaryOnly and not config.primary
          continue
        
        configs.push _.extend({}, config, {packageId})
    
    configs

  # Get merged env vars for a set of configurations
  # @param configs [Array<Object>] Configurations to merge
  # @return [Object] { env: {merged vars}, conflicts: [{var, values}] }
  mergeEnvVars: (configs) ->
    merged = {}
    conflicts = []
    
    for config in configs
      for key, value of (config.env or {})
        if merged[key]?
          # Check if we can merge this var
          if MERGEABLE_ENV_VARS[key]?
            merged[key] = MERGEABLE_ENV_VARS[key].merge(merged[key], value)
          else if merged[key] isnt value
            # Non-mergeable conflict
            conflicts.push {var: key, values: [merged[key], value], packages: []}
        else
          merged[key] = value
    
    {env: merged, conflicts}

  # Get fixtures required for a set of packages (package-level fallback)
  # @param packageIds [Array<String>] Package IDs
  # @return [Array<String>] Unique fixture IDs
  # @deprecated Use getConfigurationFixtures for config-specific fixtures
  getFixtures: (packageIds) ->
    fixtures = []
    
    for packageId in packageIds
      manifest = @_registry[packageId]
      continue unless manifest?
      
      for fixture in (manifest.fixtures or [])
        fixtures.push(fixture) unless fixture in fixtures
    
    fixtures

  # Get fixtures for a specific configuration
  # @param packageId [String] Package ID
  # @param configId [String] Configuration ID
  # @return [Array<String>] Fixture IDs for this configuration
  getConfigurationFixtures: (packageId, configId) ->
    manifest = @_registry[packageId]
    return [] unless manifest?
    
    # Find the specific configuration
    config = null
    for c in (manifest.configurations or [])
      if c.id is configId
        config = c
        break
    
    return [] unless config?
    
    # Use config-level fixtures if specified, otherwise fall back to package-level
    if config.fixtures?
      return config.fixtures.slice()  # Return copy
    else
      return (manifest.fixtures or []).slice()  # Fall back to package-level

  # Get fixtures for multiple configurations (merges unique fixtures)
  # @param configs [Array<Object>] Configurations with packageId
  # @return [Array<String>] Unique fixture IDs
  getFixturesForConfigs: (configs) ->
    fixtures = []
    
    for config in configs
      configFixtures = @getConfigurationFixtures(config.packageId, config.id)
      for fixture in configFixtures
        fixtures.push(fixture) unless fixture in fixtures
    
    fixtures

  # Check if a package requires dynamic installation
  # @param packageId [String] The package ID
  # @return [Boolean]
  requiresInstallation: (packageId) ->
    manifest = @_registry[packageId]
    manifest?.installation?

  # Get installation info for a package
  # @param packageId [String] The package ID
  # @return [Object] Installation config or null
  getInstallation: (packageId) ->
    @_registry[packageId]?.installation

  # Debug helper
  debug: ->
    console.log "[TestManifest] Registered packages:"
    for packageId, manifest of @_registry
      configIds = manifest.configurations.map((c) -> c.id).join(", ")
      console.log "  #{packageId}: #{configIds}"

# Make globally available
@TestManifest = TestManifest
