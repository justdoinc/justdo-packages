_.extend JustdoFilesDriver,
  project_custom_feature_id: "justdo_files_driver" # Use underscores

  plugin_human_readable_name: "justdo-files-driver"

  both_register_driver_options_schema_properties:
    max_file_size_in_bytes:
      type: Number
    instance:
      # Note: Most (if not all) of our plugins are EventEmitter instances, instead of a simple Object.
      type: EventEmitter
      blackbox: true