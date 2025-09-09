_.extend JustdoCoreHelpers,
  mimeTypeToPreviewCategory: (mime_type) ->
    # Receives a mime_type and returns JustDo's standard Preview Category id that defines its previewability.
    #
    # What we try to capture here are categories that are typically bounded together in their previewability
    # for example, in all modern browsers, anything image/* would be previwable, as such we bound all of them
    # into a single Preview Category "images". As for pdf preview, for example, if a pdf is previewable
    # other types are not necessarily previwable as well (for example doc), hence, pdf gets its own category.
    #
    # The general rule of thumb for adding more categories, is that we add them, as we encounter/need them,
    # and not preemptively.

    mime_type = mime_type.toLowerCase()

    if mime_type.indexOf("image/") is 0
      return "image"

    if mime_type.indexOf("video/") is 0
      return "video"

    if mime_type.indexOf("application/pdf") is 0
      return "pdf"

    return "other"