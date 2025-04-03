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

    if not max_length? or max_length is 0
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

  br2nl: (string, options) ->
    if typeof string != "string"
      string = ""

    string = string.replace(/<br\s*\/?\s*>/g, "\n")

    if options?.strip_trailing_br
      string = string.trimEnd()

    return string

  getHtmlBodyContent: (html_str) ->
    # The first implementation was the following badly unoptimized regex:
    # return html_str.replace(/(.|[\r\n])*<body.*?>/i, "").replace(/<\/body>(.|[\r\n])*/i, "")
    
    if (res = /<body.*?>/i.exec(html_str))?
      html_str = html_str.substr(res.index + res[0].length)

    if (res = /<\/body>/i.exec(html_str))?
      html_str = html_str.substr(0, res.index)

    return html_str

  numberToHumanReadable: (number, options) ->
    if _.isString number
      number = parseFloat number

    if (precision = options?.precision)?
      number = parseFloat(number.toFixed precision)

    return number.toLocaleString()

  bytesToHumanReadable: (size, kb=1000) ->
    mb = kb ** 2
    gb = kb ** 3

    unit = "byte"

    if size >= gb
      size = size / gb
      unit = "GB"
    else if size >= mb
      size = size / mb
      unit = "MB"
    else if size >= kb
      size = size / kb
      unit = "KB"
    else if size > 1
      unit = "bytes"
    else if size == 1
      size = size
    else
      size = 0
    
    size = @numberToHumanReadable size, {precision: 2}

    return "#{size} #{unit}"

  useDarkTextColorForBackground: (background_color) ->
    # true use dark text color
    # false use bright text color
    #
    # https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb
    # https://www.nbdtech.com/Blog/archive/2008/04/27/Calculating-the-Perceived-Brightness-of-a-Color.aspx / https://archive.is/wip/Cxuud
    # http://alienryderflex.com/hsp.html / https://archive.is/wip/f186W

    [r, g, b] = JustdoHelpers.hexToRgb(background_color)

    brightness =
      Math.sqrt( .299 * Math.pow(r, 2) + .587 * Math.pow(g, 2) + .114 * Math.pow(b, 2) )

    # 0 black
    # 255 white
    if brightness > 200
      return true # dark color

    return false # bright color

  normalizeBgColor: (color) ->
    if not color?
      return "transparent"

    if color.toLowerCase() == "00000000"
      return "transparent"

    if color.toLowerCase() == "transparent"
      return "transparent"

    if color[0] != "#"
      return "#" + color
    else
      return color

  getFgColor: (color) ->
    if (normalized_color = JustdoHelpers.normalizeBgColor(color)) == "transparent"
      return "#000000"

    if JustdoHelpers.useDarkTextColorForBackground(normalized_color)
      return "#000000"
    else
      return "#ffffff"

  hexToRgb: (hex) ->
    # Handle empty or invalid input
    return [0, 0, 0] unless hex?.length
    
    # Remove # if present
    hex = hex.replace('#', '')
    
    # Handle shorthand hex (#fff)
    if hex.length is 3
      r = parseInt(hex.charAt(0) + hex.charAt(0), 16)
      g = parseInt(hex.charAt(1) + hex.charAt(1), 16)
      b = parseInt(hex.charAt(2) + hex.charAt(2), 16)
    else if hex.length is 6
      r = parseInt(hex.substring(0, 2), 16)
      g = parseInt(hex.substring(2, 4), 16)
      b = parseInt(hex.substring(4, 6), 16)
    else
      return [0, 0, 0]
    
    # Handle NaN values that might occur with invalid hex
    r = if isNaN(r) then 0 else r
    g = if isNaN(g) then 0 else g
    b = if isNaN(b) then 0 else b
    
    return [r, g, b]

  # Convert hex color to RGB string for use in rgba()
  hexToRgbStr: (hex) ->
    rgb = @hexToRgb(hex)
    return "#{rgb[0]}, #{rgb[1]}, #{rgb[2]}"

  # Convert RGB to HSL
  # Parameters:
  #   r, g, b: RGB values (0-255)
  # Returns: 
  #   Array with [h (0-1), s (0-1), l (0-1)]
  rgbToHsl: (r, g, b) ->
    r /= 255
    g /= 255
    b /= 255
    
    max = Math.max(r, g, b)
    min = Math.min(r, g, b)
    h = 0
    s = 0
    l = (max + min) / 2
    
    if max isnt min
      d = max - min
      s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
      
      switch max
        when r
          h = (g - b) / d + (if g < b then 6 else 0)
        when g
          h = (b - r) / d + 2
        when b
          h = (r - g) / d + 4
      
      h /= 6
    
    return [h, s, l]

  # Convert Hex to HSL
  # Parameters:
  #   hex: Hex color (with or without # prefix)
  # Returns:
  #   Array with [h (0-1), s (0-1), l (0-1)]
  # Note: The conversion mathematically requires RGB as an intermediate step,
  #       as hex is just a text representation of RGB values
  hexToHsl: (hex) ->
    rgb = @hexToRgb(hex)
    return @rgbToHsl(rgb[0], rgb[1], rgb[2])

_.extend JustdoHelpers,
  escaped_chars_within_defined_block_encode_map:
    ",": "\u000B"
    "'": "\u000C"
    '"': "\u000D"
    "{": "\u000E"
    "}": "\u000F"
    "[": "\u000E"
    "]": "\u000F"
    "(": "\u0010"
    ")": "\u0011"
    "`": "\u0012"
    "|": "\u0013"
    "<": "\u0014"
    ">": "\u0015"

