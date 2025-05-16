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

    @registerVendorApi vendor_name, register_vendor_api_options

    return 