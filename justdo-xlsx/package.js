Package.describe({
  name: "justdoinc:justdo-xlsx",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-xlsx"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.use("coffeescript", both);
  api.use("underscore", both);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);

  api.export("JustdoXlsx", both);
});
