Currently, we use OpenAI's models to perform chat completion. The response type can either be streamed or non-streamed.

When supporting new vendors (to use models like Mixtral, Geminai, etc), you will have to implement your own _newChatCompletion and _newStream so it can work properly with justdo_ai_kit's newChatCompletion and newStream (and take a lot of checking/publication logic for granted, instead of writing your own.)

Below describes the parameters and expected output of each methods. When in doubt, please refer to openai.coffee for acutal examples.

 
_newChatCompletion: (template, template_data, user_id="system") ->
  This method is expected to perform the actual call to thrid-party API, and return the response.
  The request used in API call should always be generated using template.requestGenerator(template_data)
  Proper request logging should also be implemented (refer to the one in openai.coffee)

  Parameters:
    template: A request template object. Observe examples from server/static.coffee
    template_data: data obj passed to template.requestGenerator to generate the request sent to thrid-party APIs
    user_id: Performing user_id. Default is "system"

_newStream: (stream_type, template, template_data, user_id) ->
  Implement this if you plan to stream responses from thrid-party API.
  A mechanism to stream responses to client is available and makes use of this api.
  Check createStreamRequest publication inside publication.coffee
  The return object should be an EventEmitter obj with *at least* the following events:
    - chunk (emitted whenever the atomic unit of data is received from thrid-party API)
    - parsed_item (emitted when the parser (defined by stream_type) has parsed a document (e.g. a JSON object, an array, etc) mid-way through the stream)
    - abort (emitted when the stream is aborted. Always avoid emitting abort when error occurs)
    - error (emitted when the stream has error. Always avoid emitting error when stream is aborted)
    - end (emitted upon stream ends.)
  The return obj should also have a .stop() method to allow stopping the stream anytime.
  You are welcomed to implement more events and methods when needed.


  Parameters: (same as _newChatCompletion, except stream_type will be provided by newStream and is controlled by request template)
