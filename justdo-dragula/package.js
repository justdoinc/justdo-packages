Package.describe({
  name: "justdoinc:justdo-dragula",
  version: "1.0.0",
  summary: "based on Drag and drop so simple it hurts - https://bevacqua.github.io/dragula/",
  // git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-avatar"
});

client = "client"

Package.onUse(function (api) {
  api.addFiles("dragula.css", client);
  api.addFiles("dragula.js", client);

  // api.export("JustdoAvatar", client);
});
