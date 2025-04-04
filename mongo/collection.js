// options.connection, if given, is a LivedataClient or LivedataServer
// XXX presently there is no way to destroy/clean up a Collection
import {
  ASYNC_COLLECTION_METHODS,
  getAsyncMethodName,
} from 'meteor/minimongo/constants';

import { normalizeProjection } from './mongo_utils';
export function warnUsingOldApi(methodName, collectionName, isCalledFromAsync) {
  if (
    process.env.WARN_WHEN_USING_OLD_API && // also ensures it is on the server
    !isCalledFromAsync // must be true otherwise we should log
  ) {
    if (collectionName === undefined || collectionName.includes('oplog'))
      return;
    console.warn(`
   
   Calling method ${collectionName}.${methodName} from old API on server.
   This method will be removed, from the server, in version 3.
   Trace is below:`);
    console.trace();
  }
}
/**
 * @summary Namespace for MongoDB-related items
 * @namespace
 */
Mongo = {};

/**
 * @summary Constructor for a Collection
 * @locus Anywhere
 * @instancename collection
 * @class
 * @param {String} name The name of the collection.  If null, creates an unmanaged (unsynchronized) local collection.
 * @param {Object} [options]
 * @param {Object} options.connection The server connection that will manage this collection. Uses the default connection if not specified.  Pass the return value of calling [`DDP.connect`](#ddp_connect) to specify a different server. Pass `null` to specify no connection. Unmanaged (`name` is null) collections cannot specify a connection.
 * @param {String} options.idGeneration The method of generating the `_id` fields of new documents in this collection.  Possible values:

 - **`'STRING'`**: random strings
 - **`'MONGO'`**:  random [`Mongo.ObjectID`](#mongo_object_id) values

The default id generation technique is `'STRING'`.
 * @param {Function} options.transform An optional transformation function. Documents will be passed through this function before being returned from `fetch` or `findOne`, and before being passed to callbacks of `observe`, `map`, `forEach`, `allow`, and `deny`. Transforms are *not* applied for the callbacks of `observeChanges` or to cursors returned from publish functions.
 * @param {Boolean} options.defineMutationMethods Set to `false` to skip setting up the mutation methods that enable insert/update/remove from client code. Default `true`.
 */
Mongo.Collection = function Collection(name, options) {
  if (!name && name !== null) {
    Meteor._debug(
      'Warning: creating anonymous collection. It will not be ' +
        'saved or synchronized over the network. (Pass null for ' +
        'the collection name to turn off this warning.)'
    );
    name = null;
  }

  if (name !== null && typeof name !== 'string') {
    throw new Error(
      'First argument to new Mongo.Collection must be a string or null'
    );
  }

  if (options && options.methods) {
    // Backwards compatibility hack with original signature (which passed
    // "connection" directly instead of in options. (Connections must have a "methods"
    // method.)
    // XXX remove before 1.0
    options = { connection: options };
  }
  // Backwards compatibility: "connection" used to be called "manager".
  if (options && options.manager && !options.connection) {
    options.connection = options.manager;
  }

  options = {
    connection: undefined,
    idGeneration: 'STRING',
    transform: null,
    _driver: undefined,
    _preventAutopublish: false,
    ...options,
  };

  switch (options.idGeneration) {
    case 'MONGO':
      this._makeNewID = function() {
        var src = name
          ? DDP.randomStream('/collection/' + name)
          : Random.insecure;
        return new Mongo.ObjectID(src.hexString(24));
      };
      break;
    case 'STRING':
    default:
      this._makeNewID = function() {
        var src = name
          ? DDP.randomStream('/collection/' + name)
          : Random.insecure;
        return src.id();
      };
      break;
  }

  this._transform = LocalCollection.wrapTransform(options.transform);

  if (!name || options.connection === null)
    // note: nameless collections never have a connection
    this._connection = null;
  else if (options.connection) this._connection = options.connection;
  else if (Meteor.isClient) this._connection = Meteor.connection;
  else this._connection = Meteor.server;

  if (!options._driver) {
    // XXX This check assumes that webapp is loaded so that Meteor.server !==
    // null. We should fully support the case of "want to use a Mongo-backed
    // collection from Node code without webapp", but we don't yet.
    // #MeteorServerNull
    if (
      name &&
      this._connection === Meteor.server &&
      typeof MongoInternals !== 'undefined' &&
      MongoInternals.defaultRemoteCollectionDriver
    ) {
      options._driver = MongoInternals.defaultRemoteCollectionDriver();
    } else {
      const { LocalCollectionDriver } = require('./local_collection_driver.js');
      options._driver = LocalCollectionDriver;
    }
  }

  this._collection = options._driver.open(name, this._connection);
  this._name = name;
  this._driver = options._driver;

  this._maybeSetUpReplication(name, options);

  // XXX don't define these until allow or deny is actually used for this
  // collection. Could be hard if the security rules are only defined on the
  // server.
  if (options.defineMutationMethods !== false) {
    try {
      this._defineMutationMethods({
        useExisting: options._suppressSameNameError === true,
      });
    } catch (error) {
      // Throw a more understandable error on the server for same collection name
      if (
        error.message === `A method named '/${name}/insert' is already defined`
      )
        throw new Error(`There is already a collection named "${name}"`);
      throw error;
    }
  }

  // autopublish
  if (
    Package.autopublish &&
    !options._preventAutopublish &&
    this._connection &&
    this._connection.publish
  ) {
    this._connection.publish(null, () => this.find(), {
      is_auto: true,
    });
  }
};

