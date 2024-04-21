GridControl.installEditorExtension
  editor_name: "TextareaWithTreeControlsEditor"
  extended_editor_name: "TextareaEditor"
  prototype_extensions:
    generateInputWrappingElement: ->
      tree_control = @callFormatter("textWithTreeControls")

      $tree_control = $(tree_control)

      $tree_control
        .filter(".text-tree-control") # we filter to avoid affecting the priority indicator which we need to keep outside the grid-formatter container due to positioning needs (need it relative to the .slick-dynamic-row-height .slick-cell for correct height)
        .removeClass("grid-formatter")
        .addClass("grid-editor")
        .find(".grid-tree-control-text")
        .html(@$input)

      @$input.addClass "tree-control-textarea"

      return $tree_control