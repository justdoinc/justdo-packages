Package.describe({
  name: "justdoinc:justdo-grid-visualization",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-grid-visualization"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", client);
  api.use("underscore", client);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/google-charts.coffee", client);
  api.addFiles("lib/client/canvg.coffee", client);

  api.addFiles("lib/client/grid-visualization.coffee", client);

  api.addFiles("lib/client/templates/config_section.html", client);
  api.addFiles("lib/client/templates/config_section.coffee", client);
  api.addFiles("lib/client/templates/config_section.sass", client);

  api.addFiles("lib/client/templates/menu-template.html", client);
  api.addFiles("lib/client/templates/menu-template.sass", client);
  api.addFiles("lib/client/templates/menu-template.coffee", client);

  api.addFiles("lib/client/templates/visualization-modal.html", client);
  api.addFiles("lib/client/templates/visualization-modal.coffee", client);
  api.addFiles("lib/client/templates/visualization-modal.sass", client);

  api.addAssets("lib/assets/canvg.min.js", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", client);
  // api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  api.addFiles("lib/client/app-integration.coffee", client);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  api.export("JustdoGridVisualization", client);
});
