JustdoRoles.schemas = {}

JustdoRoles.schemas.RegionsSchema = new SimpleSchema
  _id:
    label: "Schmea ID"

    type: String

  label:
    label: "Role Label"

    type: String

  managers:
    label: "Region Managers"

    defaultValue: []

    type: [String]

JustdoRoles.schemas.RoleRegionSchema = new SimpleSchema
  _id:
    label: "The region ID"

    type: String

  uid:
    label: "Region Role User ID"

    type: String

JustdoRoles.schemas.RolesSchema = new SimpleSchema
  _id:
    label: "Schmea ID"

    type: String

  label:
    label: "Role Label"

    type: String

  regions:
    label: "Role Region Member"

    type: [JustdoRoles.schemas.RoleRegionSchema]

JustdoRoles.schemas.GroupRegionSchema = new SimpleSchema
  _id:
    label: "The region ID"

    type: String

  uids:
    label: "Region Role User IDs"

    type: [String]

JustdoRoles.schemas.GroupsSchema = new SimpleSchema
  _id:
    label: "Group ID"

    type: String

  label:
    label: "Group Label"

    type: String

  regions:
    label: "Group Region Members"

    type: [JustdoRoles.schemas.GroupRegionSchema]


JustdoRoles.schemas.RoleRegionEditSchema = new SimpleSchema
  region_id:
    label: "The region ID"

    type: String

  role_id:
    label: "The region ID"

    type: String

  uid:
    label: "Region Role User ID"

    type: String

    optional: true

JustdoRoles.schemas.GroupRegionEditSchema = new SimpleSchema
  region_id:
    label: "The region ID"

    type: String

  group_id:
    label: "The region ID"

    type: String

  uids:
    label: "Region Group User IDs"

    type: [String]

    optional: true

_.extend JustdoRoles.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      project_id:
        label: "Project ID"

        type: String

      regions:
        label: "Regions"
        type: [JustdoRoles.schemas.RegionsSchema]

      roles:
        label: "Roles"
        type: [JustdoRoles.schemas.RolesSchema]

      groups:
        label: "Groups"
        type: [JustdoRoles.schemas.GroupsSchema]

      createdAt:
        label: "Created"

        type: Date
        autoValue: ->
          if this.isInsert
            return new Date()
          else if this.isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

          return

      updatedAt:
        label: "Updated"

        type: Date

        autoValue: ->
          if this.isUpdate
            return new Date()
          else if this.isInsert
            return new Date()
          else if this.isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

          return

      updatedBy:
        label: "Updated By"

        optional: true
        type: String

    @projects_roles_and_grps_collection.attachSchema Schema

    return