_.extend(JustdoTasksCollectionsManager.prototype, {
  _initTasksCollection: function () {
    return new TasksCollectionConstructor("tasks");
  }
});

//
// WHAT YOU SEE BELOW IS:
//
// Mongo.Collection (in reality we are extending collection hook's extension)
// extended with few replacements to its prototype with a *slightly* modified
// methods.
//
// What we try to achieve below is to be able to perform operations before
// allow/deny ops gets executed on the server side, including manipulating
// the arguments passed (see the server's api @applyPrivateDataWritesProxies()
// to understand the motivation).
//
// The base for all the methods below was taken from meteor/packages/allow-deny/allow-deny.js
// version: 5533aa7ce86f8cbeb8e770ebeb9fb5909b399b1f
// The places where anything got changed by is marked with // JUSTDO DEVIATION BEGIN/END
//

const hasOwn = Object.prototype.hasOwnProperty;

// Only allow these operations in validated updates. Specifically
// whitelist operations, rather than blacklist, so new complex
// operations that are added aren't automatically allowed. A complex
// operation is one that does more than just modify its target
// field. For now this contains all update operations except '$rename'.
// http://docs.mongodb.org/manual/reference/operators/#update
const ALLOWED_UPDATE_OPERATIONS = {
  $inc:1, $set:1, $unset:1, $addToSet:1, $pop:1, $pullAll:1, $pull:1,
  $pushAll:1, $push:1, $bit:1, $currentDate: 1
};

TasksCollectionConstructor = function () {
  Mongo.Collection.apply(this, arguments);

  return this;
};

TasksCollectionConstructor.ALLOWED_UPDATE_OPERATIONS = ALLOWED_UPDATE_OPERATIONS

Util.inherits(TasksCollectionConstructor, Mongo.Collection);

