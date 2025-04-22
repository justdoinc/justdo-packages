###
# Test cases for JustdoDeliveryPlanner's project collections hierarchy functions:
# - getParentProjectsCollectionsGroupedByDepth
# - isProjectsCollectionDepthLteMaxDepth
# - requireProjectsCollectionDepthLteMaxDepth
###

if Package["justdoinc:justdo-delivery-planner"]? and Meteor.isServer
  {expect, assert} = require "chai"
  
  describe "JustdoDeliveryPlanner - Project Collections Hierarchy", ->
    # Test variables
    test_user_id = "test_user_id"
    test_justdo_id = null
    
    # Test documents IDs
    pc1_id = null # Project Collection Level 1
    pc2_id = null # Project Collection Level 2
    pc3_id = null # Project Collection Level 3
    project_id = null # Project (not a collection)
    task_id = null # Regular task
    
    # Complex hierarchy IDs - with regular task breaking the chain
    regular_task_id = null # Regular task under pc3
    pc4_id = null # Project Collection under regular task
    pc5_id = null # Project Collection under pc4
    pc6_id = null # Project Collection under pc5
    pj2_id = null # Project under pc6
    
    # Setup the environment before running tests
    before (done) ->
      APP.getEnv ->
        # Create a test project using Projects API
        project_doc = 
          title: "Test Project"
          timezone: "America/New_York"
          members: [{user_id: test_user_id, is_admin: true}]
          conf: {custom_features: ["delivery_planner"]}
          
        test_justdo_id = APP.collections.Projects.insert(project_doc)
        done()
    
    # Before each test, set up the test data
    beforeEach ->
      # Clean up test data from previous tests
      if pc1_id?
        APP.collections.Tasks.remove({_id: pc1_id})
      if pc2_id?
        APP.collections.Tasks.remove({_id: pc2_id})
      if pc3_id?
        APP.collections.Tasks.remove({_id: pc3_id})
      if project_id?
        APP.collections.Tasks.remove({_id: project_id})
      if task_id?
        APP.collections.Tasks.remove({_id: task_id})
      if regular_task_id?
        APP.collections.Tasks.remove({_id: regular_task_id})
      if pc4_id?
        APP.collections.Tasks.remove({_id: pc4_id})
      if pc5_id?
        APP.collections.Tasks.remove({_id: pc5_id})
      if pc6_id?
        APP.collections.Tasks.remove({_id: pc6_id})
      if pj2_id?
        APP.collections.Tasks.remove({_id: pj2_id})
      
      # Create the test hierarchical structure:
      # PC1 -> PC2 -> PC3 -> Project -> Task
      
      # Level 1 Project Collection - create as root task
      pc1_fields = 
        title: "Project Collection 1"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      pc1_id = APP.projects._grid_data_com.addRootChild(pc1_fields, test_user_id)
      
      # Level 2 Project Collection - create as child of PC1
      pc2_fields = 
        title: "Project Collection 2"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      # Make sure to use proper path format with leading and trailing slashes
      pc2_id = APP.projects._grid_data_com.addChild("/#{pc1_id}/", pc2_fields, test_user_id)
      
      # Level 3 Project Collection - create as child of PC2
      pc3_fields = 
        title: "Project Collection 3"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      pc3_id = APP.projects._grid_data_com.addChild("/#{pc2_id}/", pc3_fields, test_user_id)
      
      # Project (not a collection) - create as child of PC3
      project_fields = 
        title: "Test Project"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "is_project": true
      
      project_id = APP.projects._grid_data_com.addChild("/#{pc3_id}/", project_fields, test_user_id)
      
      # Regular task - create as child of Project
      task_fields = 
        title: "Test Task"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
      
      task_id = APP.projects._grid_data_com.addChild("/#{project_id}/", task_fields, test_user_id)
      
      # Create complex hierarchy with regular task breaking the chain
      # PC1 -> PC2 -> PC3 -> regular_task -> PC4 -> PC5 -> PC6 -> pj2
      
      # Regular task under PC3
      regular_task_fields = 
        title: "Regular Task Breaking Chain"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
      
      regular_task_id = APP.projects._grid_data_com.addChild("/#{pc3_id}/", regular_task_fields, test_user_id)
      
      # Verify the task was created
      if not APP.collections.Tasks.findOne(regular_task_id)?
        throw new Error("Failed to create regular task")
      
      # PC4 under regular task
      pc4_fields = 
        title: "Project Collection 4"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      pc4_id = APP.projects._grid_data_com.addChild("/#{regular_task_id}/", pc4_fields, test_user_id)
      
      # Verify PC4 was created
      if not APP.collections.Tasks.findOne(pc4_id)?
        throw new Error("Failed to create PC4")
      
      # PC5 under PC4
      pc5_fields = 
        title: "Project Collection 5"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      pc5_id = APP.projects._grid_data_com.addChild("/#{pc4_id}/", pc5_fields, test_user_id)
      
      # Verify PC5 was created
      if not APP.collections.Tasks.findOne(pc5_id)?
        throw new Error("Failed to create PC5")
      
      # PC6 under PC5
      pc6_fields = 
        title: "Project Collection 6"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "projects_collection": {
          "projects_collection_type": "program",
          "is_closed": false
        }
      
      pc6_id = APP.projects._grid_data_com.addChild("/#{pc5_id}/", pc6_fields, test_user_id)
      
      # Verify PC6 was created
      if not APP.collections.Tasks.findOne(pc6_id)?
        throw new Error("Failed to create PC6")
      
      # Project 2 under PC6
      pj2_fields = 
        title: "Test Project 2"
        project_id: test_justdo_id
        created_by_user_id: test_user_id
        "is_project": true
      
      pj2_id = APP.projects._grid_data_com.addChild("/#{pc6_id}/", pj2_fields, test_user_id)
      
      # Verify PJ2 was created
      if not APP.collections.Tasks.findOne(pj2_id)?
        throw new Error("Failed to create PJ2")
    
    # Clean up after all tests
    after ->
      # Remove test data
      if pc1_id?
        APP.collections.Tasks.remove({_id: pc1_id})
      if pc2_id?
        APP.collections.Tasks.remove({_id: pc2_id})
      if pc3_id?
        APP.collections.Tasks.remove({_id: pc3_id})
      if project_id?
        APP.collections.Tasks.remove({_id: project_id})
      if task_id?
        APP.collections.Tasks.remove({_id: task_id})
      if regular_task_id?
        APP.collections.Tasks.remove({_id: regular_task_id})
      if pc4_id?
        APP.collections.Tasks.remove({_id: pc4_id})
      if pc5_id?
        APP.collections.Tasks.remove({_id: pc5_id})
      if pc6_id?
        APP.collections.Tasks.remove({_id: pc6_id})
      if pj2_id?
        APP.collections.Tasks.remove({_id: pj2_id})
      
      # Remove test project
      if test_justdo_id?
        APP.collections.Projects.remove({_id: test_justdo_id})
    
    describe "getParentProjectsCollectionsGroupedByDepth", ->
      it "should return parent collections grouped by depth for a project", ->
        # Get parent collections for the project
        result = APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({
          task: project_id
        })
        
        # Verify the result
        expect(result).to.be.an("array")
        expect(result.length).to.equal(3) # Three levels of project collections
        
        # Level 1 (immediate parent): PC3
        expect(result[0]).to.be.an("array")
        expect(result[0].length).to.equal(1)
        expect(result[0][0]._id).to.equal(pc3_id)
        
        # Level 2 (parent of PC3): PC2
        expect(result[1]).to.be.an("array")
        expect(result[1].length).to.equal(1)
        expect(result[1][0]._id).to.equal(pc2_id)
        
        # Level 3 (parent of PC2): PC1
        expect(result[2]).to.be.an("array")
        expect(result[2].length).to.equal(1)
        expect(result[2][0]._id).to.equal(pc1_id)
        
        return
        
      it "should return parent collections grouped by depth for a task", ->
        # Tasks doesn't belong directly to project collections
        result = APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({
          task: task_id
        })
        
        # Verify the result is empty as tasks aren't directly in project collections
        expect(result).to.be.an("array")
        expect(result.length).to.equal(0)
        
        return
        
      it "should return parent collections with forced parent IDs", ->
        # Test with forced parent IDs
        result = APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({
          forced_parent_ids: [pc2_id, pc1_id]
        })
        
        # Verify the result
        expect(result).to.be.an("array")
        expect(result.length).to.equal(2) # Two levels of project collections
        
        # Level 1 (immediate parent): PC2 and PC1
        expect(result[0]).to.be.an("array")
        expect(result[0].length).to.equal(2)
        expect(result[0][0]._id).to.equal(pc2_id)
        expect(result[0][1]._id).to.equal(pc1_id)
        
        # Level 2 (parent of PC2): PC1
        expect(result[1]).to.be.an("array")
        expect(result[1].length).to.equal(1)
        expect(result[1][0]._id).to.equal(pc1_id)
        
        return
        
      it "should return specific fields when fields option is provided", ->
        # Get parent collections with specific fields
        result = APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({
          task: project_id,
          fields: {
            _id: 1,
            title: 1
          }
        })
        
        # Verify the result
        expect(result).to.be.an("array")
        expect(result.length).to.equal(3)
        
        # Check that each document has only the requested fields
        for level in result
          for doc in level
            expect(doc).to.have.property("_id")
            expect(doc).to.have.property("title")
            expect(doc).to.have.property("parents") # Required for hierarchy traversal
            expect(doc).to.have.property("projects_collection") # Required for verification
            expect(doc).to.not.have.property("users") # Not requested
        
        return
        
      it "should throw an error if no task or forced_parent_ids are provided", ->
        try
          APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({})
          assert.fail("Expected to throw")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal("missing-argument")
        
        return

      it "should not include project collections with non-collection parent in hierarchy", ->
        # Verify all tasks were created successfully
        expect(APP.collections.Tasks.findOne(pj2_id)).to.exist
        expect(APP.collections.Tasks.findOne(pc6_id)).to.exist
        expect(APP.collections.Tasks.findOne(pc5_id)).to.exist
        expect(APP.collections.Tasks.findOne(pc4_id)).to.exist
        expect(APP.collections.Tasks.findOne(regular_task_id)).to.exist
        
        # Get parent collections for project 2
        # The hierarchy is:
        # PC1 -> PC2 -> PC3 -> regular_task -> PC4 -> PC5 -> PC6 -> pj2
        # But since regular_task breaks the chain, we should only see PC4, PC5, PC6
        result = APP.justdo_delivery_planner.getParentProjectsCollectionsGroupedByDepth({
          task: pj2_id
        })
        
        # Verify the result
        expect(result).to.be.an("array")
        expect(result.length).to.equal(3) # Only three levels of project collections (PC4, PC5, PC6)
        
        # Level 1 (immediate parent): PC6
        expect(result[0]).to.be.an("array")
        expect(result[0].length).to.equal(1)
        expect(result[0][0]._id).to.equal(pc6_id)
        
        # Level 2 (parent of PC6): PC5
        expect(result[1]).to.be.an("array")
        expect(result[1].length).to.equal(1)
        expect(result[1][0]._id).to.equal(pc5_id)
        
        # Level 3 (parent of PC5): PC4
        expect(result[2]).to.be.an("array")
        expect(result[2].length).to.equal(1)
        expect(result[2][0]._id).to.equal(pc4_id)
        
        # Verify PC1, PC2, PC3 are not in the results
        all_collections = result[0].concat(result[1], result[2])
        all_ids = all_collections.map((item) -> item._id)
        expect(all_ids).to.not.include(pc1_id)
        expect(all_ids).to.not.include(pc2_id)
        expect(all_ids).to.not.include(pc3_id)
        
        return
    
    describe "isProjectsCollectionDepthLteMaxDepth", ->
      it "should return true if depth is less than max depth", ->
        # Project -> PC3 -> PC2 -> PC1 (depth 3)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          task: project_id
        }, 4)
        
        expect(result).to.be.true
        
        return
        
      it "should return true if depth is equal to max depth", ->
        # Project -> PC3 -> PC2 -> PC1 (depth 3)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          task: project_id
        }, 3)
        
        expect(result).to.be.true
        
        return
        
      it "should return false if depth is greater than max depth", ->
        # Project -> PC3 -> PC2 -> PC1 (depth 3)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          task: project_id
        }, 2)
        
        expect(result).to.be.false
        
        return
        
      it "should work with forced parent IDs", ->
        # PC2 -> PC1 (depth 2)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          forced_parent_ids: [pc2_id]
        }, 2)
        
        expect(result).to.be.true
        
        # PC2 -> PC1 (depth 2)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          forced_parent_ids: [pc2_id]
        }, 1)
        
        expect(result).to.be.false
        
        return

      it "should correctly count depth when chain is broken by regular task", ->
        # pj2 -> PC6 -> PC5 -> PC4 (depth 3)
        # PC1, PC2, PC3 should not be counted because of regular_task breaking the chain
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          task: pj2_id
        }, 3)
        
        expect(result).to.be.true
        
        # Test with a max depth of 2 (should fail)
        result = APP.justdo_delivery_planner.isProjectsCollectionDepthLteMaxDepth({
          task: pj2_id
        }, 2)
        
        expect(result).to.be.false
        
        return
    
    describe "requireProjectsCollectionDepthLteMaxDepth", ->
      it "should return true if depth is within the limit", ->
        # Project -> PC3 -> PC2 -> PC1 (depth 3)
        result = APP.justdo_delivery_planner.requireProjectsCollectionDepthLteMaxDepth({
          task: project_id
        }, 3)
        
        expect(result).to.be.true
        
        return
        
      it "should throw an error if depth exceeds the limit", ->
        try
          # Project -> PC3 -> PC2 -> PC1 (depth 3)
          APP.justdo_delivery_planner.requireProjectsCollectionDepthLteMaxDepth({
            task: project_id
          }, 2)
          
          assert.fail("Expected to throw")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal("not-supported")
          expect(error.reason).to.include("Cannot nest projects collections beyond 2 level(s)")
        
        return
        
      it "should work with forced parent IDs", ->
        try
          # PC2 -> PC1 (depth 2)
          APP.justdo_delivery_planner.requireProjectsCollectionDepthLteMaxDepth({
            forced_parent_ids: [pc2_id]
          }, 1)
          
          assert.fail("Expected to throw")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal("not-supported")
        
        return

      it "should correctly enforce depth limits when chain is broken by regular task", ->
        # pj2 -> PC6 -> PC5 -> PC4 (depth 3)
        # PC1, PC2, PC3 should not be counted because of regular_task breaking the chain
        result = APP.justdo_delivery_planner.requireProjectsCollectionDepthLteMaxDepth({
          task: pj2_id
        }, 3)
        
        expect(result).to.be.true
        
        # Test with a max depth of 2 (should throw error)
        try
          APP.justdo_delivery_planner.requireProjectsCollectionDepthLteMaxDepth({
            task: pj2_id
          }, 2)
          
          assert.fail("Expected to throw")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal("not-supported")
          expect(error.reason).to.include("Cannot nest projects collections beyond 2 level(s)")
        
        return 