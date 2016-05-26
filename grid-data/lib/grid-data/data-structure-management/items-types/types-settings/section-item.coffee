PACK.items_types["section-item"] = 
  builtInMetadataGenerator: (item, ext, index) ->
    # Section title occupies the entire row
    metadata = {
      columns:
        0:
          editor: null
          colspan: "*"
    }

    return metadata