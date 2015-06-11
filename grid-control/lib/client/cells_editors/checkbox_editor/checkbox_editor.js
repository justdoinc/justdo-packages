PACK.Editors.CheckboxEditor = function (args) {
  var $select;
  var currentValue;
  var scope = this;

  this.init = function () {
    $select = $("<input type='checkbox' class='editor-checkbox' hideFocus>");
    $select.appendTo(args.container);
    $select.focus();
  };

  this.destroy = function () {
    $select.remove();
  };

  this.focus = function () {
    $select.focus();
  };

  this.loadValue = function (item) {
    currentValue = !!item[args.column.field];
    if (currentValue) {
      $select.prop('checked', true);
    } else {
      $select.prop('checked', false);
    }
  };

  this.serializeValue = function () {
    return $select.prop('checked');
  };

  this.applyValue = function (item, state) {
    item[args.column.field] = state;
  };

  this.isValueChanged = function () {
    return (this.serializeValue() !== currentValue);
  };

  this.validate = function () {
    return {
      valid: true,
      msg: null
    };
  };

  this.init();
};