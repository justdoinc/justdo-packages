_.extend JustdoAiKit.prototype,
  _setupOpenAI: ->
    vendor_name = "openai"
    confs_to_get = ["api_key"]

    secret_conf = @requireVendorConf vendor_name, confs_to_get, true

    register_vendor_api_options = 
      sdk_constructor_options:
        apiKey: secret_conf.api_key
      default_model: JustdoAiKit.openai_template_generation_model
    
    @registerVendorApi vendor_name, register_vendor_api_options

    return