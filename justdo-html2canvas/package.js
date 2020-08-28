Package.describe({
  name: "justdoinc:justdo-html2canvas",

  summary: "html2canvas",

  version: "0.4.1"
});

Package.onUse(function (api) {
  api.add_files("html2canvas.min.js", "client");
});
