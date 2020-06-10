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

  normalizeBgColor: (color) ->
    if not color?
      return "transparent"

    if color.toLowerCase() == "ffffff"
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
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)

    if not result?
      return [0, 0, 0]

    return [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)]

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
