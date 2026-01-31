# TEST_CONSTANTS Self-Tests
#
# Tests that TEST_CONSTANTS is properly defined with all required
# user types and valid data.

{expect} = require "chai"

describe "TEST_CONSTANTS", ->
  @timeout(5000)
  
  describe "structure", ->
    it "should be defined", ->
      expect(TEST_CONSTANTS).to.exist
    
    it "should have users object", ->
      expect(TEST_CONSTANTS.users).to.exist
      expect(TEST_CONSTANTS.users).to.be.an "object"
    
    it "should have defaults object", ->
      expect(TEST_CONSTANTS.defaults).to.exist
      expect(TEST_CONSTANTS.defaults.password).to.exist
      expect(TEST_CONSTANTS.defaults.timezone).to.exist
    
    it "should have projects object", ->
      expect(TEST_CONSTANTS.projects).to.exist
      expect(TEST_CONSTANTS.projects.defaultTitle).to.exist
  
  describe "users", ->
    describe "site admins", ->
      it "should have 3 site admin users", ->
        expect(TEST_CONSTANTS.users.siteAdmin1).to.exist
        expect(TEST_CONSTANTS.users.siteAdmin2).to.exist
        expect(TEST_CONSTANTS.users.siteAdmin3).to.exist
      
      it "should have valid site admin data", ->
        for key in ["siteAdmin1", "siteAdmin2", "siteAdmin3"]
          user = TEST_CONSTANTS.users[key]
          expect(user.email).to.match /@justdo\.com$/
          expect(user.password).to.exist
          expect(user.type).to.equal "site_admin"
          expect(user.profile.first_name).to.exist
          expect(user.profile.last_name).to.exist
    
    describe "regular users", ->
      it "should have 3 regular users", ->
        expect(TEST_CONSTANTS.users.regularUser1).to.exist
        expect(TEST_CONSTANTS.users.regularUser2).to.exist
        expect(TEST_CONSTANTS.users.regularUser3).to.exist
      
      it "should have valid regular user data", ->
        for key in ["regularUser1", "regularUser2", "regularUser3"]
          user = TEST_CONSTANTS.users[key]
          expect(user.email).to.match /@justdo\.com$/
          expect(user.password).to.exist
          expect(user.type).to.equal "regular"
          expect(user.profile.first_name).to.exist
          expect(user.profile.last_name).to.exist
    
    describe "proxy users", ->
      it "should have 3 proxy users", ->
        expect(TEST_CONSTANTS.users.proxyUser1).to.exist
        expect(TEST_CONSTANTS.users.proxyUser2).to.exist
        expect(TEST_CONSTANTS.users.proxyUser3).to.exist
      
      it "should have valid proxy user data", ->
        for key in ["proxyUser1", "proxyUser2", "proxyUser3"]
          user = TEST_CONSTANTS.users[key]
          expect(user.email).to.match /@justdo\.com$/
          expect(user.password).to.exist
          expect(user.type).to.equal "proxy"
          expect(user.profile.first_name).to.exist
          expect(user.profile.last_name).to.exist
  
  describe "email uniqueness", ->
    it "should have unique email addresses for all users", ->
      emails = []
      
      for key, user of TEST_CONSTANTS.users
        expect(emails).to.not.include user.email,
          "Duplicate email found: #{user.email}"
        emails.push(user.email)
  
  describe "server method", ->
    it "should expose test.getConstants method in test mode", ->
      # This test verifies the method exists
      # The method should throw if called outside test mode
      expect(Meteor.server.method_handlers["test.getConstants"]).to.exist
