mock_collection = new Mongo.Collection(null)

_.extend JustdoAccounts.prototype,
  _setupCollectionsHooks: ->
    Meteor.users.before.remove (user_id, doc) =>
      url = doc.profile?.profile_pic
      if url?
        if doc._profile_pic_metadata?
          APP.filestack_base?.cleanupRemovedFile doc._profile_pic_metadata

    Meteor.users.before.update (user_id, doc, fields, modifier, options) =>
      try
        # A bulletproof way to check the doc + modifier result:
        # We use a null-backed collection to simulate the effect of this action
        # this could fail if one of the arguments we're passed is oncompatible
        # with a null-backed meteor collection.

        # XXX use JustdoHelpers.applyMongoModifiers()
        #         note that we also have: JustdoHelpers.getCollection2Simulator() but it
        #         isn't necessary here.

        mock_collection.remove {}
        mock_collection.insert doc
        mock_collection.update doc._id, modifier
        new_doc = mock_collection.findOne()
        mock_collection.remove {}

        url = doc.profile?.profile_pic
        new_url = new_doc.profile?.profile_pic
        if url? and url != new_url
          if doc._profile_pic_metadata?
            APP.filestack_base?.cleanupRemovedFile doc._profile_pic_metadata
            # Remove the metadata unless the update is overwriting the metadata
            if new_doc._profile_pic_metadata?.id == doc._profile_pic_metadata?.id
              modifier.$unset ?= {}
              modifier.$unset._profile_pic_metadata = true

      catch error
        @logger.error "before-update-remove-files-failed", error.stack

    return
