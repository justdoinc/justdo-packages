PACK.Editors.SelectorEditor = function (args) {
    var $select;
    var $select_picker;
    var $grid_view_port;
    var grid_view_port_scroll_handler;
    var currentValue;
    var scope = this;
    var grid = args.grid;

    this.init = function () {
      var self = this;

      var value, label, options, option, output = "";

      if (args.column.values !== null) {
        options = args.column.values;
      } else {
        options = {};
      }

      for (value in options) {
        option = options[value];

        if (typeof option.html !== "undefined") {
          label = option.html;
        } else {
          label = option.txt;
        }

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

      $grid_view_port = $(grid.getCanvasNode()).parent();

      grid_view_port_scroll_handler = function () {
        $select.selectpicker("resizeHandler");
      };

      $grid_view_port.on("scroll", grid_view_port_scroll_handler);
    };

    this.showOptions = function () {
      event = document.createEvent('MouseEvents');
      event.initMouseEvent('mousedown', true, true, window);
      $select.get(0).dispatchEvent(event);
    };
 
    this.destroy = function () {
      $select.selectpicker("destroy");
      $grid_view_port.off("scroll", grid_view_port_scroll_handler);
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

    this.getValue = function () {
      return this.serializeValue();
    };

    this.init();
};
