_.extend JustdoFilesInterface,
  project_custom_feature_id: "justdo_file_interface" # Use underscores

  plugin_human_readable_name: "justdo-file-interface"

  both_register_fs_options_schema_properties:
    max_file_size_in_bytes:
      type: Number
    instance:
      # Note: Most (if not all) of our plugins are EventEmitter instances, instead of a simple Object.
      type: EventEmitter
      blackbox: true