Object.assign(Mongo.Collection.prototype, {
  _maybeSetUpReplication(name, { _suppressSameNameError = false }) {
    const self = this;
    if (!(self._connection && self._connection.registerStore)) {
      return;
    }

    // OK, we're going to be a slave, replicating some remote
    // database, except possibly with some temporary divergence while
    // we have unacknowledged RPC's.
    const ok = self._connection.registerStore(name, {
      // Called at the beginning of a batch of updates. batchSize is the number
      // of update calls to expect.
      //
      // XXX This interface is pretty janky. reset probably ought to go back to
      // being its own function, and callers shouldn't have to calculate
      // batchSize. The optimization of not calling pause/remove should be
      // delayed until later: the first call to update() should buffer its
      // message, and then we can either directly apply it at endUpdate time if
      // it was the only update, or do pauseObservers/apply/apply at the next
      // update() if there's another one.
      beginUpdate(batchSize, reset) {
        // pause observers so users don't see flicker when updating several
        // objects at once (including the post-reconnect reset-and-reapply
        // stage), and so that a re-sorting of a query can take advantage of the
        // full _diffQuery moved calculation instead of applying change one at a
        // time.
        if (batchSize > 1 || reset) self._collection.pauseObservers();

        if (reset) self._collection.remove({});
      },

      // Apply an update.
      // XXX better specify this interface (not in terms of a wire message)?
      update(msg) {
        var mongoId = MongoID.idParse(msg.id);
        var doc = self._collection._docs.get(mongoId);

        //When the server's mergebox is disabled for a collection, the client must gracefully handle it when:
        // *We receive an added message for a document that is already there. Instead, it will be changed
        // *We reeive a change message for a document that is not there. Instead, it will be added
        // *We receive a removed messsage for a document that is not there. Instead, noting wil happen.

        //Code is derived from client-side code originally in peerlibrary:control-mergebox
        //https://github.com/peerlibrary/meteor-control-mergebox/blob/master/client.coffee

        //For more information, refer to discussion "Initial support for publication strategies in livedata server":
        //https://github.com/meteor/meteor/pull/11151
        if (Meteor.isClient) {
          if (msg.msg === 'added' && doc) {
            msg.msg = 'changed';
          } else if (msg.msg === 'removed' && !doc) {
            return;
          } else if (msg.msg === 'changed' && !doc) {
            msg.msg = 'added';
            _ref = msg.fields;
            for (field in _ref) {
              value = _ref[field];
              if (value === void 0) {
                delete msg.fields[field];
              }
            }
          }
        }

        // Is this a "replace the whole doc" message coming from the quiescence
        // of method writes to an object? (Note that 'undefined' is a valid
        // value meaning "remove it".)
        if (msg.msg === 'replace') {
          var replace = msg.replace;
          if (!replace) {
            if (doc) self._collection.remove(mongoId);
          } else if (!doc) {
            self._collection.insert(replace);
          } else {
            // XXX check that replace has no $ ops
            self._collection.update(mongoId, replace);
          }
          return;
        } else if (msg.msg === 'added') {
          if (doc) {
            throw new Error(
              'Expected not to find a document already present for an add'
            );
          }
          self._collection.insert({ _id: mongoId, ...msg.fields });
        } else if (msg.msg === 'removed') {
          if (!doc)
            throw new Error(
              'Expected to find a document already present for removed'
            );
          self._collection.remove(mongoId);
        } else if (msg.msg === 'changed') {
          if (!doc) throw new Error('Expected to find a document to change');
          const keys = Object.keys(msg.fields);
          if (keys.length > 0) {
            var modifier = {};
            keys.forEach(key => {
              const value = msg.fields[key];
              if (EJSON.equals(doc[key], value)) {
                return;
              }
              if (typeof value === 'undefined') {
                if (!modifier.$unset) {
                  modifier.$unset = {};
                }
                modifier.$unset[key] = 1;
              } else {
                if (!modifier.$set) {
                  modifier.$set = {};
                }
                modifier.$set[key] = value;
              }
            });
            if (Object.keys(modifier).length > 0) {
              self._collection.update(mongoId, modifier);
            }
          }
        } else {
          throw new Error("I don't know how to deal with this message");
        }
      },

      // Called at the end of a batch of updates.
      endUpdate() {
        self._collection.resumeObservers();
      },

      // Called around method stub invocations to capture the original versions
      // of modified documents.
      saveOriginals() {
        self._collection.saveOriginals();
      },
      retrieveOriginals() {
        return self._collection.retrieveOriginals();
      },

      // Used to preserve current versions of documents across a store reset.
      getDoc(id) {
        return self.findOne(id);
      },

      // To be able to get back to the collection from the store.
      _getCollection() {
        return self;
      },
    });

    if (!ok) {
      const message = `There is already a collection named "${name}"`;
      if (_suppressSameNameError === true) {
        // XXX In theory we do not have to throw when `ok` is falsy. The
        // store is already defined for this collection name, but this
        // will simply be another reference to it and everything should
        // work. However, we have historically thrown an error here, so
        // for now we will skip the error only when _suppressSameNameError
        // is `true`, allowing people to opt in and give this some real
        // world testing.
        console.warn ? console.warn(message) : console.log(message);
      } else {
        throw new Error(message);
      }
    }
  },

  ///
  /// Main collection API
  ///
  /**
   * @summary Gets the number of documents matching the filter. For a fast count of the total documents in a collection see `estimatedDocumentCount`.
   * @locus Anywhere
   * @method countDocuments
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} [selector] A query describing the documents to count
   * @param {Object} [options] All options are listed in [MongoDB documentation](https://mongodb.github.io/node-mongodb-native/4.11/interfaces/CountDocumentsOptions.html). Please note that not all of them are available on the client.
   * @returns {Promise<number>}
   */
  countDocuments(...args) {
    return this._collection.countDocuments(...args);
  },

  /**
   * @summary Gets an estimate of the count of documents in a collection using collection metadata. For an exact count of the documents in a collection see `countDocuments`.
   * @locus Anywhere
   * @method estimatedDocumentCount
   * @memberof Mongo.Collection
   * @instance
   * @param {Object} [options] All options are listed in [MongoDB documentation](https://mongodb.github.io/node-mongodb-native/4.11/interfaces/EstimatedDocumentCountOptions.html). Please note that not all of them are available on the client.
   * @returns {Promise<number>}
   */
  estimatedDocumentCount(...args) {
    return this._collection.estimatedDocumentCount(...args);
  },

  _getFindSelector(args) {
    if (args.length == 0) return {};
    else return args[0];
  },

  _getFindOptions(args) {
    const [, options] = args || [];
    const newOptions = normalizeProjection(options);

    var self = this;
    if (args.length < 2) {
      return { transform: self._transform };
    } else {
      check(
        newOptions,
        Match.Optional(
          Match.ObjectIncluding({
            projection: Match.Optional(Match.OneOf(Object, undefined)),
            sort: Match.Optional(
              Match.OneOf(Object, Array, Function, undefined)
            ),
            limit: Match.Optional(Match.OneOf(Number, undefined)),
            skip: Match.Optional(Match.OneOf(Number, undefined)),
          })
        )
      );

      return {
        transform: self._transform,
        ...newOptions,
      };
    }
  },

  /**
   * @summary Find the documents in a collection that match the selector.
   * @locus Anywhere
   * @method find
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} [selector] A query describing the documents to find
   * @param {Object} [options]
   * @param {MongoSortSpecifier} options.sort Sort order (default: natural order)
   * @param {Number} options.skip Number of results to skip at the beginning
   * @param {Number} options.limit Maximum number of results to return
   * @param {MongoFieldSpecifier} options.fields Dictionary of fields to return or exclude.
   * @param {Boolean} options.reactive (Client only) Default `true`; pass `false` to disable reactivity
   * @param {Function} options.transform Overrides `transform` on the  [`Collection`](#collections) for this cursor.  Pass `null` to disable transformation.
   * @param {Boolean} options.disableOplog (Server only) Pass true to disable oplog-tailing on this query. This affects the way server processes calls to `observe` on this query. Disabling the oplog can be useful when working with data that updates in large batches.
   * @param {Number} options.pollingIntervalMs (Server only) When oplog is disabled (through the use of `disableOplog` or when otherwise not available), the frequency (in milliseconds) of how often to poll this query when observing on the server. Defaults to 10000ms (10 seconds).
   * @param {Number} options.pollingThrottleMs (Server only) When oplog is disabled (through the use of `disableOplog` or when otherwise not available), the minimum time (in milliseconds) to allow between re-polling when observing on the server. Increasing this will save CPU and mongo load at the expense of slower updates to users. Decreasing this is not recommended. Defaults to 50ms.
   * @param {Number} options.maxTimeMs (Server only) If set, instructs MongoDB to set a time limit for this cursor's operations. If the operation reaches the specified time limit (in milliseconds) without the having been completed, an exception will be thrown. Useful to prevent an (accidental or malicious) unoptimized query from causing a full collection scan that would disrupt other database users, at the expense of needing to handle the resulting error.
   * @param {String|Object} options.hint (Server only) Overrides MongoDB's default index selection and query optimization process. Specify an index to force its use, either by its name or index specification. You can also specify `{ $natural : 1 }` to force a forwards collection scan, or `{ $natural : -1 }` for a reverse collection scan. Setting this is only recommended for advanced users.
   * @param {String} options.readPreference (Server only) Specifies a custom MongoDB [`readPreference`](https://docs.mongodb.com/manual/core/read-preference) for this particular cursor. Possible values are `primary`, `primaryPreferred`, `secondary`, `secondaryPreferred` and `nearest`.
   * @returns {Mongo.Cursor}
   */
  find(...args) {
    // Collection.find() (return all docs) behaves differently
    // from Collection.find(undefined) (return 0 docs).  so be
    // careful about the length of arguments.
    return this._collection.find(
      this._getFindSelector(args),
      this._getFindOptions(args)
    );
  },

  /**
   * @summary Finds the first document that matches the selector, as ordered by sort and skip options. Returns `undefined` if no matching document is found.
   * @locus Anywhere
   * @method findOne
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} [selector] A query describing the documents to find
   * @param {Object} [options]
   * @param {MongoSortSpecifier} options.sort Sort order (default: natural order)
   * @param {Number} options.skip Number of results to skip at the beginning
   * @param {MongoFieldSpecifier} options.fields Dictionary of fields to return or exclude.
   * @param {Boolean} options.reactive (Client only) Default true; pass false to disable reactivity
   * @param {Function} options.transform Overrides `transform` on the [`Collection`](#collections) for this cursor.  Pass `null` to disable transformation.
   * @param {String} options.readPreference (Server only) Specifies a custom MongoDB [`readPreference`](https://docs.mongodb.com/manual/core/read-preference) for fetching the document. Possible values are `primary`, `primaryPreferred`, `secondary`, `secondaryPreferred` and `nearest`.
   * @returns {Object}
   */
  findOne(...args) {
    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi('findOne', this._name, this.findOne.isCalledFromAsync);
    this.findOne.isCalledFromAsync = false;

    return this._collection.findOne(
      this._getFindSelector(args),
      this._getFindOptions(args)
    );
  },
});

