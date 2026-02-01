# Projects Fixture
#
# Creates a standard test project with tasks for use in tests.
# This fixture depends on the "users" fixture.
#
# Available data after seeding:
#   - project: The test project document
#   - rootTask: A root-level task in the project
#
# Usage:
#   TestFixtures.ensure("projects")
#   { project, rootTask } = TestFixtures.get("projects")

# Only load chai in test mode
if Meteor.isTest or Meteor.isAppTest
  {expect} = require "chai"
else
  # Stub for non-test mode
  expect = -> { to: { exist: true, be: { a: -> } } }

TestFixtures.register "projects",
  dependencies: ["users"]
  seed: ->
    users = TestFixtures.get("users")
    
    # Create a test project owned by site admin
    project = createTestProject
      title: TEST_CONSTANTS.projects.defaultTitle
      owner_id: users.siteAdmin1._id
      members: [users.regularUser1._id, users.regularUser2._id]
      init_first_task: false
    
    expect(project._id).to.be.a "string"
    expect(project.title).to.equal TEST_CONSTANTS.projects.defaultTitle
    
    # Verify members were added
    memberIds = project.members.map (m) -> m.user_id
    expect(memberIds).to.include users.siteAdmin1._id
    expect(memberIds).to.include users.regularUser1._id
    expect(memberIds).to.include users.regularUser2._id
    
    # Create a root task
    rootTask = createTestTask
      project_id: project._id
      title: "Test Root Task"
      user_id: users.siteAdmin1._id
    
    expect(rootTask._id).to.be.a "string"
    expect(rootTask.title).to.equal "Test Root Task"
    
    TestLogger.log "[projects fixture]", "Created project '#{project.title}' with #{project.members.length} members and 1 task"
    
    return { project, rootTask }
