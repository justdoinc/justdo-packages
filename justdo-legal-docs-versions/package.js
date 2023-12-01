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

  api.addFiles("common.coffee", both);
  api.addFiles("docs-versions.coffee", both);

  api.addFiles("server/api.coffee", server);
  api.addFiles("server/methods.coffee", server);

  api.addFiles("client/api.coffee", client);

  api.export("JustdoLegalDocsVersions", both);
  api.export("JustdoLegalDocsVersionsApi", both);
});
