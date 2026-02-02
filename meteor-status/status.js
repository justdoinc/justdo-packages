var template = new ReactiveVar('bootstrap3')
var options  = new ReactiveVar({})
var DEFAULT_DISPLAY_DELAY_MS = 500
var display_delay_ms = new ReactiveVar(DEFAULT_DISPLAY_DELAY_MS)
var defaults = {
  classes: {
    bootstrap3:  'alert-warning',
    semantic_ui: 'negative',
    uikit:       'warning',
    foundation:  'warning'
  }
}

Status = {
  template: function () {
    return template.get()
  },

  option: function (option) {
    return options.get()[option] || defaults[option][template.get()]
  },

  setTemplate: function (name, _options) {
    template.set(name)

    if (_options) options.set(_options)
  },

  setDisplayDelayMs: function (value) {
    display_delay_ms.set(value)
  },

  getDisplayDelayMs: function () {
    return display_delay_ms.get()
  }
}
