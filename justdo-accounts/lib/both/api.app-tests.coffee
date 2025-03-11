###
# TEMPLATE FOR CREATING NEW TEST FILES
#
# HOW TO CREATE NEW TEST CASES:
# 1. File naming: Name your test files with *.app-test.coffee or *.app-tests.coffee extension
#    - Files with these extensions will be automatically discovered and symlinked
#    - Files with path containing "server" or "client" will be symlinked into
#      corresponding directories, otherwise they will be symlinked into "both"
#
# 2. Place your test files:
#    - Put tests in the same directory as the code you're testing
#    - Our test system will:
#      a) Find these files and symlink them to app-tests directory
#      b) Create package-specific subdirectories (package-name/server, package-name/client, package-name/both)
#      c) Allow Meteor to run these tests via 'meteor test --full-app'
#
# 3. Structure your tests:
#    - Use 'describe' blocks to group related tests
#    - Use 'it' blocks for individual test cases
#    - Use 'before/beforeEach' for setup and 'after/afterEach' for cleanup
#    - Isolate tests by resetting collections in beforeEach
#
# 4. Recommended patterns:
#    - Check for package existence before defining tests (as shown below)
#    - Use unique IDs for test data to avoid conflicts
#    - Create helper functions for common setup/assertions
#    - Test both success cases and error cases

# Handling async operations (like APP.getEnv)
#  - In the callback of before/beforeEach, a "done" parameter is provided.
#    Call "done()" to signal that the async operation is complete.
#    E.g. In justdo-accounts, the getPasswordRequirements method
#    depends on the APP.getEnv method. If we run the test directly, on the client side it will fail.
#    So we need to call 
#    `before (done) -> APP.getEnv -> done()`
#    in the before block.
###

if Package["justdoinc:justdo-accounts"]?
  {expect} = require "chai"

  describe "JustdoAccounts API", ->
    before (done) ->
      APP.getEnv -> done()

    describe "_getAvatarUploadPath", ->
      it "should return the correct avatar upload path for a user", ->
        user_id = "user123"
        expected_path = "/accounts-avatars/#{user_id}/"
        path = APP.accounts._getAvatarUploadPath(user_id)
        expect(path).to.equal expected_path

    describe "_testAvatarUploadPath", ->
      it "should validate a correct avatar upload path", ->
        user_id = "user123"
        valid_path = "/accounts-avatars/user123/avatar.jpg"
        result = APP.accounts._testAvatarUploadPath(valid_path, user_id)
        expect(result).to.be.true

      it "should reject an invalid avatar upload path", ->
        user_id = "user123"
        invalid_path = "/wrong-path/user123/avatar.jpg"
        result = APP.accounts._testAvatarUploadPath(invalid_path, user_id)
        expect(result).to.be.false

    describe "password requirements", ->
      describe "getPasswordRequirements", ->
        it "should return an array of requirements", ->
          # We need to ensure _setupPasswordRequirements was called during initialization
          requirements = APP.accounts.getPasswordRequirements()
          expect(requirements).to.be.an("array")
          expect(requirements.length).to.be.at.least(1)
          
          # Check the structure of each requirement
          for req in requirements
            expect(req).to.have.property("code")
            expect(req).to.have.property("reason")
            expect(req).to.have.property("validate")
            expect(req.validate).to.be.a("function")
      
      describe "getUnconformedPasswordRequirements", ->
        it "should return issues for invalid passwords", ->
          # Test with a very weak password
          issues = APP.accounts.getUnconformedPasswordRequirements("weak")
          expect(issues).to.be.an("array")
          expect(issues.length).to.be.at.least(1)
        
        it "should return empty array for strong passwords", ->
          # Test with a strong password
          strong_password = "StrongP@ssw0rd"
          issues = APP.accounts.getUnconformedPasswordRequirements(strong_password)
          expect(issues).to.be.an("array")
          expect(issues.length).to.equal(0)
        
        it "should detect similarity with user inputs", ->
          email = "test.user@example.com"
          password = "testUser123!"
          issues = APP.accounts.getUnconformedPasswordRequirements(password, [email])
          expect(issues).to.include("too-similar")
      
      describe "passwordStrengthValidator", ->
        it "should return undefined for valid passwords", ->
          valid_password = "StrongP@ssw0rd"
          result = APP.accounts.passwordStrengthValidator(valid_password)
          expect(result).to.be.undefined
        
        it "should return error code and reason for invalid passwords", ->
          invalid_password = "weak"
          result = APP.accounts.passwordStrengthValidator(invalid_password)
          expect(result).to.be.an("object")
          expect(result).to.have.property("code")
          expect(result).to.have.property("reason")
          expect(result.reason).to.be.a("function")
    
    describe "isUserDeactivated", ->
      it "should return true for deactivated users", ->
        # Mock a deactivated user for this test
        user = {_id: "user123", deactivated: true}
        result = APP.accounts.isUserDeactivated(user)
        expect(result).to.be.true
      
      it "should return false for active users", ->
        # Mock an active user
        user = {_id: "user123", deactivated: false}
        result = APP.accounts.isUserDeactivated(user)
        expect(result).to.be.false
    
    describe "isProxyUser", ->
      it "should return true for proxy users", ->
        # Mock a proxy user
        user = {_id: "user123", is_proxy: true}
        result = APP.accounts.isProxyUser(user)
        expect(result).to.be.true
      
      it "should return false for non-proxy users", ->
        # Mock a non-proxy user
        user = {_id: "user123", is_proxy: false}
        result = APP.accounts.isProxyUser(user)
        expect(result).to.be.false 