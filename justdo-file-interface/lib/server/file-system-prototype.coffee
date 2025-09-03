_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Server-only methods required to register a file system
  # 
  uploadTaskFileAsync: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
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
    # Returns: File metadata object, guarenteed to have the following properties:
    #   - _id: String
    #   - name: String
    #   - type: String
    #   - size: Number
    #   - (extra properties returned by the file system)
    throw @_error "not-implemented"
