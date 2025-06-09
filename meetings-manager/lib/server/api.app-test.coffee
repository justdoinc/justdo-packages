if Package["justdoinc:meetings-manager"]?
  {expect, assert} = require "chai"
  
  describe "MeetingsManager API", ->
    # Setup variables
    test_user_id = "test_user_1"
    test_user_id_2 = "test_user_2"
    test_project_id = null
    test_meeting_id = null
    test_task_id = null
    test_task_id_2 = null
    meetings_manager = null
    
    # Setup before all tests
    before (done) ->
      APP.getEnv ->
        # Get the meetings manager instance
        meetings_manager = APP.meetings_manager_plugin.meetings_manager
        
        # Create a test project with required fields
        project_doc = 
          title: "Test Project for Meetings"
          timezone: "America/New_York"
          members: [
            {user_id: test_user_id, is_admin: true}
            {user_id: test_user_id_2, is_admin: false}
          ]
          conf: {}
        
        test_project_id = APP.collections.Projects.insert(project_doc)
        
        # Create test tasks using the grid API
        test_task_id = APP.projects._grid_data_com.addRootChild(
          project_id: test_project_id
          title: "Test Task 1"
          users: [test_user_id, test_user_id_2]
        , test_user_id)
        
        test_task_id_2 = APP.projects._grid_data_com.addRootChild(
          project_id: test_project_id
          title: "Test Task 2"
          users: [test_user_id]
        , test_user_id)
        
        done()
    
    # Clean up after all tests
    after ->
      # Clean up test data
      if meetings_manager?
        meetings_manager.meetings.remove({project_id: test_project_id})
        meetings_manager.meetings_tasks.remove({})
        meetings_manager.meetings_private_notes.remove({})
      
      # Clean up tasks and project
      APP.collections.Tasks.remove({project_id: test_project_id})
      APP.collections.Projects.remove({_id: test_project_id})
    
    # Reset collections before each test
    beforeEach ->
      if meetings_manager?
        meetings_manager.meetings.remove({project_id: test_project_id})
        meetings_manager.meetings_tasks.remove({})
        meetings_manager.meetings_private_notes.remove({})
    
    describe "createMeeting", ->
      it "should create a new meeting", ->
        # Setup
        fields = 
          title: "Test Meeting"
          location: "Conference Room A"
          date: new Date()
          project_id: test_project_id
          status: "draft"
        
        # Execute
        meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        
        # Verify
        expect(meeting_id).to.exist
        meeting = meetings_manager.meetings.findOne({_id: meeting_id})
        expect(meeting).to.exist
        expect(meeting.title).to.equal "Test Meeting"
        expect(meeting.location).to.equal "Conference Room A"
        expect(meeting.project_id).to.equal test_project_id
        expect(meeting.organizer_id).to.equal test_user_id
        expect(meeting.users).to.include test_user_id
        expect(meeting.status).to.equal "draft"
        expect(meeting.tasks).to.be.an "array"
        expect(meeting.tasks).to.have.length 0
        
        return
      
      it "should throw an error if fields is not an object", ->
        # Execute and Verify
        try
          await meetings_manager.createMeetingAsync("invalid", test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
        
        return
      
      it "should throw an error if user is not a project member", ->
        # Setup
        fields = 
          title: "Test Meeting"
          project_id: test_project_id
          status: "draft"
        
        # Execute and Verify
        try
          await meetings_manager.createMeetingAsync(fields, "non_member_user")
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-project-member"
        
        return
    
    describe "addUsersToMeeting", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Users"
          project_id: test_project_id
          status: "draft"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should add users to a meeting", ->
        # Execute
        await meetings_manager.addUsersToMeetingAsync(test_meeting_id, [test_user_id_2], test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.users).to.include test_user_id_2
        
        return
      
      it "should throw an error if meeting_id is not a string", ->
        # Execute and Verify
        try
          await meetings_manager.addUsersToMeetingAsync(123, [test_user_id_2], test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
        
        return
      
      it "should throw an error if user is not a meeting member", ->
        # Execute and Verify
        try
          await meetings_manager.addUsersToMeetingAsync(test_meeting_id, [test_user_id_2], "non_member_user")
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-meeting-member"
        
        return
    
    describe "removeUsersFromMeeting", ->
      beforeEach ->
        # Create a test meeting with multiple users
        fields = 
          title: "Test Meeting for User Removal"
          project_id: test_project_id
          status: "draft"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addUsersToMeetingAsync(test_meeting_id, [test_user_id_2], test_user_id)
      
      it "should remove users from a meeting", ->
        # Execute
        await meetings_manager.removeUsersFromMeetingAsync(test_meeting_id, [test_user_id_2], test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.users).to.not.include test_user_id_2
        
        return
      
      it "should throw an error when trying to remove the organizer", ->
        # Execute and Verify
        try
          await meetings_manager.removeUsersFromMeetingAsync(test_meeting_id, [test_user_id], test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
          expect(error.reason).to.include "organizer"
        
        return
    
    describe "updateMeetingMetadata", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Metadata"
          project_id: test_project_id
          status: "draft"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should update meeting metadata", ->
        # Setup
        update_fields = 
          title: "Updated Meeting Title"
          location: "New Conference Room"
          note: "Meeting summary notes"
        
        # Execute
        await meetings_manager.updateMeetingMetadataAsync(test_meeting_id, update_fields, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.title).to.equal "Updated Meeting Title"
        expect(meeting.location).to.equal "New Conference Room"
        expect(meeting.note).to.equal "Meeting summary notes"
        
        return
      
      it "should throw an error if fields is not an object", ->
        # Execute and Verify
        try
          await meetings_manager.updateMeetingMetadataAsync(test_meeting_id, "invalid", test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
        
        return
    
    describe "updateMeetingStatus", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Status"
          project_id: test_project_id
          status: "draft"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should update meeting status to pending", ->
        # Execute
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "pending", test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.status).to.equal "pending"
        
        return
      
      it "should update meeting status to in-progress and add start time", ->
        # First change to pending (only organizer can change from draft)
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "pending", test_user_id)
        
        # Execute
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "in-progress", test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.status).to.equal "in-progress"
        expect(meeting.start).to.be.an "array"
        expect(meeting.start).to.have.length 1
        expect(meeting.start[0].user_id).to.equal test_user_id
        expect(meeting.start[0].date).to.be.an.instanceof Date
        
        return
      
      it "should update meeting status to ended and add end time", ->
        # First change to pending, then in-progress
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "pending", test_user_id)
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "in-progress", test_user_id)
        
        # Execute
        await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "ended", test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.status).to.equal "ended"
        expect(meeting.end).to.be.an "array"
        expect(meeting.end).to.have.length 1
        expect(meeting.end[0].user_id).to.equal test_user_id
        expect(meeting.end[0].date).to.be.an.instanceof Date
        
        return
      
      it "should throw an error if non-organizer tries to change from draft", ->
        # Add another user to the meeting
        await meetings_manager.addUsersToMeetingAsync(test_meeting_id, [test_user_id_2], test_user_id)
        
        # Execute and Verify
        try
          await meetings_manager.updateMeetingStatusAsync(test_meeting_id, "pending", test_user_id_2)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-meeting-organizer"
        
        return
    
    describe "addTaskToMeeting", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Tasks"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should add a task to a meeting by task_id", ->
        # Setup
        task_fields = 
          task_id: test_task_id
        
        # Execute
        meeting_task_id = await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id)
        
        # Verify
        expect(meeting_task_id).to.exist
        
        # Check meeting_task was created
        meeting_task = meetings_manager.meetings_tasks.findOne({_id: meeting_task_id})
        expect(meeting_task).to.exist
        expect(meeting_task.task_id).to.equal test_task_id
        expect(meeting_task.meeting_id).to.equal test_meeting_id
        
        # Check meeting was updated
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.tasks).to.have.length 1
        expect(meeting.tasks[0].task_id).to.equal test_task_id
        expect(meeting.tasks[0].added_by_user).to.equal test_user_id
        expect(meeting.tasks[0].added_at).to.be.an.instanceof Date
        
        return
      
      it "should add a task to a meeting by seqId", ->
        # Setup - Get the task's seqId
        task = APP.collections.Tasks.findOne({_id: test_task_id})
        task_fields = 
          seqId: task.seqId
        
        # Execute
        meeting_task_id = await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id)
        
        # Verify
        expect(meeting_task_id).to.exist
        meeting_task = meetings_manager.meetings_tasks.findOne({_id: meeting_task_id})
        expect(meeting_task.task_id).to.equal test_task_id
        
        return
      
      it "should throw an error if task is already in the meeting", ->
        # Setup - Add task to meeting first
        task_fields = 
          task_id: test_task_id
        
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id)
        
        # Execute and Verify
        try
          await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "duplicate-task"
        
        return
      
      it "should throw an error if user is not a task member", ->
        # Setup
        task_fields = 
          task_id: test_task_id_2  # test_user_id_2 is not a member of this task
        
        # Execute and Verify
        try
          await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id_2)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-meeting-member"  # Fixed to match actual error
        
        return
    
    describe "removeTaskFromMeeting", ->
      beforeEach ->
        # Create a test meeting with a task
        fields = 
          title: "Test Meeting for Task Removal"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        
        task_fields = 
          task_id: test_task_id
        
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, task_fields, test_user_id)
      
      it "should remove a task from a meeting", ->
        # Execute
        result = await meetings_manager.removeTaskFromMeetingAsync(test_meeting_id, test_task_id, test_user_id)
        
        # Verify
        expect(result).to.be.true
        
        # Check meeting_task was removed
        meeting_task = meetings_manager.meetings_tasks.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
        })
        expect(meeting_task).to.not.exist
        
        # Check meeting was updated
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.tasks).to.have.length 0
        
        return
    
    describe "setMeetingTaskOrder", ->
      # Track dynamically created tasks for cleanup
      additional_task_ids = []
      
      beforeEach ->
        # Clear tracking array
        additional_task_ids = []
        
        # Create a test meeting with multiple tasks
        fields = 
          title: "Test Meeting for Task Order"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        
        # Add tasks
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id_2}, test_user_id)
      
      afterEach ->
        # Clean up any dynamically created tasks
        if additional_task_ids.length > 0
          for task_id in additional_task_ids
            APP.collections.Tasks.remove({_id: task_id})
      
      it "should set the order of a task in the meeting", ->
        # Execute
        result = await meetings_manager.setMeetingTaskOrderAsync(test_meeting_id, test_task_id, 100, test_user_id)
        
        # Verify
        expect(result).to.be.true
        
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        task_item = meeting.tasks.find((task) -> task.task_id == test_task_id)  # Fixed underscore function
        expect(task_item.task_order).to.equal 100
        
        return
      
      it "should throw an error if task is not part of the meeting", ->
        # Setup - Create another task not in the meeting
        another_task_id = APP.projects._grid_data_com.addRootChild(
          project_id: test_project_id
          title: "Another Task"
          users: [test_user_id]
        , test_user_id)
        
        # Track for cleanup
        additional_task_ids.push(another_task_id)
        
        # Execute and Verify
        try
          await meetings_manager.setMeetingTaskOrderAsync(test_meeting_id, another_task_id, 100, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
          expect(error.reason).to.include "not part of meeting"
        
        return
    
    describe "addSubTaskToTask", ->
      # Track dynamically created subtasks for cleanup
      created_subtask_ids = []
      
      beforeEach ->
        # Clear tracking array
        created_subtask_ids = []
        
        # Create a test meeting with a task
        fields = 
          title: "Test Meeting for Sub Tasks"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      afterEach ->
        # Clean up any dynamically created subtasks
        if created_subtask_ids.length > 0
          for task_id in created_subtask_ids
            APP.collections.Tasks.remove({_id: task_id})
      
      it "should add a subtask to a task in the meeting", ->
        # Setup
        task_fields = 
          title: "New Sub Task from Meeting"
        
        # Execute
        new_task_id = await meetings_manager.addSubTaskToTaskAsync(test_meeting_id, test_task_id, task_fields, test_user_id)
        
        # Track for cleanup
        created_subtask_ids.push(new_task_id)
        
        # Verify
        expect(new_task_id).to.exist
        
        # Check the new task was created
        new_task = APP.collections.Tasks.findOne({_id: new_task_id})
        expect(new_task).to.exist
        expect(new_task.title).to.equal "New Sub Task from Meeting"
        expect(new_task.created_from_meeting_id).to.equal test_meeting_id
        
        # Check it was added to the meeting_task record
        meeting_task = meetings_manager.meetings_tasks.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
        })
        expect(meeting_task.added_tasks).to.have.length 1
        expect(meeting_task.added_tasks[0].task_id).to.equal new_task_id
        expect(meeting_task.added_tasks[0].title).to.equal "New Sub Task from Meeting"
        
        return
      
      it "should throw an error if parent task is not part of the meeting", ->
        # Setup
        task_fields = 
          title: "New Sub Task"
        
        # Execute and Verify
        try
          await meetings_manager.addSubTaskToTaskAsync(test_meeting_id, test_task_id_2, task_fields, test_user_id)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "invalid-request"
          expect(error.reason).to.include "not part of meeting"
        
        return
    
    describe "setNoteForTask", ->
      beforeEach ->
        # Create a test meeting with a task
        fields = 
          title: "Test Meeting for Notes"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      it "should set a note for a task in the meeting", ->
        # Setup
        note_fields = 
          note: "This is a summary note for the task"
          note_lock: {locked_by: test_user_id, locked_at: new Date()}
        
        # Execute
        await meetings_manager.setNoteForTaskAsync(test_meeting_id, test_task_id, note_fields, test_user_id)
        
        # Verify
        meeting_task = meetings_manager.meetings_tasks.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
        })
        expect(meeting_task.note).to.equal "This is a summary note for the task"
        expect(meeting_task.note_lock).to.exist
        expect(meeting_task.note_lock.locked_by).to.equal test_user_id
        
        return
    
    describe "setUserNoteForTask", ->
      beforeEach ->
        # Create a test meeting with a task
        fields = 
          title: "Test Meeting for User Notes"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      it "should set a user note for a task in the meeting", ->
        # Setup
        note_fields = 
          note: "This is my personal note for the task"
        
        # Execute
        await meetings_manager.setUserNoteForTaskAsync(test_meeting_id, test_task_id, note_fields, test_user_id)
        
        # Verify
        meeting_task = meetings_manager.meetings_tasks.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
        })
        expect(meeting_task.user_notes).to.have.length 1
        expect(meeting_task.user_notes[0].user_id).to.equal test_user_id
        expect(meeting_task.user_notes[0].note).to.equal "This is my personal note for the task"
        expect(meeting_task.user_notes[0].date_added).to.be.an.instanceof Date
        expect(meeting_task.user_notes[0].date_updated).to.be.an.instanceof Date
        
        return
      
      it "should update an existing user note", ->
        # Setup - Add initial note
        note_fields = 
          note: "Initial note"
        
        await meetings_manager.setUserNoteForTaskAsync(test_meeting_id, test_task_id, note_fields, test_user_id)
        
        # Update the note
        updated_note_fields = 
          note: "Updated note"
        
        # Execute
        await meetings_manager.setUserNoteForTaskAsync(test_meeting_id, test_task_id, updated_note_fields, test_user_id)
        
        # Verify
        meeting_task = meetings_manager.meetings_tasks.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
        })
        expect(meeting_task.user_notes).to.have.length 1
        expect(meeting_task.user_notes[0].note).to.equal "Updated note"
        
        return
    
    describe "setPrivateNoteForTask", ->
      beforeEach ->
        # Create a test meeting with a task
        fields = 
          title: "Test Meeting for Private Notes"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      it "should set a private note for a task in the meeting", ->
        # Setup
        note_fields = 
          note: "This is my private note"
        
        # Execute
        await meetings_manager.setPrivateNoteForTaskAsync(test_meeting_id, test_task_id, note_fields, test_user_id)
        
        # Verify
        private_note = meetings_manager.meetings_private_notes.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
          user_id: test_user_id
        })
        expect(private_note).to.exist
        expect(private_note.note).to.equal "This is my private note"
        expect(private_note.updatedAt).to.be.an.instanceof Date
        
        return
      
      it "should update an existing private note", ->
        # Setup - Add initial private note
        note_fields = 
          note: "Initial private note"
        
        await meetings_manager.setPrivateNoteForTaskAsync(test_meeting_id, test_task_id, note_fields, test_user_id)
        
        # Update the note
        updated_note_fields = 
          note: "Updated private note"
        
        # Execute
        await meetings_manager.setPrivateNoteForTaskAsync(test_meeting_id, test_task_id, updated_note_fields, test_user_id)
        
        # Verify
        private_note = meetings_manager.meetings_private_notes.findOne({
          meeting_id: test_meeting_id
          task_id: test_task_id
          user_id: test_user_id
        })
        expect(private_note.note).to.equal "Updated private note"
        
        return
    
    describe "updateMeetingLock", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Lock"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should lock a meeting", ->
        # Execute
        await meetings_manager.updateMeetingLockAsync(test_meeting_id, true, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.locked).to.be.true
        
        return
      
      it "should unlock a meeting", ->
        # Setup - Lock the meeting first
        await meetings_manager.updateMeetingLockAsync(test_meeting_id, true, test_user_id)
        
        # Execute
        await meetings_manager.updateMeetingLockAsync(test_meeting_id, false, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.locked).to.be.false
        
        return
      
      it "should throw an error if user is not the organizer", ->
        # Execute and Verify
        try
          await meetings_manager.updateMeetingLockAsync(test_meeting_id, true, test_user_id_2)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-meeting-organizer"
        
        return
    
    describe "updateMeetingPrivacy", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Privacy"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
      
      it "should make a meeting private", ->
        # Execute
        await meetings_manager.updateMeetingPrivacyAsync(test_meeting_id, true, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.private).to.be.true
        
        return
      
      it "should make a meeting public", ->
        # Setup - Make the meeting private first
        await meetings_manager.updateMeetingPrivacyAsync(test_meeting_id, true, test_user_id)
        
        # Execute
        await meetings_manager.updateMeetingPrivacyAsync(test_meeting_id, false, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting.private).to.be.false
        
        return
      
      it "should throw an error if user is not the organizer", ->
        # Execute and Verify
        try
          await meetings_manager.updateMeetingPrivacyAsync(test_meeting_id, true, test_user_id_2)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "not-meeting-organizer"
        
        return
    
    describe "deleteMeeting", ->
      beforeEach ->
        # Reset project member permissions to original state
        APP.collections.Projects.update(test_project_id, {
          $set: {
            "members.0": {user_id: test_user_id, is_admin: true}
            "members.1": {user_id: test_user_id_2, is_admin: false}
          }
        })
        
        # Create a test meeting with tasks
        fields = 
          title: "Test Meeting for Deletion"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      it "should delete a meeting by organizer", ->
        # Execute
        await meetings_manager.deleteMeetingAsync(test_meeting_id, test_user_id)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting).to.not.exist
        
        # Note: meetings_tasks cleanup is handled by migration script, not by deleteMeeting method
        # So we don't test for meetings_tasks cleanup here
        
        return
      
      it "should delete a meeting by admin", ->
        # Setup - Make test_user_id_2 an admin
        APP.collections.Projects.update(test_project_id, {
          $set: {"members.1.is_admin": true}
        })
        
        # Execute
        await meetings_manager.deleteMeetingAsync(test_meeting_id, test_user_id_2)
        
        # Verify
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        expect(meeting).to.not.exist
        
        return
      
      it "should throw an error if user is not organizer or admin", ->
        # Execute and Verify
        try
          await meetings_manager.deleteMeetingAsync(test_meeting_id, test_user_id_2)
          assert.fail("Expected to throw error")
        catch error
          expect(error).to.exist
          expect(error.error).to.equal "permission-denied"
        
        return
    
    describe "recalTaskMeetingsCache", ->
      beforeEach ->
        # Create test meetings
        fields1 = 
          title: "Test Meeting 1"
          project_id: test_project_id
          status: "pending"
        
        fields2 = 
          title: "Test Meeting 2"
          project_id: test_project_id
          status: "ended"
        
        meeting_id_1 = await meetings_manager.createMeetingAsync(fields1, test_user_id)
        meeting_id_2 = await meetings_manager.createMeetingAsync(fields2, test_user_id)
        
        # Add the same task to both meetings
        await meetings_manager.addTaskToMeetingAsync(meeting_id_1, {task_id: test_task_id}, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(meeting_id_2, {task_id: test_task_id}, test_user_id)
      
      afterEach ->
        # Reset the cache field on the task to prevent state pollution
        cache_field = MeetingsManagerPlugin.task_meetings_cache_field_id
        unset_obj = {}
        unset_obj[cache_field] = 1
        APP.collections.Tasks.update({_id: test_task_id}, {$unset: unset_obj})
      
      it "should update the task meetings cache", ->
        # Execute
        await meetings_manager.recalTaskMeetingsCacheAsync(test_task_id)
        
        # Verify
        task = APP.collections.Tasks.findOne({_id: test_task_id})
        cache_field = MeetingsManagerPlugin.task_meetings_cache_field_id
        expect(task[cache_field]).to.exist
        expect(task[cache_field]).to.be.an "array"
        expect(task[cache_field]).to.have.length 2  # Both meetings should be in cache
        
        return
    
    describe "getMeetingIfAccessible", ->
      beforeEach ->
        # Create a test meeting
        fields = 
          title: "Test Meeting for Access"
          project_id: test_project_id
          status: "pending"
        
        test_meeting_id = await meetings_manager.createMeetingAsync(fields, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
      
      it "should return meeting if user is a member", ->
        # Execute
        meeting = await meetings_manager.getMeetingIfAccessibleAsync(test_meeting_id, test_user_id)
        
        # Verify
        expect(meeting).to.exist
        expect(meeting._id).to.equal test_meeting_id
        
        return
      
      it "should return meeting if user has access to tasks", ->
        # Setup - Add test_user_id_2 to the meeting first to ensure access
        await meetings_manager.addUsersToMeetingAsync(test_meeting_id, [test_user_id_2], test_user_id)
        
        # Execute - test_user_id_2 now has access to the meeting
        meeting = await meetings_manager.getMeetingIfAccessibleAsync(test_meeting_id, test_user_id_2)
        
        # Verify
        expect(meeting).to.exist
        expect(meeting._id).to.equal test_meeting_id
        
        return
      
      it "should return null if user has no access", ->
        # Execute
        meeting = await meetings_manager.getMeetingIfAccessibleAsync(test_meeting_id, "no_access_user")
        
        # Verify
        expect(meeting).to.be.null
        
        return
    
    describe "filterAccessableMeetingTasks", ->
      beforeEach ->
        # Create test tasks and meeting structure
        test_meeting_id = await meetings_manager.createMeetingAsync({
          title: "Test Meeting"
          project_id: test_project_id
          status: "pending"
        }, test_user_id)
        
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id}, test_user_id)
        await meetings_manager.addTaskToMeetingAsync(test_meeting_id, {task_id: test_task_id_2}, test_user_id)
      
      it "should filter tasks by removing inaccessible ones", ->
        # Setup
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        
        # Execute - test_user_id has access to both tasks as organizer
        filtered_tasks = await meetings_manager.filterAccessableMeetingTasksAsync(meeting.tasks, test_user_id, "remove")
        
        # Verify - As organizer, user should have access to all tasks
        expect(filtered_tasks).to.have.length 2
        
        return
      
      it "should filter tasks by suppressing fields for inaccessible ones", ->
        # Setup
        meeting = meetings_manager.meetings.findOne({_id: test_meeting_id})
        
        # Execute - test_user_id has access to both tasks as organizer
        filtered_tasks = await meetings_manager.filterAccessableMeetingTasksAsync(meeting.tasks, test_user_id, "supress_fields")
        
        # Verify - As organizer, user should have access to all task fields
        expect(filtered_tasks).to.have.length 2
        # Both tasks should have their fields accessible since user is organizer
        expect(filtered_tasks[0]).to.exist
        expect(filtered_tasks[1]).to.exist
        
        return 