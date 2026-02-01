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
          "Client Login POC - Server Setup"
          "Client Login POC"
        ]
        primary: true
      }
    ]
    
    fixtures: []  # Self-tests don't use fixtures
    
    apps: ["web-app", "landing-app"]  # Available in both apps
