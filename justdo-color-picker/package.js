Package.describe({
  name: "justdoinc:justdo-color-picker",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-color-picker"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use('fourseven:scss@3.2.0', client);
  api.use("ecmascript");

  api.addFiles("lib/client/color-picker.scss", "client");
  api.mainModule("lib/client/main.js", "client", { lazy: true });
});
