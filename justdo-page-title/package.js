Package.describe({
  name: "justdoinc:justdo-page-title",
  version: "1.1.0",
  summary: "Set document title",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-page-title"
});

client = "client"
server = "server"
both = [client, server]
Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("underscore", client);
  api.use("coffeescript", client);

  api.add_files("lib/client.coffee", client);

  api.export("PageTitleManager", client);
});