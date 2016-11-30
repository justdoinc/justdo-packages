// PACK.Editors.TextWithTreeControlsEditor = function (args) {
//   var active_cell = args.grid.getActiveCell();
  
//   var $input;
//   var defaultValue;
//   var scope = this;

//   var grid_control = args.grid_control

//   this.init = function () {
//     var tree_control =
//       grid_control._formatters.textWithTreeControls(active_cell.row, active_cell.cell, "");

//     var $tree_control = $(tree_control);

//     $tree_control
//       .removeClass("grid-formatter")
//       .addClass("grid-editor")
//       .find(".grid-tree-control-text")
//       .html("<input type='text' class='tree-control-input' />");

//     $(args.container).html($tree_control);

//     $input = $tree_control.find(".tree-control-input");

//     $input
//         .bind("keydown.nav", function (e) {
//           if (e.keyCode === $.ui.keyCode.LEFT || e.keyCode === $.ui.keyCode.RIGHT) {
//             e.stopImmediatePropagation();
//           }
//         });
//   };

//   this.destroy = function () {
//     $input.remove();
//   };

//   this.focus = function () {
//     $input.focus();
//   };

//   this.getValue = function () {
//     return $input.val();
//   };

//   this.setValue = function (val) {
//     $input.val(val);
//   };

//   this.loadValue = function (item) {
//     defaultValue = item[args.column.field] || "";
//     $input
//       .val(defaultValue)
//       .focus();
//     $input[0].setSelectionRange(defaultValue.length, defaultValue.length);
//     $input[0].defaultValue = defaultValue;
//   };

//   this.serializeValue = function () {
//     return $input.val();
//   };

//   this.applyValue = function (item, state) {
//     item[args.column.field] = state;
//   };

//   this.isValueChanged = function () {
//     return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
//   };

//   this.validate = function () {
//     if (args.column.validator) {
//       var validationResults = args.column.validator($input.val());
//       if (!validationResults.valid) {
//         return validationResults;
//       }
//     }

//     return {
//       valid: true,
//       msg: null
//     };
//   };

//   this.init();
// };
