_.extend JustdoAiKit.prototype,
  _createStreamRequestPublicationOptionsSchema: 
    req_id:
      type: String
    template_id:
      type: String
    template_data: # template_data is sanitized by the requestGeneratorOptionsSchema inside the request template.
      type: Object
      blackbox: true
    cache_token: # Optional token to use for caching the response.
                 # If there is a cached response corresponding to this cache_token,
                 # it will be published instead of creating a new stream.
      type: String
      optional: true
    pre_register_id: # Works as user_id/performed_by for non logged-in users
      type: String
      optional: true
    simplify_response:
      type: Boolean
      optional: true
    api_provider:
      type: String
      optional: true

  _attachCollectionsSchemas: -> 
    self = @

    if Meteor.isServer
      @query_collection.attachSchema new SimpleSchema
        provider:
          type: String
        resource:
          type: String
        req_id:
          type: String
        req:
          type: Object
        "req.template_id":
          type: String
        "req.data":
          type: Object
          blackbox: true
        "req.jdv": # Stands for JustDo Version
          type: String
        simplify_response:
          type: Boolean
          optional: true
        res:
          type: Object
          blackbox: true
          optional: true
        err:
          type: Object
          blackbox: true
          optional: true
        aborted:
          type: Boolean
          optional: true
        choice:
          type: String
          allowedValues: ["a", "p", "d"] # a: all, p: partial, d: decline
          optional: true
        choice_data:
          type: Match.OneOf(Object, String)
          blackbox: true
          optional: true
        choice_ts:
          type: Date
          optional: true
        performed_by:
          type: String
          optional: true
        pre_register_id:
          type: String
          optional: true
        createdAt:
          type: Date
          autoValue: ->
            if this.isInsert
              return new Date()
            else if this.isUpsert
              return { $setOnInsert: new Date() }
            else
              this.unset()
              return
      
      Meteor.users.attachSchema new SimpleSchema
        "justdo_projects.first_jd.ai_cache_token":
          # If the user chose one of the cached responses, this will be the token of the cached response.
          type: String
          optional: true
        "justdo_projects.first_jd.ai_prompt":
          # The prompt that was used to generate the first_jd.justdo_tasks
          type: String
          optional: true
        "justdo_projects.first_jd.pre_register_id":
          type: String
        "justdo_projects.jd_creation_request.ai_cache_token":
          # If the user chose one of the cached responses, this will be the token of the cached response.
          type: String
          optional: true
        "justdo_projects.jd_creation_request.ai_prompt":
          # The prompt that was used to generate the jd_creation_request.justdo_tasks
          type: String
          optional: true
        "justdo_projects.jd_creation_request.pre_register_id":
          type: String
          optional: true

    return