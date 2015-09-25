PACK.Editors.TextareaEditor = function (args) {
  var active_cell = args.grid.getActiveCell();
  
  var $input;
  var defaultValue;
  var scope = this;

  var grid_control = args.grid_control

  this.init = function () {
    $input = $("<textarea class='textarea-editor' rows='1' />")
        .appendTo(args.container)
        .bind("keydown.nav", function (e) {
          if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        })
        .focus()
        .select();
  };

  this.destroy = function () {
    $input.remove();
  };

  this.focus = function () {
    $input.focus();
  };

  this.getValue = function () {
    return $input.val();
  };

  this.setInputValue = function (val) {
    $input.val(val);

    $input.autosize();
  };

  this.setValue = function (val) {
    this.setInputValue(val);
  };

  this.loadValue = function (item) {
    defaultValue = item[args.column.field] || "";
    this.setInputValue(defaultValue);
    $input[0].defaultValue = defaultValue;
    $input.select();
  };

  this.serializeValue = function () {
    return $input.val();
  };

  this.applyValue = function (item, state) {
    item[args.column.field] = state;
  };

  this.isValueChanged = function () {
    return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
  };

  this.validate = function () {
    if (args.column.validator) {
      var validationResults = args.column.validator($input.val());
      if (!validationResults.valid) {
        return validationResults;
      }
    }

    return {
      valid: true,
      msg: null
    };
  };

  this.init();
};
