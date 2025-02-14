_.extend JustdoUserActivePosition.prototype,
  _setupPublications: ->
    self = @

    if @onGridUserActivePositionEnabled()
      Meteor.publish "projectMembersCurrentPositions", (project_id) ->
        publish_this = @

        if not project_id? or not publish_this.userId?
          return publish_this.ready()
        
        if not APP.projects.getProjectIfUserIsMember project_id, publish_this.userId
          return publish_this.ready()

        # A map to store the user id to the ledger doc, to enahnce performance by publishing one document per user and removing the previous one
        user_id_to_ledger_doc_map = {}
        isLedgerDocUnderProject = (ledger_doc_fields) -> ledger_doc_fields.justdo_id is project_id
        getPreviousUserLedgerDoc = (user_id) ->
          return user_id_to_ledger_doc_map[user_id]
        setAndPublishUserLedgerDocIfUnderProject = (new_ledger_doc_id, new_ledger_doc_fields) ->
          if not isLedgerDocUnderProject(new_ledger_doc_fields)
            delete user_id_to_ledger_doc_map[new_ledger_doc_fields.UID]
            return

          user_id_to_ledger_doc_map[new_ledger_doc_fields.UID] = 
            _id: new_ledger_doc_id
            time: new_ledger_doc_fields.time
          publish_this.added JustdoUserActivePosition.users_active_position_current_collection_name, new_ledger_doc_id, new_ledger_doc_fields
          return
        # Get the cursor for the project members current positions
        cursor = self.getRecentActivePositionsLedgerDocCursor publish_this.userId

        cursor.observeChanges
          added: (new_ledger_doc_id, new_ledger_doc_fields) ->
            existing_user_ledger_doc = getPreviousUserLedgerDoc new_ledger_doc_fields.UID

            if not existing_user_ledger_doc?
              setAndPublishUserLedgerDocIfUnderProject new_ledger_doc_id, new_ledger_doc_fields
            else if existing_user_ledger_doc.time < new_ledger_doc_fields.time
              publish_this.removed JustdoUserActivePosition.users_active_position_current_collection_name, existing_user_ledger_doc._id
              setAndPublishUserLedgerDocIfUnderProject new_ledger_doc_id, new_ledger_doc_fields

        return publish_this.ready()
    
    return