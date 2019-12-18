Package.describe({
  name: "justdoinc:justdo-tab-switcher-dropdown-ui",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-internal-packages/tree/master/justdo-tab-switcher-dropdown-ui"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", client);
  api.use("underscore", client);
  api.use("templating", client);

  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.addFiles("lib/client/templates/tab-switcher-button.html", client);
  api.addFiles("lib/client/templates/tab-switcher-button.sass", client);
  api.addFiles("lib/client/templates/tab-switcher-button.coffee", client);

  api.addFiles("lib/client/templates/tab-switcher-dropdown.html", client);
  api.addFiles("lib/client/templates/tab-switcher-dropdown.sass", client);
  api.addFiles("lib/client/templates/tab-switcher-dropdown.coffee", client);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  // api.addFiles("lib/client/api.coffee", client);

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);

  api.export("TabSwitcherDropdown", client);
});
