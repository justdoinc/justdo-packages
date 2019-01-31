Package.describe({
  name: "justdo:clipboard",
  summary: "A wrapper aroung lgarron/clipboard.js",
  version: "0.2.0",
  git: "https://github.com/lgarron/clipboard.js"
});

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.2");

  api.addFiles('lib/clipboard.js', 'client');

  api.export('clipboard', 'client');
});