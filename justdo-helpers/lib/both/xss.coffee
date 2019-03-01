_.extend JustdoHelpers,
  xssGuard: (text, options) ->
    # Prepare to guard, remove problematic html that cause it to break

    if not text?
      text = ""

    text = String(text)

    default_options =
      allow_html_parsing: false
      enclosing_char: undefined
      enclosing_char_esc: undefined # If set to undefined, we will use the html entity value for the char.
      allowEmptyTags: true

    options = _.extend {}, default_options, options

    if not options.allow_html_parsing
      return JustdoHelpers.htmlEntitiesXssGuard(text)

    if not (enclosing_char = options.enclosing_char)?
      console.trace?()
      warning = '''
        JustdoHelpers.xssGuard:

        Warning: Can't allow html parsing for input, due to a missing option - *falling back
        to HTML based entities XSS guarding*.

        To prepare xssGuarded input to be parsable, we use a tool called HTML purifier, that
        removes any potential vicious code from the input HTML.

        In some circumstances the HTML purifier might not be enough, and therefore will only
        give false sense of security.

        Consider:

            <div title="#{guarded_string}">

        A user can set guarded_string to: '" onclick="script here', which is an input we
        consider as technically legitimate when passed through our HTML purifier, but,
        if placed above, will result will in: <div title="" onclick="script here" which
        can be used for hacking.

        Therefore, we force all calls to xssGuard, in which the allow_html_parsing option
        is set to true, to include information about the enclosing charecter of the input,
        or else we will have to use html-entities based escaping, to avoid unintended
        security volunarability.

        Please find out whether you got an enclosing charecter that needs escaping.

        If you do, add it in to your options:

            {allow_html_parsing: true, enclosing_char: "'"}

        Otherwise, you can set the enclosing_char option to empty string:

            {allow_html_parsing: true, enclosing_char: ""}

        (By default, we are replacing the char with its html entitiy code, but you can
        set a different replace value in the enclosing_char_esc option).
      '''

      console.warn(warning)

      return JustdoHelpers.htmlEntitiesXssGuard(text)

    if not _.isEmpty(enclosing_char)
      if not (enclosing_char_esc = options.enclosing_char_esc)?
        enclosing_char_esc =
          JustdoHelpers.htmlEntitiesXssGuard(options.enclosing_char)

        if enclosing_char_esc == options.enclosing_char
          # If it didn't change, it means we can't come up with the html
          # entity for the char - the user will have to provide it for
          # us.

          warning = '''
            JustdoHelpers.xssGuard:

            Warning: enclosing_char_esc option is needed - *falling back to HTML based entities XSS guarding*.

            We don't know how to escape your provided enclosing_char, please provide the escaped value using
            the enclosing_char_esc option.
          '''

          console.warn(warning)

          return JustdoHelpers.htmlEntitiesXssGuard(text)

      text = text.replace(RegExp(enclosing_char, "g"), enclosing_char_esc)

    text = text
      .replace(/<!(--)?\[if[^\]]*\]>/g, "")
      .replace(/<!\[endif\]-*>/g, "")

    customTags = 
      s: true # Add Strike-through to allowed tags
      dir: true
      div: true

    allowed_attributes = 
      all_elements: [
        'class'
        'style'
        'id'
        'dir'
      ]
      a: [
        'href'
        'target'
        'title'
        'name'
        'rel'
        'rev'
        'type'
      ]
      blockquote: [ 'cite' ]
      img: [
        'src'
        'alt'
        'title'
        'longdesc'
        'width'
        'height'
      ]
      td: [ 'colspan' ]
      th: [ 'colspan' ]
      tr: [ 'rowspan' ]
      table: [ 'border' ]

    try
      uni_html_options =
        customTags: customTags
        allowed_attributes: allowed_attributes

      if options.allowEmptyTags? # If set to undefined we will not pass this option at all, to use the defaults
        uni_html_options.allowEmptyTags = options.allowEmptyTags

      purified_html = UniHTML.purify text, uni_html_options

    catch e
      console.warn "JustdoHelpers.xssGuard: UniHTML.purify failed to secure a string, falling back to HTML Entities XSS guard.", e

      APP.justdo_analytics.JAReportClientSideError("xss-guard-failure", JSON.stringify(e))

      return JustdoHelpers.htmlEntitiesXssGuard(text)

    # The following:
    #
    # text = '<option value="4DG9TSoqeLTm4oo2R" data-content="<b>da</b><script>alert(12)</script>" ><b>da</b><script>alert(12)</script></option><option value="" data-content="<div class=\'null-state\'></div>" ><div class=\'null-state\'></div></option>'
    #
    # When passed through:
    #
    # JustdoHelpers.xssGuard(text, , {allow_html_parsing: true, enclosing_char: ''})
    #
    # Remains with the <script> tag intact!
    #
    # We need to find where UniHTML.purify fails.
    #
    # Until we find the cause, we can't take any risk, so:
    purified_html = purified_html.replace(/(<\s*\/?\s*)(script.*?)(\s*>)/g, "")

    if not _.isEmpty(enclosing_char)
      # By this point we know that if we have enclosing_char we have the enclosing_char_esc
      #
      # The XSS purifier changes attributes that are enclosed with single quote with double
      # quote: <div x='y'> will result in <div x="y">, so, in order to respect the enclosing
      # char - we need to perform the replace second time.
      purified_html = purified_html.replace(RegExp(enclosing_char, "g"), enclosing_char_esc)

    return purified_html

  htmlEntitiesXssGuard: (str) ->
    # https://css-tricks.com/snippets/javascript/htmlentities-for-javascript/
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;')

