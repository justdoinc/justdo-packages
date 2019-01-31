_.extend JustdoHelpers,
  lowerCamelTo: (replacement, string) ->
    string += ""
    
    return string.replace /([A-Z])/g, (letter) ->
      replacement + letter.toLowerCase()

  camelCaseTo: (replacement, string) ->
    string = JustdoHelpers.lcFirst(string)
    
    return string.replace /([A-Z])/g, (letter) ->
      replacement + letter.toLowerCase()

  dashSepTo: (replacement, string) ->
    string += ""

    string.replace /-/g, replacement

  ucFirst: (string) ->
    string += ""

    return string.charAt(0).toUpperCase() + string.substr(1)

  lcFirst: (string) ->
    string += ""

    return string.charAt(0).toLowerCase() + string.substr(1)

  substrCount: (string, sub_string, allow_overlapping) ->
    string += ""
    sub_string += ""

    if sub_string.length <= 0
      return string.length + 1

    n = 0
    pos = 0
    step = if allow_overlapping then 1 else sub_string.length

    loop
      pos = string.indexOf(sub_string, pos)
      if pos >= 0
        ++n
        pos += step
      else
        break

    return n

  padString: (number, size, fill="0") ->
    number = number.toString();

    while (number.length < size)
      number = fill + number

    return number

  ellipsis: (str, max_length) ->
    if not str?
      return ""

    if not max_length?
      return str

    if str.length <= max_length
      return str

    return str.substr(0, max_length) + "..."

  splice: (str, start, delete_count, new_substring) ->
    return str.slice(0, start) + new_substring + str.slice(start + Math.abs(delete_count))

  labelToUniqueId: (label) ->
    # Takes a human readble label and returns a unique ID with a readable part
    # based on the label entered, takes into account foreign charecters 

    if not label?
      label = ""

    unique_id = label.trim().replace(/\s+/g, "_").replace(/[^a-z_]/gi, "").replace()

    if unique_id != ""
      unique_id += "__"

    unique_id += Random.id()

    if unique_id.length > 100
      unique_id = unique_id.substr(0, 100)

    return unique_id

  nl2br: (string) ->
    if typeof string != "string"
      string = ""

    return string.replace(/\n/g, "<br>")

  getHtmlBodyContent: (html_str) ->
    # The first implementation was the following badly unoptimized regex:
    # return html_str.replace(/(.|[\r\n])*<body.*?>/i, "").replace(/<\/body>(.|[\r\n])*/i, "")
    
    if (res = /<body.*?>/i.exec(html_str))?
      html_str = html_str.substr(res.index + res[0].length)

    if (res = /<\/body>/i.exec(html_str))?
      html_str = html_str.substr(0, res.index)

    return html_str

  bytesToHumanReadable: (size) ->
    if size >= 1000000000
      size = (size / 1000000000).toFixed(2) + " GB"
    else if size >= 1000000
      size = (size / 1000000).toFixed(2) + " MB"
    else if size >= 1000
      size = (size / 1000).toFixed(2) + " KB"
    else if size > 1
      size = size + " bytes"
    else if size == 1
      size = size + " byte"
    else
      size = "0 byte"
    return size

  useDarkTextColorForBackground: (background_color) ->
    # Returns true if a dark text color should be used for the provided background
    # false otherwise.
    #
    # https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb

    [r, g, b] = JustdoHelpers.hexToRgb(background_color)

    c = [ r / 255, g / 255, b / 255 ]

    for i, x of c
      if c[i] <= 0.03928 
        c[i] = c[i] / 12.92
      else
        c[i] = Math.pow( ( c[i] + 0.055 ) / 1.055, 2.4)

    l = 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

    if ( l > 0.179 )
      return true

    return false

  hexToRgb: (hex) ->
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)

    if not result?
      return [0, 0, 0]

    return [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)]