Object.assign(Mongo.Collection, {
  _publishCursor(cursor, sub, collection) {
    var observeHandle = cursor.observeChanges(
      {
        added: function(id, fields) {
          sub.added(collection, id, fields);
        },
        changed: function(id, fields) {
          sub.changed(collection, id, fields);
        },
        removed: function(id) {
          sub.removed(collection, id);
        },
      },
      // Publications don't mutate the documents
      // This is tested by the `livedata - publish callbacks clone` test
      { nonMutatingCallbacks: true }
    );

    // We don't call sub.ready() here: it gets called in livedata_server, after
    // possibly calling _publishCursor on multiple returned cursors.

    // register stop callback (expects lambda w/ no args).
    sub.onStop(function() {
      observeHandle.stop();
    });

    // return the observeHandle in case it needs to be stopped early
    return observeHandle;
  },

  // protect against dangerous selectors.  falsey and {_id: falsey} are both
  // likely programmer error, and not what you want, particularly for destructive
  // operations. If a falsey _id is sent in, a new string _id will be
  // generated and returned; if a fallbackId is provided, it will be returned
  // instead.
  _rewriteSelector(selector, { fallbackId } = {}) {
    // shorthand -- scalars match _id
    if (LocalCollection._selectorIsId(selector)) selector = { _id: selector };

    if (Array.isArray(selector)) {
      // This is consistent with the Mongo console itself; if we don't do this
      // check passing an empty array ends up selecting all items
      throw new Error("Mongo selector can't be an array.");
    }

    if (!selector || ('_id' in selector && !selector._id)) {
      // can't match anything
      return { _id: fallbackId || Random.id() };
    }

    return selector;
  },
});

