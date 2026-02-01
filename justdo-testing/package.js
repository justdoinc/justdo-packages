Package.describe({
  name: 'justdoinc:justdo-testing',
  version: '1.0.0',
  summary: 'Test infrastructure for JustDo applications',
  git: '',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom(['1.8.1', '2.3', '3.0']);
  api.use('coffeescript');
  api.use('ecmascript');
  api.use('underscore');
  
  // Dependencies for test helpers
  api.use('accounts-base', 'server', {weak: true});
  api.use('justdoinc:justdo-helpers@1.0.0', 'server');  // Required for Barriers (fixture auto-seeding)
  api.use('justdoinc:justdo-site-admins@1.0.0', 'server', {weak: true});
  api.use('justdoinc:justdo-accounts@1.0.0', 'server', {weak: true});
  api.use('justdoinc:justdo-projects@1.0.0', 'server', {weak: true});
  
  // Shared constants (available to both server and client)
  api.addFiles([
    'lib/both/test-constants.coffee'
  ], ['client', 'server']);
  
  // Server-side test infrastructure
  // Load order is controlled by the array order below
  api.addFiles([
    'lib/server/test-fixtures.coffee',
    'lib/server/test-manifest.coffee',
    'lib/server/mergeable-vars.coffee',
    'lib/server/helpers.coffee',
    'lib/server/users-fixture.coffee',
    'lib/server/projects-fixture.coffee',
    'lib/server/fixture-bootstrap.coffee'  // Must be last - auto-seeds fixtures from TEST_FIXTURES env var
  ], 'server');
  
  // Export for use in tests
  api.export('TEST_CONSTANTS');
  api.export('TestFixtures', 'server');
  api.export('TestManifest', 'server');
  
  // Export helper functions
  api.export('createOrGetUser', 'server');
  api.export('createTestProject', 'server');
  api.export('createTestTask', 'server');
  api.export('runAsUser', 'server');
  api.export('getCurrentTestUserId', 'server');
});
