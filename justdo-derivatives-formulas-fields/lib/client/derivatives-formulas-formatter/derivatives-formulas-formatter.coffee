GridControl.installFormatter JustdoDerivativesFormulasFields.pseudo_field_formatter_id,
  invalidate_ancestors_on_change: "structure-and-content"

  slick_grid: ->
    formatter_content = @getFriendlyArgs().options?.formula?.call(@)

    formatter = """
      <div class="grid-formatter df-formatter">
        #{formatter_content}
      </div>
    """

    return formatter

  print: (doc, field, path) ->
    formatter_content = @getFriendlyArgs().options?.formula?.call(@)

    formatter = """
      <div class="grid-formatter df-formatter">
        #{formatter_content}
      </div>
    """
    
    return formatter

  print_formatter_produce_html: true