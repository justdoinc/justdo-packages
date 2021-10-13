Package.describe({
  name: "froala:editor",
  summary: "A beautiful jQuery WYSIWYG HTML rich text editor.",
  version: "2.9.5",
  git: "https://github.com/froala/meteor-froala/"
});

Package.onUse(function(api) {
  api.use("jquery@1.0.1", "client");
  api.use("fortawesome:fontawesome@4.4.0", "client");

  api.use('fourseven:scss@3.2.0', client);

  api.addFiles("assets/css/froala_editor.min.css", "client");
  api.addFiles("assets/css/froala_style.min.css", "client");
  api.addFiles("assets/css/plugins/char_counter.min.css", "client");
  api.addFiles("assets/css/plugins/code_view.min.css", "client");
  api.addFiles("assets/css/plugins/colors.min.css", "client");
  api.addFiles("assets/css/plugins/draggable.min.css", "client");
  api.addFiles("assets/css/plugins/emoticons.min.css", "client");
  api.addFiles("assets/css/plugins/file.min.css", "client");
  api.addFiles("assets/css/plugins/fullscreen.min.css", "client");
  api.addFiles("assets/css/plugins/help.min.css", "client");
  api.addFiles("assets/css/plugins/image_manager.min.css", "client");
  api.addFiles("assets/css/plugins/image.min.css", "client");
  api.addFiles("assets/css/plugins/line_breaker.min.css", "client");
  api.addFiles("assets/css/plugins/quick_insert.min.css", "client");
  api.addFiles("assets/css/plugins/special_characters.min.css", "client");
  api.addFiles("assets/css/plugins/table.min.css", "client");
  api.addFiles("assets/css/plugins/video.min.css", "client");
  api.addFiles("assets/css/third_party/embedly.min.css", "client");
  // api.addFiles("assets/css/third_party/spell_checker.min.css", "client");
  api.addFiles("assets/css/third_party/image_tui.min.css", "client");
  api.addFiles("assets/js/froala_editor.min.js", "client");
  api.addFiles("assets/js/plugins/align.min.js", "client");
  api.addFiles("assets/js/plugins/char_counter.min.js", "client");
  api.addFiles("assets/js/plugins/code_beautifier.min.js", "client");
  api.addFiles("assets/js/plugins/code_view.min.js", "client");
  api.addFiles("assets/js/plugins/colors.min.js", "client");
  api.addFiles("assets/js/plugins/draggable.min.js", "client");
  api.addFiles("assets/js/plugins/emoticons.min.js", "client");
  api.addFiles("assets/js/plugins/entities.min.js", "client");
  api.addFiles("assets/js/plugins/file.min.js", "client");
  api.addFiles("assets/js/plugins/font_family.min.js", "client");
  api.addFiles("assets/js/plugins/font_size.min.js", "client");
  api.addFiles("assets/js/plugins/fullscreen.min.js", "client");
  api.addFiles("assets/js/plugins/help.min.js", "client");
  api.addFiles("assets/js/plugins/image.min.js", "client");
  api.addFiles("assets/js/plugins/image_manager.min.js", "client");
  api.addFiles("assets/js/plugins/inline_class.min.js", "client");
  api.addFiles("assets/js/plugins/inline_style.min.js", "client");
  api.addFiles("assets/js/plugins/line_breaker.min.js", "client");
  api.addFiles("assets/js/plugins/line_height.min.js", "client");
  api.addFiles("assets/js/plugins/link.min.js", "client");
  api.addFiles("assets/js/plugins/lists.min.js", "client");
  api.addFiles("assets/js/plugins/paragraph_format.min.js", "client");
  api.addFiles("assets/js/plugins/paragraph_style.min.js", "client");
  api.addFiles("assets/js/plugins/print.min.js", "client");
  api.addFiles("assets/js/plugins/quick_insert.min.js", "client");
  api.addFiles("assets/js/plugins/quote.min.js", "client");
  api.addFiles("assets/js/plugins/save.min.js", "client");
  api.addFiles("assets/js/plugins/special_characters.min.js", "client");
  api.addFiles("assets/js/plugins/table.min.js", "client");
  api.addFiles("assets/js/plugins/url.min.js", "client");
  api.addFiles("assets/js/plugins/video.min.js", "client");
  api.addFiles("assets/js/plugins/word_paste.min.js", "client");
  api.addFiles("assets/js/third_party/embedly.min.js", "client");
  api.addFiles("assets/js/third_party/font_awesome.min.js", "client");
  api.addFiles("assets/js/third_party/image_aviary.min.js", "client");
  api.addFiles("assets/js/third_party/image_tui.min.js", "client");
  // api.addFiles("assets/js/third_party/spell_checker.min.js", "client");

  api.addFiles("justdo-modifications.js", "client");
  api.addFiles("justdo-modifications.sass", "client");
});