_.extend(TasksCollectionConstructor.prototype, {

  // JUSTDO DEVIATION BEGIN
  beforeAllowDenyInsert: function (doc) {},

  beforeAllowDenyUpdate: function (userId, selector, mutator, options, doc) {},

  beforeAllowDenyRemove: function (selector) {},
  // JUSTDO DEVIATION END

  _validatedInsert: function (userId, doc,
                                generatedId) {
    const self = this;

    // call user validators.
    // Any deny returns true means denied.
    if (self._validators.insert.deny.some((validator) => {
      return validator(userId, docToValidate(validator, doc, generatedId));
    })) {
      throw new Meteor.Error(403, "Access denied");
    }
    // Any allow returns true means proceed. Throw error if they all fail.
    if (self._validators.insert.allow.every((validator) => {
      return !validator(userId, docToValidate(validator, doc, generatedId));
    })) {
      throw new Meteor.Error(403, "Access denied");
    }

    // If we generated an ID above, insert it now: after the validation, but
    // before actually inserting.
    if (generatedId !== null)
      doc._id = generatedId;

    // JUSTDO DEVIATION BEGIN
    self.beforeAllowDenyInsert(doc)
    // JUSTDO DEVIATION END

    self._collection.insert.call(self._collection, doc);
  },

  // Simulate a mongo `update` operation while validating that the access
  // control rules set by calls to `allow/deny` are satisfied. If all
  // pass, rewrite the mongo operation to use $in to set the list of
  // document ids to change ##ValidatedChange
  _validatedUpdate: function(
      userId, selector, mutator, options) {
    const self = this;

    check(mutator, Object);

    options = Object.assign(Object.create(null), options);

    if (!LocalCollection._selectorIsIdPerhapsAsObject(selector))
      throw new Error("validated update should be of a single ID");

    // We don't support upserts because they don't fit nicely into allow/deny
    // rules.
    if (options.upsert)
      throw new Meteor.Error(403, "Access denied. Upserts not " +
                             "allowed in a restricted collection.");

    const noReplaceError = "Access denied. In a restricted collection you can only" +
          " update documents, not replace them. Use a Mongo update operator, such " +
          "as '$set'.";

    const mutatorKeys = Object.keys(mutator);

    // compute modified fields
    const modifiedFields = {};

    if (mutatorKeys.length === 0) {
      throw new Meteor.Error(403, noReplaceError);
    }
    mutatorKeys.forEach((op) => {
      const params = mutator[op];
      if (op.charAt(0) !== '$') {
        throw new Meteor.Error(403, noReplaceError);
      } else if (!hasOwn.call(ALLOWED_UPDATE_OPERATIONS, op)) {
        throw new Meteor.Error(
          403, "Access denied. Operator " + op + " not allowed in a restricted collection.");
      } else {
        Object.keys(params).forEach((field) => {
          // treat dotted fields as if they are replacing their
          // top-level part
          if (field.indexOf('.') !== -1)
            field = field.substring(0, field.indexOf('.'));

          // record the field we are trying to change
          modifiedFields[field] = true;
        });
      }
    });

    const fields = Object.keys(modifiedFields);

    const findOptions = {transform: null};
    if (!self._validators.fetchAllFields) {
      findOptions.fields = {};
      self._validators.fetch.forEach((fieldName) => {
        findOptions.fields[fieldName] = 1;
      });
    }

    const doc = self._collection.findOne(selector, findOptions);
    if (!doc)  // none satisfied!
      return 0;

    // call user validators.
    // Any deny returns true means denied.
    if (self._validators.update.deny.some((validator) => {
      const factoriedDoc = transformDoc(validator, doc);
      return validator(userId,
                       factoriedDoc,
                       fields,
                       mutator);
    })) {
      throw new Meteor.Error(403, "Access denied");
    }
    // Any allow returns true means proceed. Throw error if they all fail.
    if (self._validators.update.allow.every((validator) => {
      const factoriedDoc = transformDoc(validator, doc);
      return !validator(userId,
                        factoriedDoc,
                        fields,
                        mutator);
    })) {
      throw new Meteor.Error(403, "Access denied");
    }

    options._forbidReplace = true;

    // Back when we supported arbitrary client-provided selectors, we actually
    // rewrote the selector to include an _id clause before passing to Mongo to
    // avoid races, but since selector is guaranteed to already just be an ID, we
    // don't have to any more.

    // JUSTDO DEVIATION BEGIN
    if (!self.beforeAllowDenyUpdate(userId, selector, mutator, options, doc)) {
      // if beforeAllowDenyUpdate returned false, it means we shouldn't proceed with
      // the updates
      return 0;
    }
    // JUSTDO DEVIATION END

    return self._collection.update.call(
      self._collection, selector, mutator, options);
  },

  // Simulate a mongo `remove` operation while validating access control
  // rules. See #ValidatedChange
  _validatedRemove: function(userId, selector) {
    const self = this;

    const findOptions = {transform: null};
    if (!self._validators.fetchAllFields) {
      findOptions.fields = {};
      self._validators.fetch.forEach((fieldName) => {
        findOptions.fields[fieldName] = 1;
      });
    }

    const doc = self._collection.findOne(selector, findOptions);
    if (!doc)
      return 0;

    // call user validators.
    // Any deny returns true means denied.
    if (self._validators.remove.deny.some((validator) => {
      return validator(userId, transformDoc(validator, doc));
    })) {
      throw new Meteor.Error(403, "Access denied");
    }
    // Any allow returns true means proceed. Throw error if they all fail.
    if (self._validators.remove.allow.every((validator) => {
      return !validator(userId, transformDoc(validator, doc));
    })) {
      throw new Meteor.Error(403, "Access denied");
    }

    // Back when we supported arbitrary client-provided selectors, we actually
    // rewrote the selector to {_id: {$in: [ids that we found]}} before passing to
    // Mongo to avoid races, but since selector is guaranteed to already just be
    // an ID, we don't have to any more.

    // JUSTDO DEVIATION BEGIN
    self.beforeAllowDenyRemove(selector)
    // JUSTDO DEVIATION END

    return self._collection.remove.call(self._collection, selector);
  },

  _defineMutationMethods: function(options) {
    const self = this;
    options = options || {};

    // set to true once we call any allow or deny methods. If true, use
    // allow/deny semantics. If false, use insecure mode semantics.
    self._restricted = false;

    // Insecure mode (default to allowing writes). Defaults to 'undefined' which
    // means insecure iff the insecure package is loaded. This property can be
    // overriden by tests or packages wishing to change insecure mode behavior of
    // their collections.
    self._insecure = undefined;

    self._validators = {
      insert: {allow: [], deny: []},
      update: {allow: [], deny: []},
      remove: {allow: [], deny: []},
      upsert: {allow: [], deny: []}, // dummy arrays; can't set these!
      fetch: [],
      fetchAllFields: false
    };

    if (!self._name)
      return; // anonymous collection

    // XXX Think about method namespacing. Maybe methods should be
    // "Meteor:Mongo:insert/NAME"?
    self._prefix = '/' + self._name + '/';

    // Mutation Methods
    // Minimongo on the server gets no stubs; instead, by default
    // it wait()s until its result is ready, yielding.
    // This matches the behavior of macromongo on the server better.
    // XXX see #MeteorServerNull
    if (self._connection && (self._connection === Meteor.server || Meteor.isClient)) {
      const m = {};

      ['insert', 'update', 'remove'].forEach((method) => {
        const methodName = self._prefix + method;

        if (options.useExisting) {
          const handlerPropName = Meteor.isClient ? '_methodHandlers' : 'method_handlers';
          // Do not try to create additional methods if this has already been called.
          // (Otherwise the .methods() call below will throw an error.)
          if (self._connection[handlerPropName] &&
            typeof self._connection[handlerPropName][methodName] === 'function') return;
        }

        m[methodName] = function (/* ... */) {
          // All the methods do their own validation, instead of using check().
          check(arguments, [Match.Any]);
          const args = Array.from(arguments);
          try {
            // For an insert, if the client didn't specify an _id, generate one
            // now; because this uses DDP.randomStream, it will be consistent with
            // what the client generated. We generate it now rather than later so
            // that if (eg) an allow/deny rule does an insert to the same
            // collection (not that it really should), the generated _id will
            // still be the first use of the stream and will be consistent.
            //
            // However, we don't actually stick the _id onto the document yet,
            // because we want allow/deny rules to be able to differentiate
            // between arbitrary client-specified _id fields and merely
            // client-controlled-via-randomSeed fields.
            let generatedId = null;
            if (method === "insert" && !hasOwn.call(args[0], '_id')) {
              generatedId = self._makeNewID();
            }

            if (this.isSimulation) {
              // In a client simulation, you can do any mutation (even with a
              // complex selector).
              if (generatedId !== null)
                args[0]._id = generatedId;
              return self._collection[method].apply(
                self._collection, args);
            }

            // This is the server receiving a method call from the client.

            // We don't allow arbitrary selectors in mutations from the client: only
            // single-ID selectors.
            if (method !== 'insert')
              throwIfSelectorIsNotId(args[0], method);

            if (self._restricted) {
              // short circuit if there is no way it will pass.
              if (self._validators[method].allow.length === 0) {
                throw new Meteor.Error(
                  403, "Access denied. No allow validators set on restricted " +
                    "collection for method '" + method + "'.");
              }

              const validatedMethodName =
                    '_validated' + method.charAt(0).toUpperCase() + method.slice(1);
              args.unshift(this.userId);
              method === 'insert' && args.push(generatedId);
              return self[validatedMethodName].apply(self, args);
            } else if (self._isInsecure()) {
              if (generatedId !== null)
                args[0]._id = generatedId;
              // In insecure mode, allow any mutation (with a simple selector).
              // XXX This is kind of bogus.  Instead of blindly passing whatever
              //     we get from the network to this function, we should actually
              //     know the correct arguments for the function and pass just
              //     them.  For example, if you have an extraneous extra null
              //     argument and this is Mongo on the server, the .wrapAsync'd
              //     functions like update will get confused and pass the
              //     "fut.resolver()" in the wrong slot, where _update will never
              //     invoke it. Bam, broken DDP connection.  Probably should just
              //     take this whole method and write it three times, invoking
              //     helpers for the common code.
              return self._collection[method].apply(self._collection, args);
            } else {
              // In secure mode, if we haven't called allow or deny, then nothing
              // is permitted.
              throw new Meteor.Error(403, "Access denied");
            }
          } catch (e) {
            if (e.name === 'MongoError' || e.name === 'MinimongoError') {
              throw new Meteor.Error(409, e.toString());
            } else {
              throw e;
            }
          }
        };
      });

      self._connection.methods(m);
    }
  }
});

