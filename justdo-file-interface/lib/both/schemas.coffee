_.extend JustdoFileInterface.prototype,
  # jd_folder_id_obj is used by many methods in justdo-file-interface and it's file systems.
  # It consists of the minimal details we need to identify a folder under a file system. Consider it the primary key of a folder.
  jd_folder_id_obj_schema: new SimpleSchema
    fs_id:
      type: String
    bucket_id:
      type: String
    folder_name:
      type: String

  # jd_file_id_obj is used by many methods in justdo-file-interface and it's file systems.
  # It consists of the minimal details we need to identify a file under a file system. Consider it the primary key of a file.
  jd_file_id_obj_schema: new SimpleSchema
    fs_id:
      type: String
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