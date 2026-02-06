# justdo-testing Test Manifest
#
# Meta! Tests for the testing infrastructure itself.
#
# Usage:
#   ./test-packages.bash justdo-testing

TestManifest?.register "justdo-testing",
  configurations: [
    {
      id: "enabled"
      env: {}  # No special env vars needed
      mocha_tests: [
        "TestFixtures System"
        "TestFixtures.beforeHook"
        "TestManifest System"
        "TEST_CONSTANTS"
        "Test Helper Functions"
        "Client Login POC - Server Setup"
        "Client Login POC"
      ]
      fixtures: ["users"]  # Needed for Client Login POC tests
      primary: true
    }
  ]
  
  apps: ["web-app", "landing-app"]  # Available in both apps
