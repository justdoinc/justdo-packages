# Client Login POC - Server Setup
# @package justdo-testing
# @config enabled
#
# Server-side setup for client login tests.
# Ensures test users are seeded before client tests run.
#
# Run with:
#   ./test-packages.bash justdo-testing

{expect} = require "chai"

describe "Client Login POC - Server Setup", ->
  @timeout(10000)
  
  before (done) ->
    APP.getEnv ->
      TestFixtures.ensure("users")
      done()
    return
  
  it "should have test users available", ->
    users = TestFixtures.get("users")
    expect(users.regularUser1).to.exist
    expect(users.regularUser1._id).to.be.a "string"
