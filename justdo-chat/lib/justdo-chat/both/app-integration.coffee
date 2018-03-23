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

  APP.justdo_chat = new JustdoChat options

  if Meteor.isClient
    APP.justdo_chat._setupHtmlTitlePrefixController()
    APP.justdo_chat._setupReceivedMessagesSoundNotification()
    APP.justdo_chat._setupBottomWindows()

  return
