PACK.Editors.SelectorEditor = function (args) {
    var $select;
    var currentValue;
    var scope = this;
    var grid = args.grid;

    this.init = function () {
      var value, label, options, output = "";

      if (args.column.values !== null) {
        options = args.column.values;
        if (_.isFunction(options)) {
          options = options(args.grid_control);
        }
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
      this.showOptions();
      $select.click(function () {
        grid.getEditorLock().commitCurrentEdit();
      });
    };

    this.showOptions = function () {
      event = document.createEvent('MouseEvents');
      event.initMouseEvent('mousedown', true, true, window);
      $select.get(0).dispatchEvent(event);
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