function transformDoc(validator, doc) {
  if (validator.transform)
    return validator.transform(doc);
  return doc;
}

function docToValidate(validator, doc, generatedId) {
  let ret = doc;
  if (validator.transform) {
    ret = EJSON.clone(doc);
    // If you set a server-side transform on your collection, then you don't get
    // to tell the difference between "client specified the ID" and "server
    // generated the ID", because transforms expect to get _id.  If you want to
    // do that check, you can do it with a specific
    // `C.allow({insert: f, transform: null})` validator.
    if (generatedId !== null) {
      ret._id = generatedId;
    }
    ret = validator.transform(ret);
  }
  return ret;
}

function addValidator(collection, allowOrDeny, options) {
  // validate keys
  const validKeysRegEx = /^(?:insert|update|remove|fetch|transform)$/;
  Object.keys(options).forEach((key) => {
    if (!validKeysRegEx.test(key))
      throw new Error(allowOrDeny + ": Invalid key: " + key);
  });

  collection._restricted = true;

  ['insert', 'update', 'remove'].forEach((name) => {
    if (hasOwn.call(options, name)) {
      if (!(options[name] instanceof Function)) {
        throw new Error(allowOrDeny + ": Value for `" + name + "` must be a function");
      }

      // If the transform is specified at all (including as 'null') in this
      // call, then take that; otherwise, take the transform from the
      // collection.
      if (options.transform === undefined) {
        options[name].transform = collection._transform;  // already wrapped
      } else {
        options[name].transform = LocalCollection.wrapTransform(
          options.transform);
      }

      collection._validators[name][allowOrDeny].push(options[name]);
    }
  });

  // Only update the fetch fields if we're passed things that affect
  // fetching. This way allow({}) and allow({insert: f}) don't result in
  // setting fetchAllFields
  if (options.update || options.remove || options.fetch) {
    if (options.fetch && !(options.fetch instanceof Array)) {
      throw new Error(allowOrDeny + ": Value for `fetch` must be an array");
    }
    collection._updateFetch(options.fetch);
  }
}

function throwIfSelectorIsNotId(selector, methodName) {
  if (!LocalCollection._selectorIsIdPerhapsAsObject(selector)) {
    throw new Meteor.Error(
      403, "Not permitted. Untrusted code may only " + methodName +
        " documents by ID.");
  }
};

// Determine if we are in a DDP method simulation
function alreadyInSimulation() {
  var CurrentInvocation =
    DDP._CurrentMethodInvocation ||
    // For backwards compatibility, as explained in this issue:
    // https://github.com/meteor/meteor/issues/8947
    DDP._CurrentInvocation;

  const enclosing = CurrentInvocation.get();
  return enclosing && enclosing.isSimulation;
}
