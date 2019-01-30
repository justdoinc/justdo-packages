ReceivedLogObjectSchema = JustdoAnalytics.schemas.ReceivedLogObjectSchema

_.extend JustdoAnalytics.prototype,
  validateAndSterilizeLog: (log, verify_registered_log=true, add_base_classes=false) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        ReceivedLogObjectSchema,
        log,
        {self: @, throw_on_error: true}
      )

    if add_base_classes
      # We add the base classes only right before we write the log.
      # Otherwise every call to validateAndSterilizeLog will add
      # logs again (in client side too), and we want to avoid it. 
      if (base_classes = JustdoAnalytics.logs_index[cleaned_val.cat]?[cleaned_val.act]?.classes)?
        if cleaned_val.cls?
          cleaned_val.cls = base_classes.concat(cleaned_val.cls)
        else
          cleaned_val.cls = base_classes

    cleaned_val.cls = _.unique(cleaned_val.cls)

    if verify_registered_log
      if not (JustdoAnalytics.logs_index?[log.cat]?[log.act])?
        throw @_error "unknown-log-type", "Log #{log.cat}::#{log.act} isn't registered"
    
    return cleaned_val