Package.describe({
  name: "justdoinc:justdo-legal-docs-versions",
  version: "1.0.0",
  summary: "Templates of JustDo legal document content",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-legal-docs"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.add_files("common.coffee", both);
  api.add_files("docs-versions.coffee", both);

  api.add_files("server/api.coffee", server);
  api.add_files("server/methods.coffee", server);

  api.add_files("client/api.coffee", client);

  api.export("JustdoLegalDocsVersions", both);
  api.export("JustdoLegalDocsVersionsApi", both);
});
