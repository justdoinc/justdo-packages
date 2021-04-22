import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  'bson-to-json': '2.0.x'
}, 'justdoinc:justdo-helpers')

bsonToJson = require("bson-to-json")
JustdoHelpers.bsonToJson = bsonToJson

JustdoHelpers.sendCustomJsonStructure = (cursor, writable_stream, transcoder_options, prefixGenerator, suffixGenerator) ->
  # The following a forked version of bson-to-json's .send() that is based on fibers
  # instead of promises + some changes other changes for our use cases.

  fiber = JustdoHelpers.requireCurrentFiber()

  cursor.rewind()

  if cursor.isDead()
    throw new Error "Cursor is closed."

  if prefixGenerator? or suffixGenerator?
    if not prefixGenerator?
      prefixGenerator = -> return

    if not suffixGenerator?
      suffixGenerator = -> return

    outputRawDoc = (raw_doc) ->
      [raw_doc_json_buffer, document_id_jsoned] = bsonToJson.bsonToJson(raw_doc, transcoder_options, false)

      prefixGenerator(raw_doc_json_buffer, document_id_jsoned, writable_stream)

      stream_capacity_available = writable_stream.write(raw_doc_json_buffer)

      suffixGenerator(raw_doc_json_buffer, document_id_jsoned, writable_stream)

      return stream_capacity_available
  else
    outputRawDoc = (raw_doc) ->
      stream_capacity_available = writable_stream.write(bsonToJson.bsonToJson(raw_doc, transcoder_options, false)[0])

      return stream_capacity_available

  rest = false
  while true
    # Read all buffered documents. This loop doesn't wait for the stream to
    # drain: The source documents are already in memory, so try to free
    # that memory up ASAP (although it allocates new memory).
    {cursorState} = cursor
    documents = cursorState.documents

    i = cursorState.cursorIndex
    while i < documents.length - 1 # Note < and not <= the last document is taken later to decide how fast
                                   # to keep draining (according to the writable_stream capacity)
                                   # Daniel C.
      doc = documents[i]
      i += 1

      if not doc?
        break

      outputRawDoc(doc)
      writable_stream.write(",") # Note we don't use + to avoid allocating a new string in the memory...

    if (last_doc = documents[i])?

      should_wait_drain = not outputRawDoc(last_doc)

      cursorState.cursorIndex = documents.length
      if should_wait_drain
        writable_stream.once "drain", ->
          fiber.run()

          return

        JustdoHelpers.fiberYield()

    # Get next batch from MongoDB (i.e. issue GET_MORE).
    cursor.next().then (has_next) ->
      fiber.run(has_next)

      return

    has_next = JustdoHelpers.fiberYield()
    if not has_next
      break

    cursorState.cursorIndex -= 1

    if rest # The first time we ever run there won't be docs. Daniel C.
      writable_stream.write ","
    else
      rest = true

  return