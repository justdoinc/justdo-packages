# Users Fixture
#
# Creates standard test users for use in tests.
# This fixture has no dependencies.
#
# Uses TEST_CONSTANTS to ensure consistency between:
# - Server-side fixtures (this file)
# - Client-side tests (via Meteor method)
#
# Available users after seeding:
#   - siteAdmin1, siteAdmin2, siteAdmin3: Site admin users
#   - regularUser1, regularUser2, regularUser3: Regular users
#   - proxyUser1, proxyUser2, proxyUser3: Proxy users (for impersonation testing)
#
# Usage:
#   TestFixtures.ensure("users")
#   users = TestFixtures.get("users")
#   # Use users.siteAdmin1, users.regularUser1, etc.

# Only load chai in test mode
if Meteor.isTest or Meteor.isAppTest
  {expect} = require "chai"
else
  # Stub for non-test mode
  expect = -> { to: { exist: true, be: { a: -> } } }

TestFixtures.register "users",
  dependencies: []
  seed: ->
    users = {}
    
    # Create users from TEST_CONSTANTS
    for userKey, userData of TEST_CONSTANTS.users
      isSiteAdmin = userData.type is "site_admin"
      isProxy = userData.type is "proxy"
      
      users[userKey] = createOrGetUser
        email: userData.email
        profile: userData.profile
        isSiteAdmin: isSiteAdmin
        isProxy: isProxy
      
      # Verify the user was created correctly
      expect(users[userKey]._id).to.be.a "string",
        "User #{userKey} should have an _id"
      
      # Verify site admin status if applicable
      if isSiteAdmin
        expect(users[userKey].site_admin?.is_site_admin).to.equal true,
          "User #{userKey} should have site_admin.is_site_admin = true"
    
    console.log "[users fixture] Created #{Object.keys(users).length} test users"
    
    return users
