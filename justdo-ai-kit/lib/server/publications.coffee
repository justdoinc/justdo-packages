_.extend JustdoAiKit.prototype,
  _setupPublications: -> 
    self = @

    Meteor.publish "createStreamRequest", (options) ->
      publish_this = @
      if not @userId? and not (pre_register_id = options.pre_register_id)?
        throw self._error "missing-argument", "For non logged-in user, pre_register_id is required."

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          new SimpleSchema(_.extend({}, self._createStreamRequestPublicationOptionsSchema)),
          options,
          {self: self, throw_on_error: true}
        )
      options = cleaned_val

      req_id = options.req_id

      request_template = self.requireRequestTemplate options.template_id
      template_data = _.extend {}, options.template_data,
        cache_token: options.cache_token

      if not @userId? and (request_template.allow_anon isnt true)
        throw self._error "login-required"

      # Publish cached response if available.
      if request_template.cachedResponseCondition?.call publish_this, template_data, req_id, @userId
        request_template.cachedResponsePublisher.call publish_this, template_data, req_id, @userId
        publish_this.ready()
        return

      options.template = request_template
      delete options.template_id
      stream = await self.newStream options, @userId

      # Add event handler to allow client-side to stop the stream.
      stopStream = ->
        stream.stop()
        publish_this.ready()
        return
      stop_event_handler = self.once "stop_stream_#{req_id}", stopStream
      publish_this.onStop ->
        self.off "stop_stream_#{req_id}", stopStream
        stream.stop()
        return

      res_data = 
        intermediate_res: ""

      item_seq_id = 0
      stream
        .on "parsed_item", (parsed_item) ->
          parsed_item = request_template.streamedResponseParser parsed_item, template_data, req_id
          parsed_item.seqId = item_seq_id
          item_seq_id += 1
          publish_this.added "ai_response", parsed_item._id, parsed_item
          return
        .on "end", ->
          publish_this.ready()
          return
        .on "error", (err) ->
          publish_this.error err
          return

      return
