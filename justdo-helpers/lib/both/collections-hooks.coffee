mock_collection = new Mongo.Collection(null)

_.extend JustdoHelpers,
  applyMongoModifiers: (doc, modifiers, cb) ->
    # Gets a doc and applies the given Mongo modifiers on it, calls cb
    # with the resulted document:
    #
    #   cb(err, modified_doc)
    #
    # IMPORTANT! on the server cb is called on the same js tick in a sync
    # way, on the client it's async.
    #
    # On the server, will return the cb output
    #
    # A bulletproof way to check the doc + modifiers result:
    # We use a null-backed collection to simulate the effect of this action
    # this could fail if one of the arguments we're passed is oncompatible
    # with a null-backed meteor collection.

    try
      if Meteor.isServer
        # On the server, all the mongo ops are sync,
        # which makes our code much simpler.
        mock_collection.insert doc
        mock_collection.update doc._id, modifiers
        new_doc = mock_collection.findOne(doc._id)
        mock_collection.remove doc._id

        return cb(undefined, new_doc)
      else
        # If doc provided with _id, we want to avoid situation where
        # more than one call for a document with this _id will be done
        # to applyMongoModifiers(), we change the doc _id to a temporary
        # id.
        #
        # Before returning the processed doc we will set its id back to the
        # original one. 
        if (original_id = doc._id)?
          temp_id = original_id + Date.now()

          # extend to avoid changing the original doc!
          doc = _.extend {}, doc, {_id: temp_id}

        mock_collection.insert doc, (e, id) ->
          if e?
            return cb(e)
          
          mock_collection.update id, modifiers, (e) ->
            removeDoc = ->
              mock_collection.remove id

            if e?
              removeDoc()

              return cb(e)

            new_doc = mock_collection.findOne id

            if original_id?
              # Return the processed doc with the original_id
              # as the user of this method expect it to be returned
              new_doc._id = original_id

            return cb(undefined, new_doc)

            removeDoc()

            return
            
    catch e
      return cb(e)

    return
      
