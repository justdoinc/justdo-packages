if Package["justdoinc:justdo-user-active-position"]?
  {expect, assert} = require "chai"
  
  describe "JustdoUserActivePosition API", ->
    # Setup variables
    test_user_id = "test_user_id_position"
    test_valid_pos = null
    
    # Setup before all tests
    before (done) ->
      APP.getEnv ->
        # Setup valid position object for testing
        test_valid_pos = 
          DID: "12345678901234567" # Must be exactly 17 characters
          SID: "98765432109876543" # Must be exactly 17 characters  
          page: "/app/projects"
          justdo_id: "test_justdo_id"
          tab: "tasks"
          path: "/test/path"
          field: "title"
        
        done()
    
    # Clean up after all tests
    after ->
      # Clean up all test data
      if APP.collections.UsersActivePositionsLedger?
        APP.collections.UsersActivePositionsLedger.remove({UID: test_user_id})
    
    # Reset collections before each test
    beforeEach ->
      # Clean up position records before each test
      if APP.collections.UsersActivePositionsLedger?
        APP.collections.UsersActivePositionsLedger.remove({UID: test_user_id})
    
    describe "logPos", ->
      it "should log a valid position for a logged-in user", ->
        # Execute
        await APP.justdo_user_active_position.logPosAsync(test_valid_pos, test_user_id)
        
        # Verify the document was inserted
        logged_pos = APP.collections.UsersActivePositionsLedger.findOne({UID: test_user_id})
        expect(logged_pos).to.exist
        expect(logged_pos.UID).to.equal test_user_id
        expect(logged_pos.SSID).to.exist
        expect(logged_pos.SSID).to.be.a("string")
        expect(logged_pos.SSID.length).to.be.within(15, 30) # SSID validation range
        expect(logged_pos.DID).to.equal test_valid_pos.DID
        expect(logged_pos.SID).to.equal test_valid_pos.SID
        expect(logged_pos.page).to.equal test_valid_pos.page
        expect(logged_pos.justdo_id).to.equal test_valid_pos.justdo_id
        expect(logged_pos.tab).to.equal test_valid_pos.tab
        expect(logged_pos.path).to.equal test_valid_pos.path
        expect(logged_pos.field).to.equal test_valid_pos.field
        expect(logged_pos.time).to.be.an.instanceof(Date)
        
        return
      
      it "should not log position when user_id is null", ->
        # Execute
        await APP.justdo_user_active_position.logPosAsync(test_valid_pos, null)
        
        # Verify no document was inserted
        logged_pos = APP.collections.UsersActivePositionsLedger.findOne({UID: test_user_id})
        expect(logged_pos).to.not.exist
        
        return
      
      it "should not log position when user_id is undefined", ->
        # Execute
        await APP.justdo_user_active_position.logPosAsync(test_valid_pos, undefined)
        
        # Verify no document was inserted
        logged_pos = APP.collections.UsersActivePositionsLedger.findOne({UID: test_user_id})
        expect(logged_pos).to.not.exist
        
        return
      
      it "should not log position when user_id is empty string", ->
        # Execute
        await APP.justdo_user_active_position.logPosAsync(test_valid_pos, "")
        
        # Verify no document was inserted
        logged_pos = APP.collections.UsersActivePositionsLedger.findOne({UID: test_user_id})
        expect(logged_pos).to.not.exist
        
        return
      
      it "should handle minimal position object with required fields only", ->
        ssid = APP.justdo_analytics.getSSID()
        # Setup minimal position object
        minimal_pos = 
          DID: "abcdefghijklmnopq" # Must be exactly 17 characters
          SID: "zyxwvutsrqponmlkj" # Must be exactly 17 characters
        
        # Execute
        await APP.justdo_user_active_position.logPosAsync(minimal_pos, test_user_id)
        
        # Verify the document was inserted with minimal data
        logged_pos = APP.collections.UsersActivePositionsLedger.findOne({UID: test_user_id})
        expect(logged_pos).to.exist
        expect(logged_pos.UID).to.equal test_user_id
        expect(logged_pos.SSID).to.equal ssid
        expect(logged_pos.DID).to.equal minimal_pos.DID
        expect(logged_pos.SID).to.equal minimal_pos.SID
        expect(logged_pos.time).to.be.an.instanceof(Date)
        
        # Optional fields should be undefined
        expect(logged_pos.page).to.be.undefined
        expect(logged_pos.justdo_id).to.be.undefined
        expect(logged_pos.tab).to.be.undefined
        expect(logged_pos.path).to.be.undefined
        expect(logged_pos.field).to.be.undefined
        
        return
      
      it "should throw validation error for invalid position object", ->
        # Setup invalid position object (missing required DID field)
        invalid_pos = 
          SID: "98765432109876543" # Must be exactly 17 characters
          page: "/test/page"
        
        # Execute and Verify
        try
          await APP.justdo_user_active_position.logPosAsync(invalid_pos, test_user_id)
          assert.fail("Expected to throw validation error")
        catch error
          expect(error).to.exist
        
        return
      
      it "should throw validation error for non-string user_id when provided", ->
        # Execute and Verify - passing number instead of string
        try
          await APP.justdo_user_active_position.logPosAsync(test_valid_pos, 12345)
          assert.fail("Expected to throw validation error")
        catch error
          expect(error).to.exist
        
        return
      
      it "should preserve original position object properties", ->
        # Create a position object to test immutability
        original_pos = _.clone(test_valid_pos)
        
        # Execute
        await APP.justdo_user_active_position.logPosAsync(test_valid_pos, test_user_id)
        
        # Verify original object wasn't modified
        expect(test_valid_pos).to.deep.equal original_pos
        expect(test_valid_pos.UID).to.be.undefined
        expect(test_valid_pos.SSID).to.be.undefined
        
        return
      
      it "should handle multiple log entries for the same user", ->
        # First log entry
        first_pos = _.extend {}, test_valid_pos, {page: "/first/page"}
        await APP.justdo_user_active_position.logPosAsync(first_pos, test_user_id)
        
        # Second log entry  
        second_pos = _.extend {}, test_valid_pos, {page: "/second/page"}
        await APP.justdo_user_active_position.logPosAsync(second_pos, test_user_id)
        
        # Verify both entries exist
        logged_positions = APP.collections.UsersActivePositionsLedger.find({UID: test_user_id}).fetch()
        expect(logged_positions).to.have.lengthOf(2)
        
        pages = _.map(logged_positions, (pos) -> pos.page)
        expect(pages).to.include("/first/page")
        expect(pages).to.include("/second/page")
        
        # Verify SSID is set correctly for both entries
        _.each logged_positions, (pos) ->
          expect(pos.SSID).to.exist
          expect(pos.SSID).to.be.a("string")
          expect(pos.SSID.length).to.be.within(15, 30)
        
        return 