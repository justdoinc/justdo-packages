Package.describe({
  summary: "Exposing internal Meteor APIs to hack Meteor easily",
  version: "2.1.1",
  git: "https://github.com/lamhieu-vk/meteorx.git",
  name: "meteorhacks:meteorx",
});

Package.onUse(function(api) {
  configurePackage(api);
  api.export(["MeteorX"]);
});

Package.onTest(function(api) {
  configurePackage(api);
  api.use(["tinytest"], "server");
  api.add_files(["test/server.js"], "server");
});

function configurePackage(api) {
  api.versionsFrom("METEOR@1.0");
  api.use(["random", "mongo"], "server");
  api.add_files(["src/livedata.js", "src/mongo-livedata.js", "src/server.js"], "server");
}
