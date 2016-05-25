_.extend GridData.prototype,
  _initMetadata: ->
    @_metadataGenerators = []

  getItemMetadata: (index) ->
    # Get the metadata from each one of the generators
    generators_metadata =
      _.map @_metadataGenerators, (generator) =>
        generator(@grid_tree[index][0], @grid_tree[index], index)

    # Merge metadata, give recent registered generators priority
    if not _.isEmpty generators_metadata
      # the receiver obj, new one is required, since we do later deep merge of style
      # (otherwise last one will become the first one)
      generators_metadata.unshift {}
      metadata = _.extend.apply(_, generators_metadata)

    # deep merge the `style` metadata
    styles = _.map generators_metadata, (metadata) -> metadata.style
    styles = _.without styles, undefined
    if not _.isEmpty styles
      styles.unshift {} # receiver obj
      metadata.style = _.extend.apply(_, styles)
    else
      delete metadata.style

    # union all `cssClasses` metadata
    cssClasses = _.map generators_metadata, (metadata) -> metadata.cssClasses

    if metadata?.columns?[0]?.colspan == "*"
      # A work around.
      #
      # Due to the changes made to the slick grid dom structure, we lost the ability
      # to present correctly specific cell colspan.
      # With this workaround we add support for the first cell to occupy the entire-row
      cssClasses.push ["full-row-colspan"]

    cssClasses = _.without cssClasses, undefined
    if not _.isEmpty cssClasses
      metadata.cssClasses = _.union.apply(_, cssClasses)
    else
      delete metadata.cssClasses

    return metadata

  registerMetadataGenerator: (cb) ->
    # Register metadata function of the form cb(item, item_meta_details, index),
    # that will be called with the item index, and should return an object
    # of item meta data.
    # Important! must return an object, if no metadata for item, return empty
    # object.

    # Returns true if cb added, false otherwise
    if _.isFunction cb
      if not(cb in @_metadataGenerators)
        @_metadataGenerators.push cb

        return true
      else
        @logger.warn "registerMetadataGenerator provided an already registered generator"
    else
      @logger.warn "registerMetadataGenerator was called with no callback"

    return false

  unregisterMetadataGenerator: (cb) ->
    @_metadataGenerators = _.without @_metadataGenerators, cb