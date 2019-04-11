_.extend TasksFileManager.prototype,
  _attachCollectionsSchemas: ->
    @_attachTasksCollectionSchema()

  _attachTasksCollectionSchema: ->
    self = @

    # Add the project_id field
    Schema =
      files:
        label: "Task files"

        optional: true

        type: [Object]

      "files.$.id":
        label: "File ID"

        type: String

        optional: false

      "files.$.url":
        label: "File Url"

        type: String

        optional: false

      "files.$.title":
        label: "File Title"

        type: String

        optional: false

      "files.$.type":
        label: "File Type"

        type: String

        optional: true

      "files.$.size":
        label: "File Size"

        type: Number

        optional: true

      # For unstructured package or user supplied metadata
      "files.$.metadata":
        label: "Metadata"
        type: Object
        optional: true
        blackbox: true


      "files.$.user_uploaded":
        label: "Uploaded By"

        type: String

        optional: true

      "files.$.date_uploaded":
        label: "Date Uploaded"

        type: Date

        optional: true

        # It would be nice to use autovalue here to set the date uploaded,
        # however since this is a sub-document, we can't tell if the file
        # is being added or updated

    for field_id, field_def of Schema
      Schema[field_id].autoValue = ->
        # If the code is not from trusted code unset the update,
        # only api calls should be able to set
        if not @isFromTrustedCode
          console.warn "Untrusted attempt to change files (#{field_id}) field rejected"

          return @unset()

        return

    @tasks_collection.attachSchema Schema

    return
