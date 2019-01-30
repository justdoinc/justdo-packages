Package.describe({
  name: "justdoinc:justdo-core-user-conf",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-core-user-conf"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.use("justdoinc:justdo-user-config-ui@1.0.0", client);

  api.addFiles("lib/client/core-user-confs-ui-sections.coffee", client);
  api.addFiles("lib/client/core-user-confs-ui-templates.coffee", client);

  api.addFiles("lib/client/templates/core-profile-settings.html", client);
  api.addFiles("lib/client/templates/core-profile-settings.coffee", client);

  api.addFiles("lib/client/templates/core-date-time-settings.html", client);
  api.addFiles("lib/client/templates/core-date-time-settings.coffee", client);
});
