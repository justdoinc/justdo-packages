GridControl.installFormatter "checkboxFormatter",
  slick_grid: ->
    {value} = @getFriendlyArgs()

    input = '<input type="checkbox" class="checkbox-formatter" value="#{value}"'

    if value
      return input += ' checked />'

    return input += ' />'

  print: (doc, field) ->
    {value} = @getFriendlyArgs()

    return if value then "+" else "-"