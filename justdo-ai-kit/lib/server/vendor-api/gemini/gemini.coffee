_.extend JustdoAiKit.prototype,
  _setupGemini: ->
    vendor_name = "gemini"
    confs_to_get = ["base_url"]
    secret_confs_to_get = ["api_key"]

    conf = @getVendorConf vendor_name, confs_to_get
    secret_conf = @requireVendorConf vendor_name, secret_confs_to_get, true

    register_vendor_api_options =
      sdk_constructor_options:
        apiKey: secret_conf.api_key
        baseURL: conf.base_url or JustdoAiKit.default_gemini_base_url
      default_model: JustdoAiKit.gemini_template_generation_model
      requestOptionsMapper: (req) ->
        # Gemini-specific parameter adjustments
        # For example, Gemini might use different parameter names or values
        # This ensures compatibility with the OpenAI SDK interface

        # Certain options are not supported when using Gemini with OpenAI SDK,
        # for example `response_format`.
        # For the full list of (un)supported options, please refer to https://docs.anthropic.com/en/api/openai-sdk

        # Gemini has a max temperature of 1, where OpenAI has a max temperature of 2
        if req.temperature?
          req.temperature /= 2 
        
        # Gemini does not support frequency_penalty and throws 400 error.
        delete req.frequency_penalty

        # When used with `stream_project_template`, Gemini throws 500 error when provided with `response_format`.
        delete req.response_format
        
        # Disable think mode for now due to lack of usecase with it.
        # Can be enabled anytime, or enabled on a per-request basis.
        req.reasoning_effort = "none"

        return req

    @registerVendorApi vendor_name, register_vendor_api_options

    return 