# justdo-testing

Test infrastructure package for JustDo applications.

## Overview

This package provides a unified testing infrastructure that works across both `justdo-web-app` and `justdo-landing-app`. It includes:

- **TestFixtures** - Modular test data seeding system with dependency resolution
- **TestManifest** - Package test configuration system for multi-config testing
- **TEST_CONSTANTS** - Shared test data constants for server and client tests
- **Helper functions** - Utilities for creating test users, projects, and tasks

## Installation

This package should be symlinked into both web-app and landing-app:

```bash
# In justdo-web-app/application/packages/
ln -s ../../modules/justdo-packages/justdo-testing justdo-testing

# In justdo-landing-app/application/packages/
ln -s ../../modules/justdo-packages/justdo-testing justdo-testing
```

Then add to `.meteor/packages`:

```
justdoinc:justdo-testing
```

## Usage

### TestFixtures

Register a fixture in your package:

```coffeescript
# your-package/tests/server/fixtures.app-test.coffee
if Package["justdoinc:your-package"]?
  TestFixtures.register "your-feature",
    dependencies: ["users", "projects"]
    seed: ->
      users = TestFixtures.get("users")
      { project } = TestFixtures.get("projects")
      
      # Create test data...
      myDoc = APP.yourPackage.createSomething
        owner_id: users.siteAdmin1._id
      
      return { myDoc }
```

Use in tests:

```coffeescript
describe "Your Feature", ->
  before (done) ->
    @timeout(10000)
    APP.getEnv ->
      TestFixtures.ensure("your-feature")
      done()
  
  it "should do something", ->
    { myDoc } = TestFixtures.get("your-feature")
    # Test with myDoc...
```

### TestManifest

Define test configurations for your package:

```coffeescript
# your-package/tests/test-manifest.coffee
if Meteor.isServer
  TestManifest.register "your-package",
    configurations: [
      {
        id: "enabled"
        env: { YOUR_FEATURE: "true" }
        tests: ["Your Feature Tests"]
        primary: true
      }
      {
        id: "disabled"
        env: { YOUR_FEATURE: "false" }
        tests: ["Your Feature Not Available"]
        isolation_only: true
      }
    ]
    fixtures: ["users", "your-feature"]
    apps: ["web-app"]
```

### TEST_CONSTANTS

Access test user credentials:

```coffeescript
email = TEST_CONSTANTS.users.siteAdmin1.email
password = TEST_CONSTANTS.users.siteAdmin1.password
```

## Available Fixtures

| Fixture  | Dependencies | Provides |
|----------|--------------|----------|
| users    | none         | siteAdmin1-3, regularUser1-3, proxyUser1-3 |
| projects | users        | project, rootTask |

## Test User Credentials

| Email Pattern | Type | Password |
|---------------|------|----------|
| test_site_admin_N@justdo.com | Site Admin | test_password |
| test_regular_user_N@justdo.com | Regular User | test_password |
| test_proxy_user_N@justdo.com | Proxy User | test_password |

Where N is 1, 2, or 3.

## API Reference

### TestFixtures

- `register(id, options)` - Register a fixture
- `ensure(id)` - Seed a fixture and its dependencies
- `get(id)` - Get data from a seeded fixture
- `isSeeded(id)` - Check if fixture is seeded
- `reset()` - Reset all fixture state
- `debug()` - Print fixture status

### TestManifest

- `register(packageId, manifest)` - Register a package manifest
- `getPackage(packageId)` - Get a package's manifest
- `getConfigurations(packageIds, options)` - Get merged configurations
- `mergeEnvVars(configs)` - Merge environment variables
- `getFixtures(packageIds)` - Get required fixtures

### Helper Functions

- `createOrGetUser(options)` - Create or get a user by email
- `createTestProject(options)` - Create a test project
- `createTestTask(options)` - Create a test task
- `runAsUser(userId, fn)` - Run code as a specific user
