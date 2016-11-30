GridControl.installEditorExtension
  editor_name: "TextareaWithTreeControlsEditor"
  extended_editor_name: "TextareaEditor"
  prototype_extensions:
    generateInputWrappingElement: ->
      tree_control = @callFormatter("textWithTreeControls")

      $tree_control = $(tree_control)

      $tree_control
        .removeClass("grid-formatter")
        .addClass("grid-editor")
        .find(".grid-tree-control-text")
        .html(@$input)

      @$input.addClass "tree-control-textarea"

      return $tree_control