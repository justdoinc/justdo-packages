Busboy = require "busboy"

Router.route JustdoTaskPane.froala_file_upload_route, ->
  req = @request
  res = @response

  if not (user_doc = JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req))?
    res.statusCode = 403
    res.end "AUTH FAILED"

    return

  task_id = null
  filename = null
  mimetype = null
  metadata = {}
  user_id = user_doc._id
  file_data_buffers = []
  

  busboy = new Busboy
    headers: req.headers
  
  busboy.on "field", (fieldname, val) ->
    if (fieldname == "task_id")
      task_id = val
    
    return
    
  busboy.on "file", (_fieldname, _file, _filename, _encoding, _mimetype) ->
    filename = _filename
    mimetype = _mimetype
    _file.on "data", (data) ->
      file_data_buffers.push data

    return
  
  busboy.on "finish", Meteor.bindEnvironment ->
    file = Buffer.concat file_data_buffers

    try
      result = APP.tasks_file_manager_plugin.tasks_file_manager.uploadAndRegisterFile(task_id, file, filename, mimetype, metadata, user_id)
    catch err
      console.error "Froala uploader failed to upload file", err

      res.statusCode = 500
      res.end "UPLOAD FAILED"

      return

    res.statusCode = 200
    res.end JSON.stringify
      link: "#{APP.tasks_file_manager_plugin.tasks_file_manager.getFileDownloadPath task_id, result.id}"

    return

  req.pipe busboy

  return
,
  name: "froala-file-upload"
  where: "server"