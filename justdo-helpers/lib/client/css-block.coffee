_.extend JustdoHelpers,
  loadCssBlock: (css_code) ->
    # Takes css_code in its text form e.g "body {background-color: red}", sets a <style>
    # tag for it in the document <head> and returns a jQuery object with a reference
    # the created DOM object, so you can .remove() it.
    #
    #   red_background = JustdoHelpers.loadCssBlock("""body {background-color: red}""")
    #   red_background.remove()
    #
    # The concept was taken from createCssRules of slick.grid.js

    $style = $("""<style type="text/css" rel="stylesheet" />""").appendTo($("head"))

    if $style[0].styleSheet? # IE
      $style[0].styleSheet.cssText = css_code
    else
      $style[0].appendChild(document.createTextNode(css_code))

    return $style