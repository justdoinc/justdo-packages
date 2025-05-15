_.extend JustdoAiKit.prototype,
  _setupOllama: ->
    vendor_name = "ollama"
    confs_to_get = ["base_url"]

    conf = @getVendorConf vendor_name, confs_to_get

    register_vendor_api_options =
      sdk_constructor_options:
        apiKey: vendor_name # While Ollama does not require an api key, OpenAI SDK requires one.
        baseURL: conf.base_url or JustdoAiKit.default_ollama_base_url
      default_model: JustdoAiKit.ollama_template_generation_model
      requestOptionsMapper: (req) ->
        # Ollama-specific parameter adjustments
        # For example, Ollama might use different parameter names or values
        # This ensures compatibility with the OpenAI SDK interface

        # Map response_format to format if it exists
        if (json_schema = req.response_format?.json_schema)?
          req.format = json_schema
          delete req.response_format

        return req

    @registerVendorApi vendor_name, register_vendor_api_options

    return 