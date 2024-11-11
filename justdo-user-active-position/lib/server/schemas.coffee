# We consider the schemas definition a secret so, unlike other packages, it isn't defined under both

JustdoUserActivePosition.schemas = {}

users_active_positions_ledger_collection_schema_definition =
  # Once we'll upgrade simple schema we'll be able to replace the following with .pick() and .extend().
  DID: JustdoAnalytics.schemas.ConnectIdentificationObjectSchema.getDefinition("DID")

  SID: JustdoAnalytics.schemas.ConnectIdentificationObjectSchema.getDefinition("SID")

  SSID: JustdoAnalytics.schemas.ASIDObjectSchema.getDefinition("SSID")

  UID:
    label: "User ID"

    optional: true # null means - non logged-in user

    type: String

  page:
    label: "page"

    optional: true # Special case - EXIT means end of session - either tab close/refresh (not promised)

    type: String

  justdo_id:
    label: "JustDo ID"

    optional: true # null means - not inside JustDo

    type: String

  tab:
    label: "Active tab"

    optional: true # null means - not inside JustDo

    type: String

  path:
    label: "Active path"

    optional: true # null means - no item is selected

    type: String

  field:
    label: "Active field"

    optional: true # null means - no field is in edit mode

    type: String

  time:
    label: "Time"

    type: Date
    autoValue: ->
      if this.isInsert
        return new Date
      else if this.isUpsert
        return {$setOnInsert: new Date}
      else
        this.unset()

      return

users_active_positions_current_collection_schema_definition = _.extend {}, users_active_positions_ledger_collection_schema_definition
users_active_positions_current_collection_schema_definition.time = _.extend users_active_positions_ledger_collection_schema_definition.time
users_active_positions_current_collection_schema_definition.time.autoValue = -> new Date()

UsersActivePositionsLedger = new SimpleSchema users_active_positions_ledger_collection_schema_definition
UsersActivePositionsCurrent = new SimpleSchema users_active_positions_current_collection_schema_definition

JustdoUserActivePosition.schemas.UsersActivePositionsLedger = UsersActivePositionsLedger
JustdoUserActivePosition.schemas.PosObjectSchema = UsersActivePositionsLedger.pick("DID", "SID", "page", "justdo_id", "tab", "path", "field")

_.extend JustdoUserActivePosition.prototype,
  _attachCollectionsSchemas: ->
    @users_active_positions_ledger_collection.attachSchema JustdoUserActivePosition.schemas.UsersActivePositionsLedger

    @users_active_positions_current_collection.attachSchema JustdoUserActivePosition.schemas.UsersActivePositionsCurrent # NOT YET MAINTAINED/IMPLEMENTEDusers_active_positions_ledger_collection

    return