# For pseudo collections names are defined in both/static-settings.coffee

APP.collections.JDChatInfo = new Mongo.Collection JustdoChat.jdc_info_pseudo_collection_name

APP.collections.JDChatRecentActivityChannels = new Mongo.Collection JustdoChat.jdc_recent_activity_channels_collection_name
APP.collections.JDChatRecentActivityMessages = new Mongo.Collection JustdoChat.jdc_recent_activity_messages_collection_name