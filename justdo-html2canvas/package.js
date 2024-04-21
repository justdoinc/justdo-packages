Package.describe({
  name: "justdoinc:justdo-html2canvas",

  summary: "html2canvas",

  version: "1.0.0"
});

Package.onUse(function (api) {
  api.addFiles("html2canvas.min.js", "client");
});
