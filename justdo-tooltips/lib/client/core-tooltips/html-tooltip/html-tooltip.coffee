APP.justdo_tooltips.registerTooltip
  id: "html"
  template: "html_tooltip"

Template.html_tooltip.helpers
  html: -> decodeURIComponent(@options.html or "")
