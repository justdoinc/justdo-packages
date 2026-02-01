# Client Login POC - Server Setup
# @package justdo-testing
# @config enabled
#
# Server-side setup for client login tests.
# Fixtures listed in the manifest (users) are auto-seeded before tests run.
#
# Run with:
#   ./test-packages.bash justdo-testing

{expect} = require "chai"

describe "Client Login POC - Server Setup", ->
  before TestFixtures.beforeHook()
  
  it "should have test users available", ->
    users = TestFixtures.get("users")
    expect(users.regularUser1).to.exist
    expect(users.regularUser1._id).to.be.a "string"
