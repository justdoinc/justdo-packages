// XXX We should revisit how we factor MongoDB support into (1) the
// server-side node.js driver [which you might use independently of
// livedata, after all], (2) minimongo [ditto], and (3) Collection,
// which is the class that glues the two of them to Livedata, but also
// is generally the "public interface for newbies" to Mongo in the
// Meteor universe. We want to allow the components to be used
// independently, but we don't want to overwhelm the user with
// minutiae.

Package.describe({
  summary: "Adaptor for using MongoDB and Minimongo over DDP",
  version: '1.16.10',
});

Npm.depends({
  "mongodb-uri": "0.9.7"
});

Npm.strip({
  mongodb: ["test/"]
});

Package.onUse(function (api) {
  api.use('npm-mongo', 'server');
  api.use('allow-deny');

  api.use([
    'random',
    'ejson',
    'minimongo',
    'ddp',
    'tracker',
    'diff-sequence',
    'mongo-id',
    'check',
    'ecmascript',
    'mongo-dev-server',
    'logging'
  ]);

  // Make weak use of Decimal type on client
  api.use('mongo-decimal', 'client', {weak: true});
  api.use('mongo-decimal', 'server');
  api.use('justdoinc:justdo-core-helpers@1.0.0', ['client', 'server']);

  api.use('underscore', 'server');

  // Binary Heap data structure is used to optimize oplog observe driver
  // performance.
  api.use('binary-heap', 'server');

  // Allow us to detect 'insecure'.
  api.use('insecure', {weak: true});

  // Allow us to detect 'autopublish', and publish collections if it's loaded.
  api.use('autopublish', 'server', {weak: true});

  // Allow us to detect 'disable-oplog', which turns off oplog tailing for your
  // app even if it's configured in the environment. (This package will be
  // probably be removed before 1.0.)
  api.use('disable-oplog', 'server', {weak: true});

  // defaultRemoteCollectionDriver gets its deployConfig from something that is
  // (for questionable reasons) initialized by the webapp package.
  api.use('webapp', 'server', {weak: true});

  // If the facts package is loaded, publish some statistics.
  api.use('facts-base', 'server', {weak: true});

  api.use('callback-hook', 'server');

  // Stuff that should be exposed via a real API, but we haven't yet.
  api.export('MongoInternals', 'server');

  api.export("Mongo");
  api.export('ObserveMultiplexer', 'server', {testOnly: true});

  api.addFiles(['mongo_driver.js', 'oplog_tailing.js',
                 'observe_multiplex.js', 'doc_fetcher.js',
                 'polling_observe_driver.js','oplog_observe_driver.js', 'oplog_v2_converter.js'],
                'server');
  api.addFiles('local_collection_driver.js', ['client', 'server']);
  api.addFiles('remote_collection_driver.js', 'server');
  api.addFiles('collection.js', ['client', 'server']);
  api.addFiles('connection_options.js', 'server');
  api.addAssets('mongo.d.ts', 'server');
});

Package.onTest(function (api) {
  api.use('mongo');
  api.use('check');
  api.use('ecmascript');
  api.use('npm-mongo', 'server');
  api.use(['tinytest', 'underscore', 'test-helpers', 'ejson', 'random',
           'ddp', 'base64']);
  // XXX test order dependency: the allow_tests "partial allow" test
  // fails if it is run before mongo_livedata_tests.
  api.addFiles('mongo_livedata_tests.js', ['client', 'server']);
  api.addFiles('upsert_compatibility_test.js', 'server');
  api.addFiles('allow_tests.js', ['client', 'server']);
  api.addFiles('collection_tests.js', ['client', 'server']);
  api.addFiles('collection_async_tests.js', ['client', 'server']);
  api.addFiles('observe_changes_tests.js', ['client', 'server']);
  api.addFiles('oplog_tests.js', 'server');
  api.addFiles('oplog_v2_converter_tests.js', 'server');
  api.addFiles('doc_fetcher_tests.js', 'server');
});