_.extend JustdoHelpers,
  escaped_chars_within_defined_block_decode_map: _.invert JustdoHelpers.escaped_chars_within_defined_block_encode_map

_.extend JustdoHelpers,
  _encodeDecodeEscapedCharsWithinDefinedBlock: (op, str, escaped_blocks, options) ->
    # Structure escaped_blocks as follows:
    #
    # The following assumes options.escape_char is \
    #
    # We always allow the user to escape the closing delimiter with the options.escape_char.
    #
    # {
    #   "[]": [","] # Will encode/decode escaped "," and will allow the user to to escape ] with \] .
    #   "'": [","] # If the opening and closing delimiters are the same, no need to repeat the char (no need to have the key set to "''").
    #              # Will encode/decode escaped "," and will allow the user to to escape ' with \' . 
    # }

    if op not in ["enc", "dec"]
      throw new Error "Unknown op #{op}"

    escaped_chars_map = JustdoHelpers.escaped_chars_within_defined_block_encode_map

    default_options =
      escape_char: "\\"

    options = _.extend default_options, options
    {escape_char} = options

    for block_delimiters, encoded_chars of escaped_blocks
      if block_delimiters.length == 1
        opening_delimiter = closing_delimiter = block_delimiters
      
      if block_delimiters.length == 2
        opening_delimiter = block_delimiters[0]
        closing_delimiter = block_delimiters[1]

      encoded_chars = encoded_chars.slice() # Shallow copy, since we are going to add the closing delimiter
      encoded_chars.push(closing_delimiter)

      encoding_regex = new RegExp("(" + JustdoHelpers.escapeRegExp(opening_delimiter) + ")" + "((?:(?:[^#{closing_delimiter.replace("]", "\\]")}]*)|(?:#{escape_char}#{JustdoHelpers.escapeRegExp(closing_delimiter)}))+)" + "(" + JustdoHelpers.escapeRegExp(closing_delimiter) + ")", "g")

      str = str.replace encoding_regex, (match, opening_delimiter, content, closing_delimiter) ->
        # Allow escaping of closing delimiter with the escaped char
        if op == "enc"
          content = content.replace(new RegExp(JustdoHelpers.escapeRegExp(escape_char + closing_delimiter), "g"), escape_char + escaped_chars_map[closing_delimiter])
        else if op == "dec"
          content = content.replace(new RegExp(JustdoHelpers.escapeRegExp(escape_char) + escaped_chars_map[closing_delimiter], "g"), escape_char + closing_delimiter)
        for encoded_char in encoded_chars
          # Encoded all the defined encoded chars within the enclosing delimiters

          if op == "enc"
            content = content.replace(new RegExp("#{JustdoHelpers.escapeRegExp(encoded_char)}", "g"), escaped_chars_map[encoded_char])
          else if op == "dec"
            content = content.replace(new RegExp("#{escaped_chars_map[encoded_char]}", "g"), encoded_char)

        return opening_delimiter + content + closing_delimiter

    return str

  encodeEscapedCharsWithinDefinedBlock: (str, escaped_blocks, options) ->
    return @_encodeDecodeEscapedCharsWithinDefinedBlock("enc", str, escaped_blocks, options)

  decodeEscapedCharsWithinDefinedBlock: (str, escaped_blocks, options) ->
    return @_encodeDecodeEscapedCharsWithinDefinedBlock("dec", str, escaped_blocks, options)

  csvTo2DArray: (csv, options) ->
    # Notes:
    #
    # * , can't be escaped.
    # * Items can be enclosed with "" or '' in which case they can have , inside them

    # Fields that aren't enclosed with quotes these lines
    res = []

    default_options =
      remove_delimiters: true
      escaped_blocks:
        "'": [","]
        '"': [","]

    options = _.extend default_options, options
    {remove_delimiters, escaped_blocks} = options

    for line in csv.split("\n")
      line_arr = []

      for raw_field in JustdoHelpers.encodeEscapedCharsWithinDefinedBlock(line, escaped_blocks).split(",")
        field_val = JustdoHelpers.decodeEscapedCharsWithinDefinedBlock(raw_field, escaped_blocks).trim()

        if remove_delimiters
          field_val = field_val.replace(/^"(.*)"$/, "$1")
          field_val = field_val.replace(/^'(.*)'$/, "$1")

        line_arr.push field_val

      res.push line_arr

    return res

  getNonEmptyValuesFromCsv: (csv) ->
    csv = csv or ""

    if not _.isString(csv)
      csv = ""

    trimmed_values = _.map csv.split(","), (conf) -> conf.trim()

    return _.compact(trimmed_values)

  localeAwareSortCaseInsensitive: (array, valueExtractor) ->
    array = array.slice() # Shallow copy.

    array.sort (a, b) ->
      if _.isFunction(valueExtractor)
        a = valueExtractor(a)
        b = valueExtractor(b)

      res = a.toUpperCase().localeCompare(b.toUpperCase())
      if res != 0
        return res

      if res == 0
        return a.localeCompare(b) * -1 # put the upper before

    return array

  htmlEntitiesEncode: (str) ->
    # This code doesn't support emojis!
    # https://stackoverflow.com/questions/18749591/encode-html-entities-in-javascript#comment94981399_23834738
    return str.replace /[\u00A0-\u9999<>\&]/gim, (i) =>
      return '&#' + i.charCodeAt(0) + ';'
