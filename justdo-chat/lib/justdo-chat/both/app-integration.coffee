# This file is the last file we load for this package and it's loaded in both
# server and client (keep in mind! don't put non-secure code that shouldn't be
# exposed to clients here).
#
# Uncomment to create an instance automatically on server/client init
#
# If you uncomment this, uncomment in package.js the load of meteorspark:app
# package.
#
# Avoid this step in packages that implements pure logic that isn't specific
# to the JustDo app. Pure logic packages should get all the context they need
# to work with collections/other plugins instances/etc. as options.

# **Method A:** If you aren't depending on any env variable just comment the following

# APP.justdo_chat = new JustdoChat()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

_justdo_chat_dep = new Tracker.Dependency()
APP.getJustdoChatObject = ->
  _justdo_chat_dep.depend()

  return APP.justdo_chat

setJustdoChatObject = (justdo_chat) ->
  APP.justdo_chat = justdo_chat

  _justdo_chat_dep.changed()

  return

APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

  APP.collections.JDChatChannels = new Mongo.Collection("jd_chat_channels")
  APP.collections.JDChatMessages = new Mongo.Collection("jd_chat_messages")

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    channels_collection: APP.collections.JDChatChannels
    messages_collection: APP.collections.JDChatMessages
  
  files_helpers = 
    getChannelType: (channel_object) ->
      return channel_object.channel_type
    
  # justdo-files
  if env.JUSTDO_FILES_ENABLED is "true"
    _.extend files_helpers,
      file_storage_type: "justdo-files"
      subscribeToFilesCollection: (channel_object) ->
        channel_type = @getChannelType channel_object
        
        if channel_type is "task"
          return Meteor.subscribe "jdfTaskFiles", channel_object.task_id

        return
      isFileExist: (file_id, channel_object) ->
        channel_type = @getChannelType channel_object

        if channel_type is "task"
          return APP.justdo_files.isFileExist file_id, channel_object.task_id

        return false
      downloadFile: (file_id, channel_object) ->
        channel_type = @getChannelType channel_object

        if channel_type is "task"
          return APP.justdo_files.downloadFile file_id

        return
      uploadFile: (file, upload_file_options={}, channel_object, cb) ->
        if not upload_file_options.meta?
          upload_file_options.meta = {}
        _.extend upload_file_options.meta,
          from_chat: true
          storage_type: @file_storage_type

        if channel_object.channel_type is "task"
          upload_file_options.task_id = channel_object.task_id
          
          try
            upload = APP.justdo_files.uploadFile(file, upload_file_options)
          catch err
            cb err
            return

          upload.on "end", (err, file_obj) ->
            if err?
              cb err
              return
            cb null, file_obj
            return

          upload.start()

          return

        return
  
  _.extend options, files_helpers

  if Meteor.isClient
    options.hash_requests_handler = APP.hash_requests_handler

  setJustdoChatObject new JustdoChat options

  if Meteor.isClient
    APP.justdo_chat._setupHtmlTitlePrefixController()
    APP.justdo_chat._setupReceivedMessagesSoundNotification()
    APP.justdo_chat._setupBottomWindows()
    APP.justdo_chat._setupHashRequests()

  return
