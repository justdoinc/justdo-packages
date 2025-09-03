_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Server-only methods required to register a file system
  # 
  uploadTaskFile: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
    # Uploads a file to a task
    # 
    # Params:
    #   task_id: String, required
    #   file_blob: File blob, required
    #   filename: String, required
    #   mimetype: String, required
    #   metadata: Object, optional
    #   user_id: String, required
    # 
    # Returns: Object, metadata of uploaded file
    #   - _id: String
    #   - name: String
    #   - type: String
    #   - size: Number
    #   - metadata: Object
    #   - user_uploaded: String
    #   - date_uploaded: Date
    #   - storage_type: String
    #   - (extra properties returned by the file system)
    throw @_error "not-implemented"
