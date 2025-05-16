Package.describe({
  name: "justdoinc:justdo-ai-kit",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-ai-kit"
});

client = "client"
server = "server"
both = [client, server]

Npm.depends({
  "openai": "4.51.0",
  "jsonrepair": "3.12.0"
});

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);
  api.use("ejson", both);

  // Uncomment if you want to use NPM peer dependencies using
  // checkNpmVersions.
  //
  // Introducing new NPM packages procedure:
  //
  // * Uncomment the lines below.
  // * Add your packages to the main web-app package.json dependencies section.
  // * Call $ meteor npm install
  // * Call $ meteor npm shrinkwrap
  //
  // Add to the peer dependencies checks to one of the JS/Coffee files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-ai-kit')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("iron:router@1.1.2", both);

  api.use("check", both);
  api.use("justdoinc:justdo-analytics@1.0.0", both);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);
  api.use("stem-capital:projects@0.1.0", both, {weak: true});
  api.use("justdoinc:justdo-snackbar@1.0.0", client);
  api.use("justdoinc:justdo-new-project-templates@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("http", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.use("ddp-server@2.1.0", server);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/router.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/static.coffee", server);
  // <Vendor-specific files>
  api.addFiles("lib/server/vendor-api/vendor-api-constructor.coffee", server);
  // OpenAI
  api.addFiles("lib/server/vendor-api/openai/static.coffee", server);
  api.addFiles("lib/server/vendor-api/openai/openai.coffee", server);
  // Ollama
  api.addFiles("lib/server/vendor-api/ollama/static.coffee", server);
  api.addFiles("lib/server/vendor-api/ollama/ollama.coffee", server);
  // </Vendor-specific files>
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/typed.umd.js", client);
  api.addFiles("lib/client/showdown.min.js", client);

  api.addFiles("lib/client/template-generator/template-generator-controller.coffee", client);
  api.addFiles("lib/client/template-generator/template-generator.sass", client);
  api.addFiles("lib/client/template-generator/template-generator.html", client);
  api.addFiles("lib/client/template-generator/template-generator.coffee", client);

  api.addFiles("lib/client/project-template-welcome-ai/project-template-welcome-ai.sass", client);
  api.addFiles("lib/client/project-template-welcome-ai/project-template-welcome-ai.html", client);
  api.addFiles("lib/client/project-template-welcome-ai/project-template-welcome-ai.coffee", client);

  api.addFiles("lib/client/tasks-summary/tasks-summary.html", client);
  api.addFiles("lib/client/tasks-summary/tasks-summary.sass", client);
  api.addFiles("lib/client/tasks-summary/tasks-summary.coffee", client);

  api.addFiles("lib/client/ai-wizard-tooltip/ai-wizard-tooltip.html", client);
  api.addFiles("lib/client/ai-wizard-tooltip/ai-wizard-tooltip.sass", client);
  api.addFiles("lib/client/ai-wizard-tooltip/ai-wizard-tooltip.coffee", client);

  api.addFiles("lib/client/user-journey-ai-section/user-journey-ai-section.sass", client);
  api.addFiles("lib/client/user-journey-ai-section/user-journey-ai-section.html", client);
  api.addFiles("lib/client/user-journey-ai-section/user-journey-ai-section.coffee", client);

  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page-filter-dropdown.sass", client);
  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page-filter-dropdown.html", client);
  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page-filter-dropdown.coffee", client);

  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page.sass", client);
  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page.html", client);
  api.addFiles("lib/client/site-admin-anon-ai-requests-page/site-admin-anon-ai-requests-page.coffee", client);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  // api.addFiles("lib/client/project-conf/project-conf.sass", client);
  // api.addFiles("lib/client/project-conf/project-conf.html", client);
  // api.addFiles("lib/client/project-conf/project-conf.coffee", client);

  // api.addFiles("lib/client/plugin-page/plugin-page.sass", client);
  // api.addFiles("lib/client/plugin-page/plugin-page.html", client);
  // api.addFiles("lib/client/plugin-page/plugin-page.coffee", client);

  // api.addFiles("lib/client/task-pane-section/task-pane-section-registrar.coffee", client);

  // api.addFiles("lib/client/task-pane-section/task-pane-section.sass", client);
  // api.addFiles("lib/client/task-pane-section/task-pane-section.html", client);
  // api.addFiles("lib/client/task-pane-section/task-pane-section.coffee", client);

  api.addFiles("lib/client/chatbox/chatbox.sass", client);
  api.addFiles("lib/client/chatbox/chatbox.html", client);
  api.addFiles("lib/client/chatbox/chatbox.coffee", client);

  // I18n files. Always after template.
  this.addI18nFiles(api, "i18n/part1.{}.i18n.json");
  this.addI18nFiles(api, "i18n/part2.{}.i18n.json");
  this.addI18nFiles(api, "i18n/template-generator-examples/{}.i18n.json");

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoAiKit", both);
});
