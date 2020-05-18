Router.route JustdoTaskPane.froala_file_upload_route, ->
  if not (user_doc = JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(@request))?
    @response.statusCode = 403
    @response.end "AUTH FAILED"

    return

  file = ""
  @request.on "data", (chunk) =>
    file += chunk.toString() 

    return

  @request.on "end", Meteor.bindEnvironment =>
    task_id = "59Me4d32o5GG6Bd4Y" # TODO
    filename = "testing.txt" 
    mimetype = "text/plain"
    metadata = {}
    user_id = user_doc._id

    try
      result = APP.tasks_file_manager_plugin.tasks_file_manager.uploadAndRegisterFile(task_id, file, filename, mimetype, metadata, user_id)
    catch err
      console.error "Froala uploader failed to upload file", err

      @response.statusCode = 500
      @response.end "UPLOAD FAILED"

      return

    @response.statusCode = 200
    @response.end JSON.stringify({link: "/file-stack-id/#{result.id}"})

    return

  return
,
  name: "froala-file-upload"
  where: "server"