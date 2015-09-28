PACK.Editors.SelectorEditor = function (args) {
    var $select;
    var $select_picker;
    var currentValue;
    var scope = this;
    var grid = args.grid;

    this.init = function () {
      var self = this;

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

        output += '<option value="' + value + '" data-content="' + label + '">' + label + '</option>';
      }

      $select = $("<select class='selector-editor'>" + output + "</select>");
      $select.appendTo(args.container);
      $select.selectpicker({
        container: "body",
        dropupAuto: true,
        size: false,
        width: "100%"
      });
      $select_picker = $select.next();
      setTimeout(function () {
        $("button", $select_picker).click();

        setTimeout(function () {
          self.focus();
        }, 0);
      }, 0);
    };

    this.showOptions = function () {
      event = document.createEvent('MouseEvents');
      event.initMouseEvent('mousedown', true, true, window);
      $select.get(0).dispatchEvent(event);
    };
 
    this.destroy = function () {
      $select.selectpicker("destroy");
    };

    this.focus = function () {
      $("button", $select_picker).focus();
    };

    this.loadValue = function (item) {
      currentValue = item[args.column.field];

      $select.selectpicker("val", currentValue);
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
