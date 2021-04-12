Fiber = Npm.require "fibers"
stream = require "stream"

DDPOutputObjectsStream = ->
  stream.Transform.call @, {objectMode: true}

  return

Util.inherits DDPOutputObjectsStream, stream.Transform

_.extend DDPOutputObjectsStream.prototype,
  _transform: (chunk, encoding, callback) ->
    @push(chunk)

    callback()

    return

sockets_threshold_for_warning = 10

open_fake_sockets = 0
FakeDdpSocket = ->
  EventEmitter.call @

  fake_socket =
    send: @_socketSend.bind(@)
    close: -> return
    headers: []

  ddp_connect_message =
    msg: "connect"
    version: "pre1"
    support: ["pre1"]

  Meteor.default_server._handleConnect(fake_socket, ddp_connect_message)
  open_fake_sockets += 1

  if open_fake_sockets > sockets_threshold_for_warning
    console.warn "There are more than #{sockets_threshold_for_warning} fake sockets (total: #{open_fake_sockets})"

  @socket = fake_socket

  @session = fake_socket._meteorSession
  @server = fake_socket._meteorSession.server
  @publish_handlers = fake_socket._meteorSession.server.publish_handlers
  @methods_handlers = fake_socket._meteorSession.server.method_handlers

  # Change @session.send so it won't stringify the message by default
  # we'll decide if/when/and how to stringify the message
  @session.send = (msg, simple_ejson_stringify) ->
    # See file: ddp-server/livedata_server.js for the original Session.send definition
    self = @

    if self.socket
      if Meteor._printSentDDP
        Meteor._debug("Sent DDP", msg)
      self.socket.send(msg)

    return

  @disconnected = false

  return @

Util.inherits FakeDdpSocket, EventEmitter

_.extend FakeDdpSocket.prototype,
  _socketSend: (msg) ->
    @emit "socket_send", msg

    @socketSend(msg)

    return

  socketSend: (msg) -> console.log msg

  subscribe: (pub_name, args_arr, sub_id) ->
    if not sub_id?
      sub_id = Random.id()

    @session._startSubscription(@publish_handlers[pub_name], sub_id, args_arr, pub_name)

    return sub_id

  unsubscribe: (sub_id) ->
    @session._stopSubscription(sub_id)

    return

  setUserId: (user_id) ->
    if _.isString(user_id)
      try
        @session._setUserId(user_id)
      catch e
        console.error "Failed to set fakeDdpSocket user_id", e

        @disconnect() # No matter

        throw e

    return

  disconnect: ->
    if @disconnected
      return

    @disconnected = true

    open_fake_sockets -= 1

    Meteor.default_server._removeSession(@socket._meteorSession)

    return

JsDdpSocket = ->
  FakeDdpSocket.call @

  return @

Util.inherits JsDdpSocket, FakeDdpSocket

_.extend JsDdpSocket.prototype,
  socketSend: (msg) -> return

  setupMessagesListener: (cb) ->
    controller =
      stop: => @removeListener "socket_send", controller.listener

    controller.listener = (msg) -> cb(controller, msg)

    @on "socket_send", controller.listener

    return controller

  getDdpCall: ->
    # To be implemented
    return

  getDdpSubscribePreReadyPayloadStream: (pub_name, pub_args_arr) ->
    sub_id = Random.id()
    ddp_output_stream = new DDPOutputObjectsStream()

    @setupMessagesListener (controller, msg) =>
      if msg.msg == "ready"
        controller.stop()

        @unsubscribe(sub_id)

        ddp_output_stream.end(msg)
        
        return

      ddp_output_stream.write(msg)

      return

    # Defer to give a chance to attach the data/end events hooks to
    # avoid data from being buffered.
    Meteor.defer =>
      sub_id = @subscribe(pub_name, pub_args_arr, sub_id)

      return

    return ddp_output_stream

  getDdpSubscribePreReadyPayloadSync: (pub_name, pub_args_arr) ->
    # Returns an array with all the streamed objects of
    # getDdpSubscribePreReadyPayloadStream (Fake Fiber based sync)

    fiber = Fiber.current
    if not (fiber = Fiber.current)?
      throw @_error "no-fiber"

    ddp_output_stream = @getDdpSubscribePreReadyPayloadStream(pub_name, pub_args_arr)

    pre_ready_payload_messages = []

    ddp_output_stream.on "data", (msg) ->
      pre_ready_payload_messages.push msg

      return

    ddp_output_stream.on "end", ->
      fiber.run()

      return

    Fiber.yield()

    return pre_ready_payload_messages

JustdoHelpers.FakeDdpSocket = FakeDdpSocket
JustdoHelpers.JsDdpSocket = JsDdpSocket

_.extend JustdoHelpers,
  getJsDdpSocketForUser: (user_id) ->
    js_ddp_socket = new JustdoHelpers.JsDdpSocket()

    if user_id?
      js_ddp_socket.setUserId(user_id)

    return js_ddp_socket

  getDdpSubscribePreReadyPayloadForUserOutputStream: (pub_name, pub_args_arr, user_id) ->
    js_ddp_socket = @getJsDdpSocketForUser(user_id)

    ddp_output_stream = js_ddp_socket.getDdpSubscribePreReadyPayloadStream(pub_name, pub_args_arr)

    ddp_output_stream.on "end", ->
      js_ddp_socket.disconnect()

      return

    return ddp_output_stream

  getDdpSubscribePreReadyPayloadForUserSync: (pub_name, pub_args_arr, user_id) ->
    js_ddp_socket = @getJsDdpSocketForUser(user_id)

    pre_ready_payload = js_ddp_socket.getDdpSubscribePreReadyPayloadSync(pub_name, pub_args_arr)
    
    js_ddp_socket.disconnect()

    return pre_ready_payload
