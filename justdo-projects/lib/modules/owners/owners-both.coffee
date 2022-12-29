_.extend PACK.modules,
  owners:
    initBoth: ->
      @attachSchema()

    attachSchema: ->
      self = @

      Schema =
        owner_id:
          label: "Owner"
          type: String
          grid_foreign_key_collection: -> Meteor.users
          grid_foreign_key_collection_relevant_fields:
            "profile.first_name": 1
            "profile.last_name": 1
            "profile.profile_pic": 1
          grid_column_formatter: "display_name_formatter"
          grid_visible_column: true
          grid_editable_column: false
          user_editable_column: true

        is_removed_owner:
          label: "Is removed owner"
          optional: true
          type: String

        pending_owner_id:
          label: "Pending Owner"
          optional: true
          type: String
          grid_foreign_key_collection: -> Meteor.users
          grid_foreign_key_collection_relevant_fields:
            "profile.first_name": 1
            "profile.last_name": 1
            "profile.profile_pic": 1
          grid_column_formatter: "display_name_formatter"
          grid_visible_column: true
          grid_editable_column: false
          user_editable_column: true
        
        pending_owner_updated_at:
          label: "Pending Owner Updated At"
          optional: true
          type: Date
          autoValue: ->
            pending_owner_field = @field("pending_owner_id")

            if pending_owner_field.isSet
              return new Date()
            else
              this.unset()

            return # Keep this return to return undefined (as required by autoValue)

        #
        # Reject ownership related
        #
        reject_ownership_message:
          label: "Reject Ownership Message"
          optional: true
          type: String
          user_editable_column: true
          autoValue: ->
            # Allow setting the reject_ownership_message message only by users other
            # than those involved in the reject message process:
            #
            # * reject_ownership_message_by - to allow edits by the user wrote the reject ownership message
            # * reject_ownership_message_to - to allow dismiss by the receiving user (unsetting the value)
            # * pending_owner_id - to allow reject the transfer

            if not @isSet
              return
            else
              if Meteor.isServer
                if @docId?
                  if (item = self.items_collection.findOne(@docId, {fields: {_id: 0, users: 1, pending_owner_id: 1, reject_ownership_message_by: 1, reject_ownership_message_to: 1}}))?
                    if @value == null
                      pending_owner_id_field = @field("pending_owner_id")

                      if pending_owner_id_field.isSet and pending_owner_id_field.value == null
                        # Simple schema will automatically unset fields that
                        # are set to empty string. As a result, when the user
                        # will reject an ownership transfer with an empty
                        # reject_ownership_message the autoValues set for
                        # the other reject_ownership_message_*, that depends
                        # on reject_ownership_message set to work properly,
                        # won't work.
                        #
                        # We can skip the auto unset done by simple schema
                        # for empty values when we call the collection update
                        # method with certain options.
                        #
                        # Threfore, we introduced a method that serves the purpose of
                        # setting simple schema options properly: see on server file
                        # rejectOwnershipTransfer().
                        #
                        # If this if statement is true, it is very likely that the
                        # developer didn't use this method when attempting to reject
                        # ownership, and instead tried to update the reject_ownership_message
                        # value directly.

                        throw self._error "invalid-reject-message-setting-attempt", "It is very likely that you tried to set reject_ownership_message directly instead of using the rejectOwnershipTransfer() method"

                    # The following check is to be extra-careful.
                    if @userId not in item.users
                      throw self._error "not-task-member"

                    delete item.users # just to help the following code

                    if @userId in _.values(item)
                      return # Do nothing, set is allowed.

                throw self._error "illegal-reject-message-setting-attempt"

        reject_ownership_message_by:
          label: "Reject Ownership Message - Rejecting User"
          optional: true
          type: String
          autoValue: ->
            # Automatically set the reject_ownership_message_by to the logged
            # in user id, upon updates to the reject_ownership_message.
            #
            # Note, we make sure in reject_ownership_message autoValue that the
            # logged in user is allowed to set reject_ownership_message.
            reject_ownership_message = @field("reject_ownership_message")
            if reject_ownership_message.isSet
              if reject_ownership_message.value == null
                return {$set: null}
              else
                if not @isSet
                  return @userId
            else
              # Don't allow changing the reject_ownership_message_by if
              # we don't update the reject_ownership_message 
              if not @isFromTrustedCode
                if @isSet
                  throw self._error "permission-denied", "Untrusted attempt to change reject_ownership_message_by rejected"

                  # return @unset()

            return

        reject_ownership_message_to:
          label: "Reject Ownership Message - Transfering User"
          optional: true
          type: String
          user_editable_column: true
          autoValue: ->
            # Automatically set reject_ownership_message_to to the current
            # owner_id at the time reject_ownership_message was set.

            reject_ownership_message = @field("reject_ownership_message")
            if reject_ownership_message.isSet
              if reject_ownership_message.value == null
                return {$set: null}
              else
                if Meteor.isServer and @docId?
                  if (item = self.items_collection.findOne(@docId, {fields: {owner_id: 1}}))?
                    return item.owner_id
            else
              # If the code is not from trusted code unset the update
              if not @isFromTrustedCode
                if @isSet
                  throw self._error "permission-denied", "Untrusted attempt to change reject_ownership_message_to rejected"

                  # return @unset()

            return # Keep this return to return undefined (as required by autoValue)

        reject_ownership_message_updated_at:
          label: "Reject Ownership Message Updated At"
          optional: true
          type: Date
          autoValue: ->
            reject_ownership_message = @field("reject_ownership_message")

            if reject_ownership_message.isSet
              if reject_ownership_message.value == null
                return {$set: null}
              else
                return new Date()
            else
              # If the code is not from trusted code unset the update
              if not @isFromTrustedCode
                if @isSet
                  throw self._error "permission-denied", "Untrusted attempt to change reject_ownership_message_at rejected"

                  # return @unset()

            return # Keep this return to return undefined (as required by autoValue)

      @items_collection.attachSchema Schema
