MembersObjectsSchema = new SimpleSchema
  user_id:
    label: "User ID"

    type: String

  is_admin:
    label: "Is Admin"

    type: Boolean

  is_guest:
    label: "Is Guest"

    type: Boolean

  invited_at:
    label: "Invited At"

    type: Date

    optional: true
    autoValue: ->
      if this.isUpdate
        if @operator == "$push" # Only when we push the item for the first time we want date to be set.
          return new Date()

  invited_by:
    label: "Invited By"

    type: String

    optional: true

RemovedMembersSchema = new SimpleSchema
  user_id:
    label: "User ID"

    type: String

  removed_at:
    label: "Removed At"

    type: Date

    optional: true
    autoValue: ->
      if this.isUpdate
        if @operator == "$push" # Only when we push the item for the first time we want date to be set.
          return new Date()

  removed_by:
    label: "Removed by"

    type: String

    optional: true

_.extend Projects.prototype,
  _attachSchema: ->
    @_attachItemsCollectionSchema()
    @_attachProjectsCollectionSchema()
    @_attachUserProfileCollectionSchema()

    return

  _attachItemsCollectionSchema: ->
    self = @

    # Validate existing schema
    if not _.isEmpty(validation_error = @_validateItemsSchema())
      throw @_error "validation-error"

    return

  _validateItemsSchema: ->
    # XXX consider testing here whether seqID is part of the schema.

    if not @items_collection.simpleSchema()?
      return "items_collection has no simpleSchema definition"

    return true

  _attachProjectsCollectionSchema: ->
    self = @

    Schema = 
      title:
        label: "Title"

        defaultValue: "Untitled JustDo"

        type: String

      members:
        label: "Members"

        type: [MembersObjectsSchema]

      removed_members:
        label: "Removed Members"

        type: [RemovedMembersSchema]

        optional: true

      "members.$":
        blackbox: true

      access_restriction_type:
        label: "Access Restriction Type"

        defaultValue: "strict"

        allowedValues: ["strict"]

        type: String

      lastTaskSeqId:
        label: "Last Task Sequence ID"

        type: Number

        autoValue: ->
          # If the code is not from the server (isFromTrustedCode)
          # unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change lastTaskSeqId rejected"
            
            @unset()

          default_val = 0
          if this.isInsert
            return default_val
          else if this.isUpsert
            return {$setOnInsert: default_val}

          return # Keep this return to return undefined (as required by autoValue)

      custom_fields:
        label: "JustDo custom fields"

        type: [GridControlCustomFields.custom_field_definition_schema]

        optional: true

      removed_custom_fields:
        label: "JustDo removed custom fields"

        type: [GridControlCustomFields.custom_field_definition_schema]

        optional: true

      conf:
        label: "JustDo configuration"

        type: Object

        optional: true

        blackbox: true

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change conf rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

      createdAt:
        label: "Created"

        type: Date
        autoValue: ->
          if this.isInsert
            return new Date
          else if this.isUpsert
            return {$setOnInsert: new Date}
          else
            this.unset()

      updatedAt:
        label: "Modified"

        type: Date
        denyInsert: true
        optional: true
        autoValue: ->
          if this.isUpdate
            return new Date()

    @projects_collection.attachSchema Schema

  _attachUserProfileCollectionSchema: ->
    JustdoProjectsSharedComponents.attachUserProfileCollectionSchema()

    return