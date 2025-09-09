_.extend JustdoFileInterface.prototype,
  # jd_file_id_obj is used by many methods in justdo-file-interface and it's file systems.
  # It consists of the minimal details we need to identify a file. Consider it the primary key of a file.
  jd_file_id_obj_schema: new SimpleSchema
    fs_id:
      type: String
      # The purpose of fs_id is to allow justdo-file-interface to determine which file system to use.
      # If not provided, the `_getFs` will use the default fs_id.
      optional: true
    bucket_id:
      type: String
    folder_name:
      type: String
    file_id:
      type: String

  sanitizeJdFileIdObj: (jd_file_id_obj) ->
    # This method is a wrapper that sanitizes and returns the jd_file_id_obj

    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @jd_file_id_obj_schema,
      jd_file_id_obj,
      throw_on_error: true
    )
    return cleaned_val

  _attachCollectionsSchemas: -> return