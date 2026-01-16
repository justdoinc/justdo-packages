var template = new ReactiveVar('bootstrap3')
var options  = new ReactiveVar({})
var DEFAULT_SHOW_DELAY = 500
var show_delay = new ReactiveVar(DEFAULT_SHOW_DELAY)
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

  setShowDelay: function (value) {
    show_delay.set(value)
  },

  getShowDelay: function () {
    return show_delay.get()
  }
}
