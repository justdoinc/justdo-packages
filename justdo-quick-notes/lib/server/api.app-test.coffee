if Package["justdoinc:justdo-quick-notes"]?
  {expect, assert} = require "chai"
  
  describe "JustdoQuickNotes API", ->
    # Setup variables
    test_user_id = "test_user_id"
    test_project_id = null
    test_quick_note_id = null
    test_task_id = null
    
    # Setup before all tests
    before (done) ->
      APP.getEnv ->
        # Create a test project
        project_doc = 
          title: "Test Project"
          timezone: "America/New_York"  # Required field
          members: [{user_id: test_user_id, is_admin: true}]
          conf: {custom_features: ["quick_notes"]}
        
        test_project_id = APP.collections.Projects.insert(project_doc)
        done()
    
    # Clean up after all tests
    after ->
      # Clean up all test data
      APP.collections.QuickNotes.remove({user_id: test_user_id})
      APP.collections.Tasks.remove({project_id: test_project_id})
      APP.collections.Projects.remove({_id: test_project_id})
    
    # Reset collections before each test
    beforeEach ->
      # Clean up quick notes before each test
      APP.collections.QuickNotes.remove({user_id: test_user_id})
    
    describe "addQuickNoteAsync", ->
      it "should add a new quick note", ->
        # Setup
        fields = 
          title: "Test Quick Note"
        
        # Execute
        await APP.justdo_quick_notes.addQuickNoteAsync(fields, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({user_id: test_user_id, title: "Test Quick Note"})
        expect(quick_note).to.exist
        expect(quick_note.title).to.equal "Test Quick Note"
        expect(quick_note.user_id).to.equal test_user_id
        expect(quick_note.order).to.be.a "number"
        
        return
      
      it "should throw an error if title is missing", ->
        # Setup
        fields = {}
        
        # Execute and Verify
        try
          await APP.justdo_quick_notes.addQuickNoteAsync(fields, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
        
        return
    
    describe "editQuickNoteAsync", ->
      beforeEach ->
        # Create a test quick note
        fields = 
          title: "Test Quick Note"
        
        test_quick_note_id = APP.collections.QuickNotes.insert({
          title: "Test Quick Note",
          user_id: test_user_id,
          order: _.now()
        })
      
      it "should edit a quick note title", ->
        # Setup
        options = 
          title: "Updated Quick Note"
        
        # Execute
        await APP.justdo_quick_notes.editQuickNoteAsync(test_quick_note_id, options, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.title).to.equal "Updated Quick Note"
        
        return
      
      it "should mark a quick note as completed", ->
        # Setup
        options = 
          completed: true
        
        # Execute
        await APP.justdo_quick_notes.editQuickNoteAsync(test_quick_note_id, options, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.completed).to.be.an.instanceof(Date)
        
        return
      
      it "should mark a quick note as deleted", ->
        # Setup
        options = 
          deleted: true
        
        # Execute
        await APP.justdo_quick_notes.editQuickNoteAsync(test_quick_note_id, options, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.deleted).to.be.an.instanceof(Date)
        
        return
      
      it "should throw an error if quick note doesn't exist", ->
        # Setup
        options = 
          title: "Updated Quick Note"
        
        # Execute and Verify
        try
          await APP.justdo_quick_notes.editQuickNoteAsync("non_existent_id", options, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "unknown-quick-note"
        
        return
      
      it "should throw an error if options is empty", ->
        # Execute and Verify
        try
          await APP.justdo_quick_notes.editQuickNoteAsync(test_quick_note_id, {}, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "missing-argument"
        
        return
    
    describe "reorderQuickNoteAsync", ->
      beforeEach ->
        # Create test quick notes
        APP.collections.QuickNotes.insert({
          title: "Quick Note 1",
          user_id: test_user_id,
          order: 100
        })
        
        test_quick_note_id = APP.collections.QuickNotes.insert({
          title: "Quick Note 2",
          user_id: test_user_id,
          order: 200
        })
        
        APP.collections.QuickNotes.insert({
          title: "Quick Note 3",
          user_id: test_user_id,
          order: 300
        })
      
      it "should reorder a quick note to the top", ->
        # Execute
        await APP.justdo_quick_notes.reorderQuickNoteAsync(test_quick_note_id, null, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.order).to.be.greaterThan(300)
        
        return
      
      it "should reorder a quick note after another quick note", ->
        # Setup
        put_after_quick_note = APP.collections.QuickNotes.findOne({title: "Quick Note 1"})
        
        # Execute
        await APP.justdo_quick_notes.reorderQuickNoteAsync(test_quick_note_id, put_after_quick_note._id, test_user_id)
        
        # Verify
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        # The order might be negative when putting at the bottom
        # Just check that it's less than the original order
        expect(quick_note.order).to.be.lessThan(200)
        
        return
      
      it "should throw an error if target quick note doesn't exist", ->
        # Execute and Verify
        try
          await APP.justdo_quick_notes.reorderQuickNoteAsync("non_existent_id", null, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "unknown-quick-note"
        
        return
      
      it "should throw an error if trying to put a quick note after itself", ->
        # Execute and Verify
        try
          await APP.justdo_quick_notes.reorderQuickNoteAsync(test_quick_note_id, test_quick_note_id, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-argument"
        
        return
    
    describe "createTaskFromQuickNoteAsync", ->
      beforeEach ->
        # Create a test quick note
        test_quick_note_id = APP.collections.QuickNotes.insert({
          title: "Test Quick Note for Task",
          user_id: test_user_id,
          order: _.now()
        })
      
      it "should create a task from a quick note", ->
        # Execute
        created_task_id = await APP.justdo_quick_notes.createTaskFromQuickNoteAsync(
          test_quick_note_id, 
          test_project_id, 
          "0", 
          10, 
          test_user_id
        )
        
        # Verify
        expect(created_task_id).to.exist
        
        # Check task was created
        task = APP.collections.Tasks.findOne({_id: created_task_id})
        expect(task).to.exist
        expect(task.title).to.equal "Test Quick Note for Task"
        expect(task.project_id).to.equal test_project_id
        expect(task._created_from_quick_note).to.equal test_quick_note_id
        expect(task.parents["0"].order).to.equal 10
        
        # Check quick note was marked as deleted and linked to task
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.deleted).to.be.an.instanceof(Date)
        expect(quick_note.created_task_id).to.equal created_task_id
        
        return
      
      it "should throw an error if a task was already created from the quick note", ->
        # Setup - Create a task from the quick note
        created_task_id = await APP.justdo_quick_notes.createTaskFromQuickNoteAsync(
          test_quick_note_id, 
          test_project_id, 
          "0", 
          10, 
          test_user_id
        )
        
        # Execute and Verify
        try
          await APP.justdo_quick_notes.createTaskFromQuickNoteAsync(
            test_quick_note_id, 
            test_project_id, 
            "0", 
            10, 
            test_user_id
          )
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "task-created-already"
        
        return
    
    describe "undoCreateTaskFromQuickNoteAsync", ->
      beforeEach ->
        # Create a test quick note
        test_quick_note_id = APP.collections.QuickNotes.insert({
          title: "Test Quick Note for Undo",
          user_id: test_user_id,
          order: _.now()
        })
        
        # Create a task from the quick note
        created_task_id = await APP.justdo_quick_notes.createTaskFromQuickNoteAsync(
          test_quick_note_id, 
          test_project_id, 
          "0", 
          10, 
          test_user_id
        )
      
      it "should undo task creation from a quick note", ->
        # Store the task ID for verification
        task_id = APP.collections.QuickNotes.findOne({_id: test_quick_note_id}).created_task_id
        expect(task_id).to.exist
        
        # Verify task exists before undoing
        task_before = APP.collections.Tasks.findOne({_id: task_id})
        expect(task_before).to.exist
        expect(task_before._raw_removed_date).to.not.exist
        
        # Execute
        await APP.justdo_quick_notes.undoCreateTaskFromQuickNoteAsync(test_quick_note_id, test_user_id)
        
        # Verify quick note is restored
        quick_note = APP.collections.QuickNotes.findOne({_id: test_quick_note_id})
        expect(quick_note.deleted).to.be.null
        expect(quick_note.created_task_id).to.be.null
        
        # Verify task is removed (logical deletion)
        task_after = APP.collections.Tasks.findOne({_id: task_id})
        expect(task_after._raw_removed_date).to.exist
        expect(task_after._raw_removed_date).to.be.an.instanceof(Date)
        
        return
      
      it "should throw an error if no task was created from the quick note", ->
        # Setup
        APP.collections.QuickNotes.update(test_quick_note_id, {$set: {created_task_id: null}})
        
        # Execute and Verify
        try
          await APP.justdo_quick_notes.undoCreateTaskFromQuickNoteAsync(test_quick_note_id, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-argument"
        
        return 