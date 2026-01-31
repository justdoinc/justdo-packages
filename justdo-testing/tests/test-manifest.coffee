# justdo-testing Test Manifest
#
# Meta! Tests for the testing infrastructure itself.
#
# Usage:
#   ./test-packages.bash justdo-testing

if Meteor.isServer
  TestManifest?.register "justdo-testing",
    configurations: [
      {
        id: "enabled"
        env: {}  # No special env vars needed
        mocha_tests: [
          "TestFixtures System"
          "TestManifest System"
          "TEST_CONSTANTS"
          "Test Helper Functions"
        ]
        cypress_tests: []  # No Cypress tests for the testing infrastructure
        primary: true
      }
    ]
    
    fixtures: []  # Self-tests don't use fixtures
    
    apps: ["web-app", "landing-app"]  # Available in both apps
