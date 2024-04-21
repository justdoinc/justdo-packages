_.extend JustdoHelpers,
  testContrast: (contrast_level=1) ->
    $("body").css({"filter": "contrast(#{contrast_level})"})