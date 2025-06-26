_.extend JustdoFilesInterface,
  project_custom_feature_id: "justdo_file_interface" # Use underscores

  plugin_human_readable_name: "justdo-file-interface"

  both_register_fs_options_required_properties:
    max_file_size_in_bytes: Number
    # Note: Most (if not all) of JustDo plugins are EventEmitter instances, instead of a simple Object.
    instance: EventEmitter