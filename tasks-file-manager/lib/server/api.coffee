_.extend TasksFileManager.prototype,
  _immediateInit: ->
    # Register custom change types for changelog
    @_registerCustomChangeTypes()
    
    return

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

    # From the perspective of flows received from Meteor Methods, note that all
    # the methods/publications as of now Dec. 19th, 2024, are all checking for
    # logged-in user.
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
      $inc:
        [TasksFileManager.files_count_field_id]: files_to_upload.length
      $push:
        files:
          $each: files_to_upload

    _.each files_to_upload, (file) =>
      APP.tasks_changelog_manager.logChange
        field: "files.#{file.id} upload"
        label: JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, "files")?.label
        change_type: TasksFileManager.file_upload_change_type
        task_id: task_id
        by: user_id
        undo_disabled: true
        bypass_time_filter: true
        data:
          file_metadata: file

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

    return _.extend {}, results[0], {storage_type: "filestack"}

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

  getDownloadPolicySignature: (file_id) ->
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

    return signature

  getConvertPolicySignature: (task_id, file_id) ->
    location_and_path = @getStorageLocationAndPath(task_id)

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
      call: ["store", "convert"]

      # Force user to place files in a path related to the task they have
      # access for, making it easier to cleanup the consequences of an
      # abused token.
      path: location_and_path.path

    # Signs our policy by jsonifying it, base64 encoding it and applying
    # an hmac-sha256 signature algorithm.
    signature = APP.filestack_base.signPolicy policy

    return signature

  _simpleDownloadLink: (file) ->
    # IMPORTANT In this method we assume accesss rights checked by the caller!

    signature = @getDownloadPolicySignature(file.id)

    return "#{file.url}?signature=#{signature.hmac}&policy=#{signature.encoded_policy}"

  _getFileDimensionLinkCalc: (task_id, file) ->
    signature = @getConvertPolicySignature(task_id, file.id)
    security_string = "/security=p:#{signature.encoded_policy},s:#{signature.hmac}"

    return "https://cdn.filestackcontent.com/imagesize#{security_string}/#{file.id}"

  getDownloadLink: (task_id, file_id, user_id) ->
    task = @requireTaskDoc(task_id, user_id)
    file = @requireFile task, file_id

    return @_simpleDownloadLink(file)

  _getPreviewDownloadLinkOptionsSchema: new SimpleSchema
    width:
      type: Number

      allowedValues: [512, 1024]

      defaultValue: 512

      optional: true
    
    cropHeightForNonImgSrc:
      type: Number
      
      allowedValues: [256, 512, 1024]
      
      defaultValue: 256

      optional: true

    output:
      type: String
      optional: true
      allowedValues: ["pdf", "jpg", "mp4"]

  _getProcessedFileLink: (task, file, process_str, processed_file_id, processed_file_ext) ->
    # IMPORTANT!!! IF YOU CHANGE THIS COMMENT UPDATE ALSO filestack-base/lib/server/api.coffee
    #
    # We place the references to the previews under the _secret subdocument which is not
    # published.
    #
    # This isn't done for security reason, but to prevent a pitfall that might cause redundant
    # invalidations of view.
    #
    # Since we are modifying here the task document itself, if, when querying the document,
    # the client-side developer isn't careful enough to limit the tracked fields only to
    # those he needs. Once we will update the preview file, we will cause his view to invalidate
    # and another request to get the file will be triggered.
    #
    # The preview subdocument should be structured as follows:
    #
    # _secret: {
    #   files_previews: {
    #     "file_id": {
    #       "vVERSION_preview_id1": preview_file_info_object,
    #       "vVERSION_preview_id2": preview_file_info_object
    #     }
    #   }
    # }
    #
    # It is critical that this structure will be kept in future versions
    # as well, for APP.filestack_base.cleanupRemovedFile() to work properly.
    #
    # IMPORTANT!!! IF YOU CHANGE THIS COMMENT UPDATE ALSO filestack-base/lib/server/api.coffee

    task_id = task._id
    file_id = file.id

    if (preview_file = task._secret?.files_previews?[file_id]?[processed_file_id])?
        return @_simpleDownloadLink(preview_file)

      location_and_path = @getStorageLocationAndPath(task_id)
      signature = @getConvertPolicySignature(task_id, file_id)
      security_string = "/security=p:#{signature.encoded_policy},s:#{signature.hmac}"

      processed_file_name = "#{file.id}-convert-#{processed_file_id}.#{processed_file_ext}"
      store_task = """/store=path:"#{encodeURIComponent(location_and_path.path)}",filename:"#{processed_file_name}",location:#{location_and_path.location}"""
      
      convert_url = "https://cdn.filestackcontent.com#{security_string}#{process_str}/#{store_task}/#{file_id}"

      convert_result = HTTP.get convert_url
      if not (convert_result?.statusCode == 200)
        console.warn "Image file conversion failed"

        return @_simpleDownloadLink(file)

      converted_file_doc = convert_result.data

      converted_file_doc.id = converted_file_doc.url.replace(/.*\//, "")

      # Ensure that we don't have already a file that been converted with the same instruction
      up_to_date_task = @tasks_collection.findOne(task_id)
      if (previously_converted_file = up_to_date_task?._secret?.files_previews?[file_id]?[processed_file_id])?
        @logger.info "Removing existing stored converted file (redundant convert occured, if you see this message frequently, might indicate a bug with images preview conversion process)", previously_converted_file.key

        # We found that a request to perform this conversion already happened.
        # A case like this can happen when multiple conversion requests received at the same time.
        # Remove the previously converted file, to keep only the one we got now.

        # This isn't theoretical, I saw it happening in real world (Daniel C.)

        Meteor.defer =>
          # Defer to prevent blocking
          APP.filestack_base.cleanupRemovedFile previously_converted_file

          return

      query = {_id: task_id}
      update = 
        $set:
          "_secret.files_previews.#{file_id}.#{processed_file_id}": converted_file_doc

      # We don't want the unmerged publications raw fields, nor any other hook to trigger as a result
      # of that update, hence the use of the rawCollection()
      APP.justdo_analytics.logMongoRawConnectionOp(@tasks_collection._name, "update", query, update)
      @tasks_collection.rawCollection().update query, update, Meteor.bindEnvironment (err) ->
        if err?
          console.error(err)

          return

        return

      return @_simpleDownloadLink(converted_file_doc)

  getPreviewDownloadLink: (task_id, file_id, version, options, user_id) ->
    check version, Number
    check options, Object

    if version != 1
      throw @_error "api-version-not-supported", "At the moment only version 1 is supported for getPreviewDownloadLink"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getPreviewDownloadLinkOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    task = @requireTaskDoc(task_id, user_id)
    file = @requireFile task, file_id
  
    if file.type.indexOf("application/pdf") is 0
      options.output = "pdf"
    else if file.type.indexOf("image/") is 0
      options.output = "jpg"
    else if file.type.indexOf("video/") is 0
      options.output = "mp4"

    if options.output == "pdf"
      if file.type == "application/pdf"   
        # pdf to pdf
        return @_simpleDownloadLink file
      else                                
        # others to pdf
        # XXX supported file formats
        return @_getProcessedFileLink task, file, "/output=f:pdf", "v#{version}_pdf", "pdf"
    else if options.output == "mp4"
      return @_simpleDownloadLink file
    else if options.output == "jpg"       
      if file.type.indexOf("image/") == 0
      # image to jpg
        if not (file_dimension = task._secret?.files_dimensions?[file_id])?
            file_dimension_result = HTTP.get @_getFileDimensionLinkCalc(task_id, file)
            if not (file_dimension_result?.statusCode == 200)
              console.warn "Failed to fetch file dimensions"

              return @_simpleDownloadLink(file)
            file_dimension = file_dimension_result.data

            query = {_id: task_id}
            update = 
              $set:
                "_secret.files_dimensions.#{file_id}": file_dimension

            # We don't want the unmerged publications raw fields, nor any other hook to trigger as a result
            # of that update, hence the use of the rawCollection()
            APP.justdo_analytics.logMongoRawConnectionOp(@tasks_collection._name, "update", query, update)
            @tasks_collection.rawCollection().update query, update, Meteor.bindEnvironment (err) ->
              if err?
                console.error(err)

                return

              return

        processed_file_ext = file.type.replace("image/", "").replace("jpeg", "jpg")
        
        proccess_str = ""

        if file_dimension.width > options.width
          proccess_str +=
            "/resize=width:#{options.width}"

        proccess_str +=
          "/rotate=deg:exif" +
          "/compress"

        return @_getProcessedFileLink task, file, proccess_str, "v#{version}_w#{options.width}", processed_file_ext
      else 
        # others to jpg
        proccess_str = "/output=f:jpg" +
          "/resize=width:#{options.width}" +
          "/crop=dim:[0,0,#{options.width},#{options.cropHeightForNonImgSrc}]" +
          "/rotate=deg:exif" +
          "/compress"

        return @_getProcessedFileLink task, file, proccess_str, "v#{version}_w#{options.width}h#{options.cropHeightForNonImgSrc}", "jpg" 
      
      return null

  renameFile: (task_id, file_id, new_title, user_id) ->
    task = @requireTaskDoc(task_id, user_id)

    file = @requireFile task, file_id

    @tasks_collection.update
      _id: task_id
      "files.id": file_id
    ,
      $set:
        "files.$.title": new_title

    APP.tasks_changelog_manager.logChange
      field: "files.#{file_id} rename"
      label: JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, "files")?.label
      change_type: TasksFileManager.file_rename_change_type
      task_id: task_id
      by: user_id
      undo_disabled: true
      bypass_time_filter: true
      old_value: file.title
      new_value: new_title
      data:
        # We store the file metadata obj PRE title update to avoid fetching it again,
        # since the only difference is the title, which we already have.
        file_metadata: file

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
    APP.filestack_base.cleanupRemovedFile file, {cleanup_from_task_document: task}

    APP.tasks_changelog_manager.logChange
      field: "files.#{file_id} remove"
      label: JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, "files")?.label
      change_type: TasksFileManager.file_remove_change_type
      task_id: task_id
      by: user_id
      undo_disabled: true
      bypass_time_filter: true
      data:
        file_metadata: file

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