Object.assign(Mongo.Collection.prototype, {
  // 'insert' immediately returns the inserted document's new _id.
  // The others return values immediately if you are in a stub, an in-memory
  // unmanaged collection, or a mongo-backed collection and you don't pass a
  // callback. 'update' and 'remove' return the number of affected
  // documents. 'upsert' returns an object with keys 'numberAffected' and, if an
  // insert happened, 'insertedId'.
  //
  // Otherwise, the semantics are exactly like other methods: they take
  // a callback as an optional last argument; if no callback is
  // provided, they block until the operation is complete, and throw an
  // exception if it fails; if a callback is provided, then they don't
  // necessarily block, and they call the callback when they finish with error and
  // result arguments.  (The insert method provides the document ID as its result;
  // update and remove provide the number of affected docs as the result; upsert
  // provides an object with numberAffected and maybe insertedId.)
  //
  // On the client, blocking is impossible, so if a callback
  // isn't provided, they just return immediately and any error
  // information is lost.
  //
  // There's one more tweak. On the client, if you don't provide a
  // callback, then if there is an error, a message will be logged with
  // Meteor._debug.
  //
  // The intent (though this is actually determined by the underlying
  // drivers) is that the operations should be done synchronously, not
  // generating their result until the database has acknowledged
  // them. In the future maybe we should provide a flag to turn this
  // off.

  /**
   * @summary Insert a document in the collection.  Returns its unique _id.
   * @locus Anywhere
   * @method  insert
   * @memberof Mongo.Collection
   * @instance
   * @param {Object} doc The document to insert. May not yet have an _id attribute, in which case Meteor will generate one for you.
   * @param {Function} [callback] Optional.  If present, called with an error object as the first argument and, if no error, the _id as the second.
   */
  insert(doc, callback) {
    // Make sure we were passed a document to insert
    if (!doc) {
      throw new Error('insert requires an argument');
    }

    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi('insert', this._name, this.insert.isCalledFromAsync);
    this.insert.isCalledFromAsync = false;

    // Make a shallow clone of the document, preserving its prototype.
    doc = Object.create(
      Object.getPrototypeOf(doc),
      Object.getOwnPropertyDescriptors(doc)
    );

    if ('_id' in doc) {
      if (
        !doc._id ||
        !(typeof doc._id === 'string' || doc._id instanceof Mongo.ObjectID)
      ) {
        throw new Error(
          'Meteor requires document _id fields to be non-empty strings or ObjectIDs'
        );
      }
    } else {
      let generateId = true;

      // Don't generate the id if we're the client and the 'outermost' call
      // This optimization saves us passing both the randomSeed and the id
      // Passing both is redundant.
      if (this._isRemoteCollection()) {
        const enclosing = DDP._CurrentMethodInvocation.get();
        if (!enclosing) {
          generateId = false;
        }
      }

      if (generateId) {
        doc._id = this._makeNewID();
      }
    }

    // On inserts, always return the id that we generated; on all other
    // operations, just return the result from the collection.
    var chooseReturnValueFromCollectionResult = function(result) {
      if (doc._id) {
        return doc._id;
      }

      // XXX what is this for??
      // It's some iteraction between the callback to _callMutatorMethod and
      // the return value conversion
      doc._id = result;

      return result;
    };

    const wrappedCallback = wrapCallback(
      callback,
      chooseReturnValueFromCollectionResult
    );

    if (this._isRemoteCollection()) {
      const result = this._callMutatorMethod('insert', [doc], wrappedCallback);
      return chooseReturnValueFromCollectionResult(result);
    }

    // it's my collection.  descend into the collection object
    // and propagate any exception.
    try {
      // If the user provided a callback and the collection implements this
      // operation asynchronously, then queryRet will be undefined, and the
      // result will be returned through the callback instead.
      const result = this._collection.insert(doc, wrappedCallback);
      return chooseReturnValueFromCollectionResult(result);
    } catch (e) {
      if (callback) {
        callback(e);
        return null;
      }
      throw e;
    }
  },

  /**
   * @summary Modify one or more documents in the collection. Returns the number of matched documents.
   * @locus Anywhere
   * @method update
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} selector Specifies which documents to modify
   * @param {MongoModifier} modifier Specifies how to modify the documents
   * @param {Object} [options]
   * @param {Boolean} options.multi True to modify all matching documents; false to only modify one of the matching documents (the default).
   * @param {Boolean} options.upsert True to insert a document if no matching documents are found.
   * @param {Array} options.arrayFilters Optional. Used in combination with MongoDB [filtered positional operator](https://docs.mongodb.com/manual/reference/operator/update/positional-filtered/) to specify which elements to modify in an array field.
   * @param {Function} [callback] Optional.  If present, called with an error object as the first argument and, if no error, the number of affected documents as the second.
   */
  update(selector, modifier, ...optionsAndCallback) {
    const callback = popCallbackFromArgs(optionsAndCallback);

    // We've already popped off the callback, so we are left with an array
    // of one or zero items
    const options = { ...(optionsAndCallback[0] || null) };
    let insertedId;
    if (options && options.upsert) {
      // set `insertedId` if absent.  `insertedId` is a Meteor extension.
      if (options.insertedId) {
        if (
          !(
            typeof options.insertedId === 'string' ||
            options.insertedId instanceof Mongo.ObjectID
          )
        )
          throw new Error('insertedId must be string or ObjectID');
        insertedId = options.insertedId;
      } else if (!selector || !selector._id) {
        insertedId = this._makeNewID();
        options.generatedId = true;
        options.insertedId = insertedId;
      }
    }

    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi('update', this._name, this.update.isCalledFromAsync);
    this.update.isCalledFromAsync = false;

    selector = Mongo.Collection._rewriteSelector(selector, {
      fallbackId: insertedId,
    });

    const wrappedCallback = wrapCallback(callback);
  
    const fields_by_update_type = JustdoCoreHelpers.getFieldsByUpdateTypeFromModifier(this, modifier);

    if (fields_by_update_type.regular.length > 0 && fields_by_update_type.client_only.length > 0) {
      throw new Error("A mix of client-only fields (" + fields_by_update_type.client_only.join(", ") + ") and regular fields (" + fields_by_update_type.regular.join(", ") + ") received in the same update request. At the moment, such a call is not supported. Please separate the update to a client-side only fields update and to a regular fields only update.");
    }

    if (Meteor.isServer && fields_by_update_type.client_only.length > 0) {
      throw new Error("We don't allow update of client-only fields in the server side: " + fields_by_update_type.client_only.join(", "));
    }

    if (Meteor.isServer || (Meteor.isClient && fields_by_update_type.client_only.length == 0)) {
      if (this._isRemoteCollection()) {
        const args = [selector, modifier, options];

        return this._callMutatorMethod('update', args, wrappedCallback);
      }
    }

    // it's my collection.  descend into the collection object
    try {
      // If the user provided a callback and the collection implements this
      // operation asynchronously, then queryRet will be undefined, and the
      // result will be returned through the callback instead.
      if (!Meteor.isClient) {
        // On the server, there's no need to give consideration for client-only fields,
        // just execute the update.
        return this._collection.update(
          selector, modifier, options, wrappedCallback);
      } else {
        // Client-side execution with consideration to client-only fields: CLIENT-SITE-EXEC-CLIENT-ONLY-FIELDS
        // (see also similar procedures taken under justdo-internal-packages/minimongo/local_collection.js
        // setDocFields() )
        //
        // The following hook is used to determine which fields changed as a result of the
        // modifier.
        //
        // We need to determine those fields, to ensure that if there are ongoing updates
        // that are pending response from the server, we will update the expected doc post-update
        // to include the modified value of the client-only fields modified.
        //
        // If we won't do so, the following operation called on the same tick, *will not
        // result* in an update of the client-only field.
        //
        //   APP.collections.Tasks.update("SyGxoMgisZPZYteXE", {$set: {status: "123"}})
        //   APP.collections.Tasks.update("SyGxoMgisZPZYteXE", {$set: {CLIENT_ONLY_FIELD: "123"}})

        var hook_called = false; // The hook won't be called if the modification didn't result in
                                 // an actual change, in which case, we need to clear the hook after
                                 // the .update() call to avoid it from firing for an irrelevant
                                 // change

        var edited_key = undefined; // Will stay undefined if the hook won't be called.
        var edited_fields = undefined; // Will stay undefined if the hook won't be called.
        var afterSetDocFieldsHook = function (key, _edited_fields) {
          hook_called = true;

          edited_fields = _edited_fields;
          edited_key = key;
        }

        this._collection._docs.once("after-setDocFields", afterSetDocFieldsHook);

        ret_val = this._collection.update(
          selector, modifier, options, wrappedCallback);

        if (hook_called) {
          // The following resulted from CoffeeScript:
          //
          // if (corresponding_server_doc = Meteor.connection._serverDocuments?[this._name]?.get(edited_key)?.document)?
          //   Object.assign(corresponding_server_doc, edited_fields)

          var corresponding_server_doc, ref, ref1, ref2;

          if ((corresponding_server_doc = (ref = Meteor.connection._serverDocuments) != null ? (ref1 = ref[this._name]) != null ? (ref2 = ref1.get(edited_key)) != null ? ref2.document : void 0 : void 0 : void 0) != null) {
            Object.assign(corresponding_server_doc, edited_fields);
          }
        } else {
          this._collection._docs.off("after-setDocFields", afterSetDocFieldsHook);
        }

        return ret_val;
      }
    } catch (e) {
      if (callback) {
        callback(e);
        return null;
      }
      throw e;
    }
  },

  setDocFields(doc_id, fields) {
    // The following resulted from CoffeeScript:
    //
    // setDocFields = (doc_id, fields) ->
    //   if @_collection.requestSetDocFieldsDirectUpdate()
    //     @update(doc_id, {$set: fields})
        
    //     return

    //   if (corresponding_server_doc = Meteor.connection._serverDocuments?[@_name]?.get(doc_id)?.document)?
    //     Object.assign(corresponding_server_doc, fields)
    //   # The purpose of the above line is the same as the code under: 
    //   # justdo-shared-packages/mongo/collection.js look for CLIENT-SITE-EXEC-CLIENT-ONLY-FIELDS

    //   @_collection._docs.setDocFields(doc_id, fields)
      
    //   return

    var corresponding_server_doc, ref, ref1, ref2;
    if (this._collection.requestSetDocFieldsDirectUpdate()) {
      this.update(doc_id, {
        $set: fields
      });
      return;
    }
    if ((corresponding_server_doc = (ref = Meteor.connection._serverDocuments) != null ? (ref1 = ref[this._name]) != null ? (ref2 = ref1.get(doc_id)) != null ? ref2.document : void 0 : void 0 : void 0) != null) {
      Object.assign(corresponding_server_doc, fields);
    }
    // The purpose of the above line is the same as the code under: 
    // justdo-shared-packages/mongo/collection.js look for CLIENT-SITE-EXEC-CLIENT-ONLY-FIELDS
    this._collection._docs.setDocFields(doc_id, fields);
  },

  getDocNonReactive(doc_id) {
    return this._collection._docs._map[doc_id];
  },

  /**
   * @summary Remove documents from the collection
   * @locus Anywhere
   * @method remove
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} selector Specifies which documents to remove
   * @param {Function} [callback] Optional.  If present, called with an error object as its argument.
   */
  remove(selector, callback) {
    selector = Mongo.Collection._rewriteSelector(selector);

    const wrappedCallback = wrapCallback(callback);

    if (this._isRemoteCollection()) {
      return this._callMutatorMethod('remove', [selector], wrappedCallback);
    }

    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi('remove', this._name, this.remove.isCalledFromAsync);
    this.remove.isCalledFromAsync = false;
    // it's my collection.  descend into the collection object
    // and propagate any exception.
    try {
      // If the user provided a callback and the collection implements this
      // operation asynchronously, then queryRet will be undefined, and the
      // result will be returned through the callback instead.
      return this._collection.remove(selector, wrappedCallback);
    } catch (e) {
      if (callback) {
        callback(e);
        return null;
      }
      throw e;
    }
  },

  // Determine if this collection is simply a minimongo representation of a real
  // database on another server
  _isRemoteCollection() {
    // XXX see #MeteorServerNull
    return this._connection && this._connection !== Meteor.server;
  },

  /**
   * @summary Modify one or more documents in the collection, or insert one if no matching documents were found. Returns an object with keys `numberAffected` (the number of documents modified)  and `insertedId` (the unique _id of the document that was inserted, if any).
   * @locus Anywhere
   * @method upsert
   * @memberof Mongo.Collection
   * @instance
   * @param {MongoSelector} selector Specifies which documents to modify
   * @param {MongoModifier} modifier Specifies how to modify the documents
   * @param {Object} [options]
   * @param {Boolean} options.multi True to modify all matching documents; false to only modify one of the matching documents (the default).
   * @param {Function} [callback] Optional.  If present, called with an error object as the first argument and, if no error, the number of affected documents as the second.
   */
  upsert(selector, modifier, options, callback) {
    if (!callback && typeof options === 'function') {
      callback = options;
      options = {};
    }

    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi('upsert', this._name, this.upsert.isCalledFromAsync);
    this.upsert.isCalledFromAsync = false;
    // caught here https://github.com/meteor/meteor/issues/12626
    this.update.isCalledFromAsync = true; // to not trigger on the next call
    return this.update(
      selector,
      modifier,
      {
        ...options,
        _returnObject: true,
        upsert: true,
      },
      callback
    );
  },

  // We'll actually design an index API later. For now, we just pass through to
  // Mongo's, but make it synchronous.
  _ensureIndex(index, options) {
    var self = this;
    if (!self._collection._ensureIndex || !self._collection.createIndex)
      throw new Error('Can only call createIndex on server collections');
    if (self._collection.createIndex) {
      self._collection.createIndex(index, options);
    } else {
      import { Log } from 'meteor/logging';
      Log.debug(
        `_ensureIndex has been deprecated, please use the new 'createIndex' instead${
          options?.name
            ? `, index name: ${options.name}`
            : `, index: ${JSON.stringify(index)}`
        }`
      );
      self._collection._ensureIndex(index, options);
    }
  },

  /**
   * @summary Creates the specified index on the collection.
   * @locus server
   * @method createIndex
   * @memberof Mongo.Collection
   * @instance
   * @param {Object} index A document that contains the field and value pairs where the field is the index key and the value describes the type of index for that field. For an ascending index on a field, specify a value of `1`; for descending index, specify a value of `-1`. Use `text` for text indexes.
   * @param {Object} [options] All options are listed in [MongoDB documentation](https://docs.mongodb.com/manual/reference/method/db.collection.createIndex/#options)
   * @param {String} options.name Name of the index
   * @param {Boolean} options.unique Define that the index values must be unique, more at [MongoDB documentation](https://docs.mongodb.com/manual/core/index-unique/)
   * @param {Boolean} options.sparse Define that the index is sparse, more at [MongoDB documentation](https://docs.mongodb.com/manual/core/index-sparse/)
   */
  createIndex(index, options) {
    var self = this;
    if (!self._collection.createIndex)
      throw new Error('Can only call createIndex on server collections');
    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi(
      'createIndex',
      self._name,
      self.createIndex.isCalledFromAsync
    );
    self.createIndex.isCalledFromAsync = false;
    try {
      self._collection.createIndex(index, options);
    } catch (e) {
      if (
        e.message.includes(
          'An equivalent index already exists with the same name but different options.'
        ) &&
        Meteor.settings?.packages?.mongo?.reCreateIndexOnOptionMismatch
      ) {
        import { Log } from 'meteor/logging';

        Log.info(
          `Re-creating index ${index} for ${self._name} due to options mismatch.`
        );
        self._collection._dropIndex(index);
        self._collection.createIndex(index, options);
      } else {
        throw new Meteor.Error(
          `An error occurred when creating an index for collection "${self._name}: ${e.message}`
        );
      }
    }
  },

  _dropIndex(index) {
    var self = this;
    if (!self._collection._dropIndex)
      throw new Error('Can only call _dropIndex on server collections');
    self._collection._dropIndex(index);
  },

  _dropCollection() {
    var self = this;
    if (!self._collection.dropCollection)
      throw new Error('Can only call _dropCollection on server collections');
    self._collection.dropCollection();
  },

  _createCappedCollection(byteSize, maxDocuments) {
    var self = this;
    if (!self._collection._createCappedCollection)
      throw new Error(
        'Can only call _createCappedCollection on server collections'
      );

    // [FIBERS]
    // TODO: Remove this when 3.0 is released.
    warnUsingOldApi(
      '_createCappedCollection',
      self._name,
      self._createCappedCollection.isCalledFromAsync
    );
    self._createCappedCollection.isCalledFromAsync = false;
    self._collection._createCappedCollection(byteSize, maxDocuments);
  },

  /**
   * @summary Returns the [`Collection`](http://mongodb.github.io/node-mongodb-native/3.0/api/Collection.html) object corresponding to this collection from the [npm `mongodb` driver module](https://www.npmjs.com/package/mongodb) which is wrapped by `Mongo.Collection`.
   * @locus Server
   * @memberof Mongo.Collection
   * @instance
   */
  rawCollection() {
    var self = this;
    if (!self._collection.rawCollection) {
      throw new Error('Can only call rawCollection on server collections');
    }
    return self._collection.rawCollection();
  },

  /**
   * @summary Returns the [`Db`](http://mongodb.github.io/node-mongodb-native/3.0/api/Db.html) object corresponding to this collection's database connection from the [npm `mongodb` driver module](https://www.npmjs.com/package/mongodb) which is wrapped by `Mongo.Collection`.
   * @locus Server
   * @memberof Mongo.Collection
   * @instance
   */
  rawDatabase() {
    var self = this;
    if (!(self._driver.mongo && self._driver.mongo.db)) {
      throw new Error('Can only call rawDatabase on server collections');
    }
    return self._driver.mongo.db;
  },
});

