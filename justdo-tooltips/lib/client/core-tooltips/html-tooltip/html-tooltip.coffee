APP.justdo_tooltips.registerTooltip
  id: "html"
  template: "html_tooltip"

Template.html_tooltip.helpers
  html: -> @options.html or ""
