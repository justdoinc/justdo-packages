# TEST_CONSTANTS - Shared test data constants
#
# These constants are used by test fixtures to create test users
# and by client-side tests to login as those users.
#
# This ensures test credentials are consistent across all test types.
#
# Usage:
#   TEST_CONSTANTS.users.siteAdmin1.email
#   TEST_CONSTANTS.users.siteAdmin1.password

TEST_CONSTANTS =
  # Test user definitions
  # These match the users created by the "users" fixture
  users:
    # Site Admin users (3 total)
    siteAdmin1:
      email: "test_site_admin_1@justdo.com"
      password: "test_password"
      type: "site_admin"
      profile:
        first_name: "Test"
        last_name: "Site Admin 1"
    siteAdmin2:
      email: "test_site_admin_2@justdo.com"
      password: "test_password"
      type: "site_admin"
      profile:
        first_name: "Test"
        last_name: "Site Admin 2"
    siteAdmin3:
      email: "test_site_admin_3@justdo.com"
      password: "test_password"
      type: "site_admin"
      profile:
        first_name: "Test"
        last_name: "Site Admin 3"
    
    # Regular users (3 total)
    regularUser1:
      email: "test_regular_user_1@justdo.com"
      password: "test_password"
      type: "regular"
      profile:
        first_name: "Test"
        last_name: "User 1"
    regularUser2:
      email: "test_regular_user_2@justdo.com"
      password: "test_password"
      type: "regular"
      profile:
        first_name: "Test"
        last_name: "User 2"
    regularUser3:
      email: "test_regular_user_3@justdo.com"
      password: "test_password"
      type: "regular"
      profile:
        first_name: "Test"
        last_name: "User 3"
    
    # Proxy users (3 total) - for impersonation testing
    proxyUser1:
      email: "test_proxy_user_1@justdo.com"
      password: "test_password"
      type: "proxy"
      profile:
        first_name: "Test"
        last_name: "Proxy User 1"
    proxyUser2:
      email: "test_proxy_user_2@justdo.com"
      password: "test_password"
      type: "proxy"
      profile:
        first_name: "Test"
        last_name: "Proxy User 2"
    proxyUser3:
      email: "test_proxy_user_3@justdo.com"
      password: "test_password"
      type: "proxy"
      profile:
        first_name: "Test"
        last_name: "Proxy User 3"
  
  # Default values
  defaults:
    password: "test_password"
    timezone: "America/New_York"
  
  # Project defaults
  projects:
    defaultTitle: "Test Project"

# Expose constants via a method for client tests to retrieve
if Meteor.isServer
  Meteor.methods
    "test.getConstants": ->
      # Only allow in test mode
      if not Meteor.isTest and not Meteor.isAppTest
        throw new Meteor.Error "not-in-test-mode", "test.getConstants only available in test mode"
      return TEST_CONSTANTS
