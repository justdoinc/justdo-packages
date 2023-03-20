Package.describe({
  name: "justdoinc:justdo-avatar",
  version: "1.0.0",
  summary: "Display profile picture with fallback to user initials + Blaze template",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-avatar"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("templating", client);
  api.use("underscore", both);
  api.use("coffeescript", both);
  api.use("fourseven:scss@3.2.0", client);

  api.use("justdoinc:justdo-helpers", both);

  api.add_files("lib/settings.js", both);
  api.add_files("lib/both.coffee", both);

  api.add_files("lib/server.coffee", server);

  api.add_files("lib/templates.html", client);
  api.add_files("lib/client.coffee", client);
  api.add_files("lib/styles.sass", client);
  api.addAssets("lib/img/anonymous-profile-image.png", client);

  // Avatars box
  api.add_files("lib/avatars-box/avatars-box.html", client);
  api.add_files("lib/avatars-box/avatars-box.sass", client);
  api.add_files("lib/avatars-box/avatars-box.coffee", client);

  api.export("JustdoAvatar", both);
});
