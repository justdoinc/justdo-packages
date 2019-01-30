_.extend JustdoGlobalActivityLog.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jdGlobalChangelog", (options) -> # Note the use of -> not =>, we need @userId
      # Publishes changelogs to the JustdoGlobalActivityLog.global_changelog_collection_name
      # 

      # Security note:
      #
      # options structures is thoroughly checked by channel_obj.globalChangelogPublicationHandler()
      # projects: 
      # if @userId is not allowed to access the channel, exception will be thrown in the attempt
      # to generate channel_obj.

      check options, Match.Maybe(Object)

      return self.globalChangelogPublicationHandler(@, options, @userId)
