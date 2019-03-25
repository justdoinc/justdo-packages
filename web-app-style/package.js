Package.describe({
  name: "justdoinc:web-app-style",
  summary: "",
  version: "0.1.0"
});

Package.onUse(function (api) {
  api.versionsFrom("1.2.1");

  api.use("twbs:bootstrap@3.3.5");

  api.use('fourseven:scss@3.2.0', client);

  api.addFiles('lib/overrides.sass', 'client');
});
