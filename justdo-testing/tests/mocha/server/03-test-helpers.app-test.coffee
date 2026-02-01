# Test Helpers Self-Tests
#
# Tests the helper functions:
# - createOrGetUser
# - createTestProject
# - createTestTask
# - runAsUser

{expect} = require "chai"

describe "Test Helper Functions", ->
  @timeout(15000)
  
  before (done) ->
    APP.getEnv ->
      done()
    return
  
  describe "createOrGetUser", ->
    it "should require email parameter", ->
      expect(->
        createOrGetUser({})
      ).to.throw(/email is required/)
    
    it "should create a new user", ->
      email = "test_helper_user_#{Date.now()}@justdo.com"
      
      user = createOrGetUser
        email: email
        profile:
          first_name: "Helper"
          last_name: "Test"
      
      expect(user._id).to.be.a "string"
      expect(user.emails[0].address).to.equal email
      
      # Cleanup
      Meteor.users.remove(user._id)
    
    it "should return existing user if email exists", ->
      email = "test_existing_#{Date.now()}@justdo.com"
      
      # Create first
      user1 = createOrGetUser
        email: email
        profile:
          first_name: "First"
          last_name: "Create"
      
      # Get existing
      user2 = createOrGetUser
        email: email
        profile:
          first_name: "Second"
          last_name: "Attempt"
      
      expect(user1._id).to.equal user2._id
      
      # Cleanup
      Meteor.users.remove(user1._id)
    
    it "should create site admin when isSiteAdmin is true", ->
      email = "test_admin_#{Date.now()}@justdo.com"
      
      user = createOrGetUser
        email: email
        isSiteAdmin: true
        profile:
          first_name: "Admin"
          last_name: "Test"
      
      expect(user.site_admin?.is_site_admin).to.be.true
      
      # Cleanup
      Meteor.users.remove(user._id)
  
  describe "createTestProject", ->
    testUserId = null
    
    before ->
      # Create a test user for project creation
      user = createOrGetUser
        email: "test_project_owner_#{Date.now()}@justdo.com"
        isSiteAdmin: true
        profile:
          first_name: "Project"
          last_name: "Owner"
      testUserId = user._id
    
    after ->
      if testUserId?
        Meteor.users.remove(testUserId)
    
    it "should require owner_id parameter", ->
      expect(->
        createTestProject({})
      ).to.throw(/owner_id is required/)
    
    it "should create a project with default title", ->
      return @skip() unless APP.projects?
      
      project = createTestProject
        owner_id: testUserId
      
      expect(project._id).to.be.a "string"
      expect(project.title).to.equal TEST_CONSTANTS.projects.defaultTitle
      
      # Cleanup
      APP.projects.projects_collection.remove(project._id)
    
    it "should create a project with custom title", ->
      return @skip() unless APP.projects?
      
      project = createTestProject
        owner_id: testUserId
        title: "Custom Test Project"
      
      expect(project.title).to.equal "Custom Test Project"
      
      # Cleanup
      APP.projects.projects_collection.remove(project._id)
  
  describe "createTestTask", ->
    it "should require project_id, title, and user_id", ->
      expect(->
        createTestTask({})
      ).to.throw(/project_id is required/)
      
      expect(->
        createTestTask({ project_id: "123" })
      ).to.throw(/title is required/)
      
      expect(->
        createTestTask({ project_id: "123", title: "Task" })
      ).to.throw(/user_id is required/)
  
  describe "runAsUser", ->
    it "should set current test user ID", ->
      testId = "test-user-123"
      
      runAsUser testId, ->
        expect(getCurrentTestUserId()).to.equal testId
    
    it "should clear user ID after execution", ->
      runAsUser "temp-user", -> null
      
      expect(getCurrentTestUserId()).to.be.null
    
    it "should clear user ID even on error", ->
      try
        runAsUser "error-user", ->
          throw new Error("Test error")
      catch e
        # Expected
      
      expect(getCurrentTestUserId()).to.be.null
    
    it "should return function result", ->
      result = runAsUser "some-user", ->
        return { value: 42 }
      
      expect(result.value).to.equal 42
