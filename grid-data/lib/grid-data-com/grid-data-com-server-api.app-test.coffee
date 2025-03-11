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

if Package["stem-capital:grid-data"]?
  {expect} = require "chai"

  describe "GridDataCom API", ->
    # Setup variables for tests
    perform_as = null
    project_id = null
    root_task_id = null
    child_task_id = null
    sibling_task_id = null

    before ->
      # Create a test user
      perform_as = Random.id()
      
      # Reset collections before each test
      APP.collections.Tasks.remove({})
      APP.collections.TasksPrivateData.remove({})
      APP.collections.Projects.remove({})

      return

    beforeEach ->
      # Create a test project first
      project = 
        title: "Test Project"
        timezone: "America/New_York"
        members: [
          {
            user_id: perform_as
            is_admin: true
          }
        ]
        conf: 
          custom_features: ["justdo_private_follow_up", "justdo_inbound_emails"]
      
      # Insert project into database
      project_id = APP.collections.Projects.insert(project)
      
      # Create a root task for testing
      root_task_fields = 
        title: "Root Task"
        project_id: project_id
        created_by_user_id: perform_as
        users: [perform_as]
      
      root_task_id = APP.projects._grid_data_com.addRootChild root_task_fields, perform_as
      
      return
    
    describe "addChild", ->
      it "should add a child to a parent task", ->
        # Prepare child task fields
        child_fields = 
          title: "Child Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        # Add child to root task
        path = "/#{root_task_id}/"
        child_id = APP.projects._grid_data_com.addChild path, child_fields, perform_as
        
        # Verify child was added
        child = APP.projects._grid_data_com.collection.findOne child_id
        
        expect(child).to.exist
        expect(child.title).to.equal "Child Task"
        expect(child.parents[root_task_id]).to.exist
        expect(child.users).to.include perform_as
        
        # Verify parents2 field is correctly set
        expect(child.parents2).to.exist
        expect(child.parents2[0].parent).to.equal root_task_id
        
        return
      
      it "should throw an error when path is invalid", ->
        invalid_path = "/invalid_id/"
        child_fields = 
          title: "Child Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        expect(->
          APP.projects._grid_data_com.addChild invalid_path, child_fields, perform_as
        ).to.throw()
        
        return
    
    describe "bulkAddChild", ->
      it "should add multiple children to a parent task", ->
        # Prepare child tasks fields
        children_fields = [
          {
            title: "Child Task 1"
            project_id: project_id
            created_by_user_id: perform_as
          },
          {
            title: "Child Task 2"
            project_id: project_id
            created_by_user_id: perform_as
          }
        ]
        
        # Add children to root task
        path = "/#{root_task_id}/"
        child_ids = APP.projects._grid_data_com.bulkAddChild path, children_fields, perform_as
        
        # Verify children were added
        expect(child_ids).to.have.length 2
        
        child1 = APP.projects._grid_data_com.collection.findOne child_ids[0]
        child2 = APP.projects._grid_data_com.collection.findOne child_ids[1]
        
        expect(child1.title).to.equal "Child Task 1"
        expect(child2.title).to.equal "Child Task 2"
        
        # Verify both children have the root task as parent
        expect(child1.parents[root_task_id]).to.exist
        expect(child2.parents[root_task_id]).to.exist
        
        return
    
    describe "addSibling", ->
      it "should add a sibling to an existing task", ->
        # First create a child to add sibling to
        child_fields = 
          title: "Child Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{root_task_id}/"
        child_id = APP.projects._grid_data_com.addChild path, child_fields, perform_as
        
        # Now add a sibling
        sibling_fields = 
          title: "Sibling Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        sibling_path = "/#{root_task_id}/#{child_id}/"
        sibling_id = APP.projects._grid_data_com.addSibling sibling_path, sibling_fields, perform_as
        
        # Verify sibling was added
        sibling = APP.projects._grid_data_com.collection.findOne sibling_id
        
        expect(sibling).to.exist
        expect(sibling.title).to.equal "Sibling Task"
        
        # Verify sibling has same parent as original child
        expect(sibling.parents[root_task_id]).to.exist
        
        # Verify sibling order is greater than child order
        child = APP.projects._grid_data_com.collection.findOne child_id
        expect(sibling.parents[root_task_id].order).to.be.above child.parents[root_task_id].order
        
        return
    
    describe "bulkAddSibling", ->
      it "should add multiple siblings to an existing task", ->
        # First create a child to add siblings to
        child_fields = 
          title: "Child Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{root_task_id}/"
        child_id = APP.projects._grid_data_com.addChild path, child_fields, perform_as

        # Now add siblings
        siblings_fields = [
          {
            title: "Sibling Task 1"
            project_id: project_id
            created_by_user_id: perform_as
          },
          {
            title: "Sibling Task 2"
            project_id: project_id
            created_by_user_id: perform_as
          }
        ]
        
        sibling_path = "/#{root_task_id}/#{child_id}/"
        sibling_ids = APP.projects._grid_data_com.bulkAddSibling sibling_path, siblings_fields, perform_as
        
        # Verify siblings were added
        expect(sibling_ids).to.have.length 2
        
        sibling1 = APP.projects._grid_data_com.collection.findOne sibling_ids[0]
        sibling2 = APP.projects._grid_data_com.collection.findOne sibling_ids[1]
        
        expect(sibling1.title).to.equal "Sibling Task 1"
        expect(sibling2.title).to.equal "Sibling Task 2"
        
        # Verify both siblings have the root task as parent
        expect(sibling1.parents[root_task_id]).to.exist
        expect(sibling2.parents[root_task_id]).to.exist
        
        # Verify siblings order is sequential
        expect(sibling2.parents[root_task_id].order).to.be.above sibling1.parents[root_task_id].order
        
        return
    
    describe "addParent", ->
      it "should add a new parent to an existing task", ->
        # Create two tasks to test with
        task1_fields = 
          title: "Task 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        task2_fields = 
          title: "Task 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        task1_id = APP.projects._grid_data_com.addRootChild task1_fields, perform_as
        task2_id = APP.projects._grid_data_com.addRootChild task2_fields, perform_as
        
        # Add task1 as parent to task2
        new_parent = 
          parent: task1_id
          order: 1
        
        APP.projects._grid_data_com.addParent task2_id, new_parent, perform_as
        
        # Verify task2 now has task1 as parent
        task2 = APP.projects._grid_data_com.collection.findOne task2_id
        
        expect(task2.parents[task1_id]).to.exist
        expect(task2.parents[task1_id].order).to.equal 1
        
        # Verify parents2 field is correctly set
        parent_in_parents2 = _.find task2.parents2, (p) -> p.parent is task1_id
        expect(parent_in_parents2).to.exist
        expect(parent_in_parents2.order).to.equal 1
        
        return
      
      it "should throw an error when trying to create a circular reference", ->
        # Create a parent-child relationship
        child_fields = 
          title: "Child Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{root_task_id}/"
        child_id = APP.projects._grid_data_com.addChild path, child_fields, perform_as
        
        # Try to add child as parent to root (should fail)
        new_parent = 
          parent: child_id
          order: 1
        
        expect(->
          APP.projects._grid_data_com.addParent root_task_id, new_parent, perform_as
        ).to.throw /infinite-loop/
        
        return
    
    describe "removeParent", ->
      it "should remove a parent from a task", ->
        # Create a task with two parents
        task_fields = 
          title: "Multi-parent Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        # Create two potential parent tasks
        parent1_fields = 
          title: "Parent 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent2_fields = 
          title: "Parent 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent1_id = APP.projects._grid_data_com.addRootChild parent1_fields, perform_as
        parent2_id = APP.projects._grid_data_com.addRootChild parent2_fields, perform_as
        
        # Add task as child of parent1
        path = "/#{parent1_id}/"
        task_id = APP.projects._grid_data_com.addChild path, task_fields, perform_as
        
        # Add parent2 as second parent
        new_parent = 
          parent: parent2_id
          order: 1
        
        APP.projects._grid_data_com.addParent task_id, new_parent, perform_as
        
        # Verify task has both parents
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task.parents[parent1_id]).to.exist
        expect(task.parents[parent2_id]).to.exist
        
        # Remove parent1
        path_to_remove = "/#{parent1_id}/#{task_id}/"
        APP.projects._grid_data_com.removeParent path_to_remove, perform_as
        
        # Verify parent1 is removed but parent2 remains
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task.parents[parent1_id]).to.not.exist
        expect(task.parents[parent2_id]).to.exist
        
        return
      
      it "should delete a task when removing its last parent", ->
        # Create a task with one parent
        task_fields = 
          title: "Single-parent Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{root_task_id}/"
        task_id = APP.projects._grid_data_com.addChild path, task_fields, perform_as
        
        # Remove the only parent
        path_to_remove = "/#{root_task_id}/#{task_id}/"
        APP.projects._grid_data_com.removeParent path_to_remove, perform_as
        
        # Verify task is marked as removed (not actually deleted)
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task._raw_removed_date).to.exist
        expect(task.users).to.be.empty
        
        return
    
    describe "bulkRemoveParents", ->
      it "should remove multiple parents at once", ->
        # Create a task with two parents
        task_fields = 
          title: "Multi-parent Task"
          project_id: project_id
          created_by_user_id: perform_as
        
        # Create two potential parent tasks
        parent1_fields = 
          title: "Parent 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent2_fields = 
          title: "Parent 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent1_id = APP.projects._grid_data_com.addRootChild parent1_fields, perform_as
        parent2_id = APP.projects._grid_data_com.addRootChild parent2_fields, perform_as
        
        # Add task as child of parent1
        path = "/#{parent1_id}/"
        task_id = APP.projects._grid_data_com.addChild path, task_fields, perform_as
        
        # Add parent2 as second parent
        new_parent = 
          parent: parent2_id
          order: 1
        
        APP.projects._grid_data_com.addParent task_id, new_parent, perform_as
        
        # Verify task has both parents
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task.parents[parent1_id]).to.exist
        expect(task.parents[parent2_id]).to.exist
        
        # Remove both parents
        paths_to_remove = [
          "/#{parent1_id}/#{task_id}/",
          "/#{parent2_id}/#{task_id}/"
        ]
        
        APP.projects._grid_data_com.bulkRemoveParents paths_to_remove, perform_as
        
        # Verify task is marked as removed (not actually deleted)
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task._raw_removed_date).to.exist
        expect(task.users).to.be.empty
        
        return
    
    describe "movePath", ->
      it "should move a task to a new parent", ->
        # Create two potential parent tasks
        parent1_fields = 
          title: "Parent 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent2_fields = 
          title: "Parent 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent1_id = APP.projects._grid_data_com.addRootChild parent1_fields, perform_as
        parent2_id = APP.projects._grid_data_com.addRootChild parent2_fields, perform_as
        
        # Add task as child of parent1
        task_fields = 
          title: "Task to move"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{parent1_id}/"
        task_id = APP.projects._grid_data_com.addChild path, task_fields, perform_as
        
        # Move task from parent1 to parent2
        path_to_move = "/#{parent1_id}/#{task_id}/"
        new_location = 
          parent: parent2_id
          order: 0
        
        APP.projects._grid_data_com.movePath path_to_move, new_location, perform_as
        
        # Verify task is now under parent2 and not under parent1
        task = APP.projects._grid_data_com.collection.findOne task_id
        expect(task.parents[parent1_id]).to.not.exist
        expect(task.parents[parent2_id]).to.exist
        expect(task.parents[parent2_id].order).to.equal 0
        
        return
      
      it "should move multiple tasks at once", ->
        # Create two potential parent tasks
        parent1_fields = 
          title: "Parent 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent2_fields = 
          title: "Parent 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        parent1_id = APP.projects._grid_data_com.addRootChild parent1_fields, perform_as
        parent2_id = APP.projects._grid_data_com.addRootChild parent2_fields, perform_as
        
        # Add two tasks as children of parent1
        task1_fields = 
          title: "Task 1 to move"
          project_id: project_id
          created_by_user_id: perform_as
        
        task2_fields = 
          title: "Task 2 to move"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{parent1_id}/"
        task1_id = APP.projects._grid_data_com.addChild path, task1_fields, perform_as
        task2_id = APP.projects._grid_data_com.addChild path, task2_fields, perform_as
        
        # Move both tasks from parent1 to parent2
        paths_to_move = [
          "/#{parent1_id}/#{task1_id}/",
          "/#{parent1_id}/#{task2_id}/"
        ]
        
        new_location = 
          parent: parent2_id
          order: 0
        
        APP.projects._grid_data_com.movePath paths_to_move, new_location, perform_as
        
        # Verify both tasks are now under parent2 and not under parent1
        task1 = APP.projects._grid_data_com.collection.findOne task1_id
        task2 = APP.projects._grid_data_com.collection.findOne task2_id
        
        expect(task1.parents[parent1_id]).to.not.exist
        expect(task1.parents[parent2_id]).to.exist
        
        expect(task2.parents[parent1_id]).to.not.exist
        expect(task2.parents[parent2_id]).to.exist
        
        # Verify tasks are ordered sequentially
        expect(task1.parents[parent2_id].order).to.equal 0
        expect(task2.parents[parent2_id].order).to.equal 1
        
        return
      
      it "should change the order of a task under the same parent", ->
        # Create three tasks under the root
        task1_fields = 
          title: "Task 1"
          project_id: project_id
          created_by_user_id: perform_as
        
        task2_fields = 
          title: "Task 2"
          project_id: project_id
          created_by_user_id: perform_as
        
        task3_fields = 
          title: "Task 3"
          project_id: project_id
          created_by_user_id: perform_as
        
        path = "/#{root_task_id}/"
        task1_id = APP.projects._grid_data_com.addChild path, task1_fields, perform_as
        task2_id = APP.projects._grid_data_com.addChild path, task2_fields, perform_as
        task3_id = APP.projects._grid_data_com.addChild path, task3_fields, perform_as
        
        # Move task1 to be after task3
        path_to_move = "/#{root_task_id}/#{task1_id}/"
        new_location = 
          order: 3
        
        APP.projects._grid_data_com.movePath path_to_move, new_location, perform_as
        
        # Verify the new order
        task1 = APP.projects._grid_data_com.collection.findOne task1_id
        task2 = APP.projects._grid_data_com.collection.findOne task2_id
        task3 = APP.projects._grid_data_com.collection.findOne task3_id
        
        expect(task2.parents[root_task_id].order).to.be.below task3.parents[root_task_id].order
        expect(task3.parents[root_task_id].order).to.be.below task1.parents[root_task_id].order
        
        return