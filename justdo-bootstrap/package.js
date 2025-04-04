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

  api.use("webapp", both);

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("amplify", client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);
  api.use("tap:i18n", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("bootstrap4/popper.js", client);
  api.addFiles("bootstrap4/bootstrap.js", client);

  api.addFiles("themes-manager/themes-manager.coffee", client);
  api.addFiles("themes-manager/injected-theme.coffee", server);

  // Themes selector
  api.addFiles("themes-selector/themes-selector.sass", client);
  api.addFiles("themes-selector/themes-selector.html", client);
  api.addFiles("themes-selector/themes-selector.coffee", client);

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  api.addFiles("themes-manager/app-integration.coffee", client);
  api.addFiles("themes-manager/web-app-integration.coffee", client);

  // Always after templates
  this.addI18nFiles(api, "i18n/{}.i18n.json");
  
});
