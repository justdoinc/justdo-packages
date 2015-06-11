PACK.Editors.SelectorEditor = function (args) {
    var $select;
    var currentValue;
    var scope = this;

    this.init = function () {
      var value, label, options, output = "";

      if (args.column.possible_values !== null) {
        options = args.column.possible_values;
      } else {
        options = {};
      }

      for (value in options) {
        label = options[value];

        output += '<option value="' + value + '">' + label + '</option>';
      }

      $select = $("<select>" + output + "</select>");
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
      currentValue = item[args.column.field];

      $select.val(currentValue);
    };

    this.serializeValue = function () {
      return $select.val();
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