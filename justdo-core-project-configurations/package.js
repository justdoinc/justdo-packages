Package.describe({
  name: "justdoinc:justdo-core-project-configurations",
  version: "1.0.0",
  summary: "In this package the core project configurations of the justdo Projects library are being defined - the pack started out of the need to demostrate how to use the project configuration APIs",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-core-project-configurations"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.use("aldeed:simple-schema@1.3.1", both);
  api.use("stem-capital:projects@0.1.0", both);

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.addFiles("lib/client/templates/project-uid.html", client);
  api.addFiles("lib/client/templates/project-uid.coffee", client);

  api.addFiles("lib/client/core-confs-ui-sections.coffee", client);
  api.addFiles("lib/client/core-confs-ui-templates.coffee", client);

  api.addFiles("lib/server/core-confs-definitions.coffee", server);

  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.html", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.coffee", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.sass", client);

  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.html", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.coffee", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.sass", client);

});
