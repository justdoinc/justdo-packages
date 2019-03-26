Package.describe({
  name: "twbs:bootstrap",
  summary: "A fork of Nemo64's meteor-bootstrap package disguised as twbs:bootstrap",
  // Note We desguided this pack as twbs:bootstrap so packages that depends on
  // it won't cause it to load and override our rules
  version: "3.3.5" // Should be same as the bootstrap version in use
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

  api.use("amplify", client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  // api.addFiles("bootstrap3/bootstrap.js", client);
  // api.addFiles("bootstrap3/bootstrap.css", client);

  api.addFiles("bootstrap4/popper.js", client);
  api.addFiles("bootstrap4/bootstrap.js", client);

  // Switch themes with: APP.bootstrap_themes_manager.setTheme("sketchy")

  api.addAssets("bootstrap4/themes/default/bootstrap.css", client);
  api.addAssets("bootstrap4/themes/cerulean/bootstrap.css", client);
  api.addAssets("bootstrap4/themes/minty/bootstrap.css", client);
  api.addAssets("bootstrap4/themes/sandstone/bootstrap.css", client);
  api.addAssets("bootstrap4/themes/sketchy/bootstrap.css", client);
  api.addAssets("bootstrap4/themes/superhero/bootstrap.css", client);

  api.addFiles("bootstrap4/themes-manager/themes-manager.coffee", client);

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  api.addFiles("bootstrap4/themes-manager/app-integration.coffee", client);

});
