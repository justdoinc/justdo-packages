JustdoXlsx = 
  requireXlsx: (cb) ->
    # The use of barrier ensures that cb will execute only once,
    # even if the script is loaded multiple times.
    
    JustdoHelpers.hooks_barriers.runCbAfterBarriers "xlsx-loading", =>
      cb? XLSX
      return

    if not XLSX?
      handleError = (error) ->
        console.error "Error loading XLSX: #{error}"
        JustdoHelpers.hooks_barriers.markBarrierAsRejected "xlsx-loading"
        return
        
      options = 
        success: (data, text_status, jqxhr) =>
          if jqxhr.status is 200
            JustdoHelpers.hooks_barriers.markBarrierAsResolved "xlsx-loading"
          else
            handleError(jqxhr.statusText)
          return
        error: (jqxhr, text_status, error) =>
          handleError(error)
          return

      JustdoHelpers.getCachedScript "/packages/justdoinc_justdo-xlsx/lib/both/xlsx.full.min.js", options

    return