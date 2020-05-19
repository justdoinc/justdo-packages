Busboy = require "busboy"

Router.route JustdoTaskPane.froala_file_upload_route, ->
  req = @request
  res = @response

  if not (user_doc = JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req))?
    res.statusCode = 403
    res.end "AUTH FAILED"

    return

  task_id_ = null
  filename_ = null
  mimetype_ = null
  metadata_ = {}
  user_id_ = user_doc._id
  file_data_buffers = []
  

  busboy = new Busboy
    headers: req.headers
  
  busboy.on "field", (fieldname, val) ->
    if (fieldname == "task_id")
      task_id_ = val
    
  busboy.on "file", (fieldname, file, filename, encoding, mimetype) ->
    filename_ = filename
    mimetype_ = mimetype
    file.on "data", (data) ->
      file_data_buffers.push data

    return
  
  busboy.on "finish", Meteor.bindEnvironment ->
    file = Buffer.concat file_data_buffers

    try
      result = APP.tasks_file_manager_plugin.tasks_file_manager.uploadAndRegisterFile(task_id_, file, filename_, mimetype_, metadata_, user_id_)
    catch err
      console.error "Froala uploader failed to upload file", err

      res.statusCode = 500
      res.end "UPLOAD FAILED"

      return

    res.statusCode = 200
    res.end JSON.stringify
      link: "#{APP.tasks_file_manager_plugin.tasks_file_manager.getFileDownloadPath task_id_, result.id}"

    return

  req.pipe busboy

  return
,
  name: "froala-file-upload"
  where: "server"