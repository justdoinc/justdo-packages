Router.route "/froala-file-upload", (a, b, c) ->
  console.log @request.method
  file = ""
  @request.on "data", (chunk) ->
    file += chunk.toString() 
  @request.on "end", ->
    task_id = "RsncYBK8nD7FEPaEE"
    filename = "testing.png"
    mimetype = "image/png"
    metadata = {}
    user_id = "JgAMHDs33vMTLZsCs"
    Meteor.bindEnvironment ->
      result = APP.tasks_file_manager_plugin.tasks_file_manager.uploadAndRegisterFile(task_id, file, filename, mimetype, metadata, user_id)
      console.log result

,
  name: "/froala-img-upload"
  where: "server"
