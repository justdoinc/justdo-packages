_.extend JustdoHelpers,
  xssGuard: (text) ->
    # Prepare to guard, remove problematic html that cause it to break

    if not text?
      text = ""

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
      purified_html = UniHTML.purify text,
        customTags: customTags
        allowed_attributes: allowed_attributes
    catch e
      console.warn "JustdoHelpers.xssGuard: UniHTML.purify failed to secure a string, falling back to HTML Entities XSS guard.", e

      APP.justdo_analytics.JAReportClientSideError("xss-guard-failure", JSON.stringify(e))

      purified_html = JustdoHelpers.htmlEntitiesXssGuard(text)

    return purified_html

  htmlEntitiesXssGuard: (str) ->
    # https://css-tricks.com/snippets/javascript/htmlentities-for-javascript/
    String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