// Convert the callback to not return a result if there is an error
function wrapCallback(callback, convertResult) {
  return (
    callback &&
    function(error, result) {
      if (error) {
        callback(error);
      } else if (typeof convertResult === 'function') {
        callback(error, convertResult(result));
      } else {
        callback(error, result);
      }
    }
  );
}

/**
 * @summary Create a Mongo-style `ObjectID`.  If you don't specify a `hexString`, the `ObjectID` will be generated randomly (not using MongoDB's ID construction rules).
 * @locus Anywhere
 * @class
 * @param {String} [hexString] Optional.  The 24-character hexadecimal contents of the ObjectID to create
 */
Mongo.ObjectID = MongoID.ObjectID;

/**
 * @summary To create a cursor, use find. To access the documents in a cursor, use forEach, map, or fetch.
 * @class
 * @instanceName cursor
 */
Mongo.Cursor = LocalCollection.Cursor;

/**
 * @deprecated in 0.9.1
 */
Mongo.Collection.Cursor = Mongo.Cursor;

/**
 * @deprecated in 0.9.1
 */
Mongo.Collection.ObjectID = Mongo.ObjectID;

/**
 * @deprecated in 0.9.1
 */
Meteor.Collection = Mongo.Collection;

// Allow deny stuff is now in the allow-deny package
Object.assign(Mongo.Collection.prototype, AllowDeny.CollectionPrototype);

function popCallbackFromArgs(args) {
  // Pull off any callback (or perhaps a 'callback' variable that was passed
  // in undefined, like how 'upsert' does it).
  if (
    args.length &&
    (args[args.length - 1] === undefined ||
      args[args.length - 1] instanceof Function)
  ) {
    return args.pop();
  }
}

ASYNC_COLLECTION_METHODS.forEach(methodName => {
  const methodNameAsync = getAsyncMethodName(methodName);
  Mongo.Collection.prototype[methodNameAsync] = function(...args) {
    try {
      // TODO: Fibers remove this when we remove fibers.
      this[methodName].isCalledFromAsync = true;
      return Promise.resolve(this[methodName](...args));
    } catch (error) {
      return Promise.reject(error);
    }
  };
});
