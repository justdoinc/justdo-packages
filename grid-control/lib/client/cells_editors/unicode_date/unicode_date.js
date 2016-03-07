momentFormat = 'YYYY-MM-DD';
datepickerFormat = 'yy-mm-dd';

PACK.Editors.UnicodeDateEditor = function (args) {
  var $input;
  var currentValue;
  var scope = this;
  var calendarOpen = false;

  this.init = function () {
    var $editor = $("<div class='grid-editor unicode-date-editor' />");

    $input = $("<INPUT type=text class='editor-unicode-date' />");
    $editor
      .html($input)
      .appendTo(args.container);

    $input.datepicker({
      dateFormat: datepickerFormat,
      showOn: "button",
      buttonImageOnly: true,
      buttonImage: "/packages/stem-capital_grid-control/lib/client/cells_editors/unicode_date/media/calendar.gif",
      showAnim: "",
      beforeShow: function () {
        calendarOpen = true;
      },
      onSelect: function () {
        $input.focus();
      },
      onClose: function () {
        calendarOpen = false;

        $input.focus();
      }
    });
    $input.width($input.width() - 18);
  };

  this.destroy = function () {
    $.datepicker.dpDiv.stop(true, true);
    $input.datepicker("hide");
    $input.datepicker("destroy");
    $input.remove();
  };

  this.show = function () {
    if (calendarOpen) {
      $.datepicker.dpDiv.stop(true, true).show();
    }
  };

  this.hide = function () {
    if (calendarOpen) {
      $.datepicker.dpDiv.stop(true, true).hide();
    }
  };

  this.position = function (position) {
    if (!calendarOpen) {
      return;
    }
    $.datepicker.dpDiv
        .css("top", position.top + 30)
        .css("left", position.left);
  };

  this.focus = function () {
    $input.focus();
  };

  this.loadValue = function (item) {
    currentValue = item[args.column.field];
    $input.datepicker("setDate", currentValue);

    $input.focus();
    $input[0].setSelectionRange(10, 10);
  };

  this.serializeValue = function () {
    return $input.val();
  };

  this.applyValue = function (item, state) {
    item[args.column.field] = state;
  };

  this.isValueChanged = function () {
    return (!($input.val() == "" && currentValue == null)) && ($input.val() != currentValue);
  };

  this.validate = function () {
    if ($input.val()=='' || moment($input.val(), momentFormat, true).isValid()) {
      return {
        valid: true,
        msg: null
      };
    } else {
      return {
        valid: false,
        msg: null
      };
    }

  };

  this.init();
};
