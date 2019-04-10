_.extend TasksFileManager.prototype,
  requireLogin: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check user_id, String

    return true

  requireTask: (task_id) ->
    task = @tasks_collection.findOne { _id: task_id }
    if not task?
      throw @_error "task-not-found"

    return task

  requireUserTask: (task_id, user_id) ->
    task = @tasks_collection.findOne { _id: task_id, users: user_id }
    if not task?
      throw @_error "task-not-found"

    return task

  requireTaskDoc: (task_id, user_id) ->
    # user_id is optional, if isn't provided, we will regard the request as a "system"
    # request.
    #
    # If provided, the user has to have access to the task.

    if user_id?
      task = @requireUserTask task_id, user_id
    else
      task = @requireTask task_id

    return task

  requireFile: (task, file_id) ->
    check task, Object
    if not task.files?
        throw @_error "file-not-found"

    check task.files, [Object]

    file = _.findWhere task.files, { id: file_id }
    if not file?
      throw @_error "file-not-found"

    return file

  requireFilestackUrl: (url) ->
    check url, String

    # XXX: For improved security check that this file belongs to our account

    regex = /^https\:\/\/(www\.filestackapi\.com|cdn\.filestackcontent\.com)/
    if not regex.test url
      throw @_error "file-url-invalid"

  registerUploadedFiles: (task_id, files, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    check files, [Object]
    _.each files, (file) => @requireFilestackUrl file.url

    # takes a url like:          https://www.filestackapi.com/api/file/KW9EJhYtS6y48Whm2S6D
    # and returns a handle like: KW9EJhYtS6y48Whm2S6D
    # should be a globally unique id supplied by filestack
    getHande = (url) =>
      check(url, String)
      regex = /[^\\\/]+$/
      match = url.match(regex)
      return match?[0]

    upload_date = new Date()

    files_to_upload = _.map files, (file) ->
      id: getHande file.url
      title: file.filename
      url: file.url
      size: file.size
      type: file.mimetype
      metadata: file.metadata
      user_uploaded: user_id
      date_uploaded: upload_date

    APP.collections.Tasks.update
      _id: task_id
    ,
      $set:
        updated_by: user_id
      $push:
        files:
          $each: files_to_upload

    _.each files_to_upload, (file) =>
      @logger.debug("New activity #{"file_uploaded"} by user #{user_id} - extra data: #{JSON.stringify({ title: file.title, size: file.size })}\n Message that will be presented: #{"User {{user}} uploaded a new file: {{title}} ({{size}} bytes)"}")

    return files_to_upload

  uploadAndRegisterFile: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
    upload_policy = @getUploadPolicy(task_id)

    location_and_path = @getStorageLocationAndPath(task_id)

    upload_url = "https://www.filestackapi.com/api/store/#{location_and_path.location}" +
      "?key=#{@filestack_api_key}" +
      "&policy=#{upload_policy.policy}" +
      "&signature=#{upload_policy.signature}" +
      "&filename=#{encodeURIComponent(filename)}" +
      "&mimetype=#{mimetype}" +
      "&path=#{location_and_path.path}"

    upload_result = HTTP.post upload_url, { content: file_blob }

    file = upload_result.data

    # For some reason this data isn't being returned from filestack, maybe
    # because we supplied it on our end (see line 132)
    file.mimetype = mimetype

    # Set any user supplied metadata
    file.metadata = metadata

    results = @registerUploadedFiles task_id, [file], user_id

    return results[0]

  getDownloadLink: (task_id, file_id, user_id) ->
    if user_id?
      task = @requireUserTask task_id, user_id
    else
      task = @requireTask task_id

    file = @requireFile task, file_id

    # This policy is to prevent users from abusing our filestack and S3
    # accounts, it doesn't affect a user's ability to associate uploaded
    # files with a task.
    policy =
      # Very short expiry time, the client api auto-downloads this file
      # immediately, so we just need time for network and a few extra
      # minutes for time-syncronization differences.
      expiry: (Date.now() / 1000) + (60 * 5) # 5 minutes in the future

      # This token can only be used to download this file, not any other
      # file
      handle: file_id

      # This token can only be used to download, not upload or any other
      # action
      call: ["read"]

    # Signs our policy by jsonifying it, base64 encoding it and applying
    # an hmac-sha256 signature algorithm.
    signature = APP.filestack_base.signPolicy policy

    # XXX should we log this? I don't think so.

    return "#{file.url}?signature=#{signature.hmac}&policy=#{signature.encoded_policy}"

  renameFile: (task_id, file_id, new_title, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    file = @requireFile task, file_id

    @tasks_collection.update
      _id: task_id
      "files.id": file_id
    ,
      $set:
        "files.$.title": new_title

    @logger.debug("New activity #{"file_renamed"} by user #{user_id} - extra data: #{JSON.stringify({ new_title: new_title, old_title: file.title })}\n Message that will be presented: #{"User {{user}} renamed a file from {{old_title}} to {{new_title}}."}")

  # INTERNAL ONLY
  # Sets metadata on a file
  setFileMetadata: (task_id, file_id, metadata, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    file = @requireFile task, file_id

    modifier = {}
    for key, value of metadata
      # IMPORTANT: If users are ever allowed to call this method, the values
      # need to be sanitized for nosql injection
      modifier["files.$.metadata.#{key}"] = value

    @tasks_collection.update
      _id: task_id
      "files.id": file_id
    ,
      $set: modifier

  removeFile: (task_id, file_id, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    file = @requireFile task, file_id

    # Remove the file from our file store (filestack/s3)
    APP.filestack_base.cleanupRemovedFile file

    @tasks_collection.update
      _id: task_id
    ,
      $pull:
        "files":
          id: file_id

    # If there are no more files, we should remove the array
    # We no longer support $unset on the Tasks collection, just leave empty array.
    # @tasks_collection.update
    #   _id: task_id
    #   "files": []
    # ,
    #   "$unset":
    #     "files": true

    @logger.debug("New activity #{"file_removed"} by user #{user_id} - extra data: #{JSON.stringify({ title: file.title, size: file.size })}\n Message that will be presented: #{"User {{user}} removed a file {{title}}."}")

  getUploadPolicy: (task_id, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    location_and_path = @getStorageLocationAndPath(task_id)

    # This policy is to prevent users from abusing our filestack and S3
    # accounts, it doesn't affect a user's ability to associate uploaded
    # files with a task.
    policy =
      # Short expiry time, limiting the usefulness of this token if users
      # capture it from the browser session.
      # This does necessitate frequently refreshing the token on the client
      expiry: Date.now() / 1000 + 1 * 60 * 60 # 1 hour

      # Force user to place files in a path related to the task they have
      # access for, making it easier to cleanup the consequences of an
      # abused token.
      path: location_and_path.path

      # Limit users to upload only, to download they'll need a download
      # token, making this token fairly useless for abuse or if lost.
      call: ["store", "pick"]

    # Signs our policy by jsonifying it, base64 encoding it and applying
    # an hmac-sha256 signature algorithm.
    signature = APP.filestack_base.signPolicy policy

    return {
      signature: signature.hmac
      policy: signature.encoded_policy
    }

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
