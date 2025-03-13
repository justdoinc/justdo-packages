AiTemplateGeneratorControllerOptionsSchema = new SimpleSchema
  onCreateBtnClick:
    type: Function
    defaultValue: -> return
  pre_prompt_txt_i18n:
    type: String
    optional: true
    defaultValue: "ai_wizard_what_kind_of_project_do_you_want_to_create"

JustdoAiKit.AiTemplateGeneratorController = (options) ->
  EventEmitter.call this

  if not options?
    options = {}

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      AiTemplateGeneratorControllerOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
  @options = cleaned_val
  @stream_handler_rv = new ReactiveVar {}
  # Store the request sent for template generation inlcuding the cache token.
  @sent_request = {}
  @excluded_item_keys = []
  @stop_sub_upon_destroy = true

  return @

Util.inherits JustdoAiKit.AiTemplateGeneratorController, EventEmitter

_.extend JustdoAiKit.AiTemplateGeneratorController.prototype,
  getPrePromptTxtI18n: -> @options.pre_prompt_txt_i18n

  getStreamHandler: -> @stream_handler_rv.get()
  setStreamHandler: (stream_handler) -> @stream_handler_rv.set stream_handler

  getSentRequest: -> @sent_request
  setSentRequest: (sent_request) -> @sent_request = sent_request

  getExcludedItemKeys: -> @excluded_item_keys
  setExcludedItemKeys: (excluded_item_keys) -> @excluded_item_keys = excluded_item_keys

  stopSubscriptionUponDestroy: -> @stop_sub_upon_destroy
  setStopSubscriptionUponDestroy: (stop_sub_upon_destroy) -> 
    check stop_sub_upon_destroy, Boolean
    @stop_sub_upon_destroy = stop_sub_upon_destroy
    return

  isResponseExists: -> 
    if _.isEmpty(stream_handler = @getStreamHandler())
      return false
    return stream_handler.findOne({"data.parent": -1}, {fields: {_id: 1}})?
  
  clearResponse: -> 
    @getStreamHandler()?.stopSubscription()
    @setStreamHandler null
    return

  onCreateBtnClick: -> @options.onCreateBtnClick()
