# Client Login POC - Client Tests
# @package justdo-testing
# @config enabled
#
# Client-side login/logout tests using Puppeteer.
# Tests basic authentication flow from the browser.
#
# Run with:
#   ./test-packages.bash justdo-testing

{expect} = require "chai"

describe "Client Login POC", ->
  @timeout(30000)  # Longer timeout for client tests
  
  it "should start logged out", ->
    expect(Meteor.userId()).to.be.null
  
  it "should login successfully", (done) ->
    Meteor.loginWithPassword "test_regular_user_1@justdo.com", "test_password", (err) ->
      if err
        done(err)
        return
      
      expect(Meteor.userId()).to.exist
      expect(Meteor.userId()).to.be.a "string"
      console.log "[Client POC] Logged in as:", Meteor.userId()
      done()
    return
  
  it "should have user data after login", ->
    user = Meteor.user()
    expect(user).to.exist
    expect(user.emails).to.be.an "array"
    expect(user.emails[0].address).to.equal "test_regular_user_1@justdo.com"
  
  it "should logout successfully", (done) ->
    Meteor.logout (err) ->
      if err
        done(err)
        return
      
      expect(Meteor.userId()).to.be.null
      console.log "[Client POC] Logged out successfully"
      done()
    return
  
  it "should be logged out after logout", ->
    expect(Meteor.userId()).to.be.null
    expect(Meteor.user()).to.be.null
