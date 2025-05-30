import LocalCollection from './local_collection.js';
import {
  hasOwn,
  sameTickStatsInc,
  sameTickStatsSetVal,
  sameTickStatsPushToArray,
  sameTickStatsAddToDict,
  reportOptimizationIssue,
} from './common.js';
import { ASYNC_CURSOR_METHODS, getAsyncMethodName } from './constants';

// Cursor: a specification for a particular subset of documents, w/ a defined
// order, limit, and offset.  creating a Cursor with LocalCollection.find(),
export default class Cursor {
  // don't call this ctor directly.  use LocalCollection.find().
  constructor(collection, selector, options = {}) {
    this.collection = collection;
    this.sorter = null;
    this.matcher = new Minimongo.Matcher(selector);
    this.selector = EJSON.clone(selector);

    if (LocalCollection._selectorIsIdPerhapsAsObject(selector)) {
      // stash for fast _id and { _id }
      this._selectorId = hasOwn.call(selector, '_id') ? selector._id : selector;
    } else {
      this._selectorId = undefined;

      if (this.matcher.hasGeoQuery() || options.sort) {
        this.sorter = new Minimongo.Sorter(options.sort || []);
      }
    }

    this.skip = options.skip || 0;
    this.limit = options.limit;
    this.fields = options.projection || options.fields;

    this._projectionFn = LocalCollection._compileProjection(this.fields || {});

    this._transform = LocalCollection.wrapTransform(options.transform);

    // by default, queries register w/ Tracker when it is available.
    if (typeof Tracker !== 'undefined') {
      this.reactive = options.reactive === undefined ? true : options.reactive;
    }
  }

  /**
   * @deprecated in 2.9
   * @summary Returns the number of documents that match a query. This method is
   *          [deprecated since MongoDB 4.0](https://www.mongodb.com/docs/v4.4/reference/command/count/);
   *          see `Collection.countDocuments` and
   *          `Collection.estimatedDocumentCount` for a replacement.   * @memberOf Mongo.Cursor
   * @memberOf Mongo.Cursor
   * @method  count
   * @instance
   * @locus Anywhere
   * @returns {Number}
   */
  count() {
    if (this.reactive) {
      // allow the observe to be unordered
      this._depend({ added: true, removed: true }, true);
    }

    return this._getRawObjects({
      ordered: true,
    }).length;
  }

  /**
   * @summary Return all matching documents as an Array.
   * @memberOf Mongo.Cursor
   * @method  fetch
   * @instance
   * @locus Anywhere
   * @returns {Object[]}
   */
  fetch() {
    const result = [];

    this.forEach(doc => {
      result.push(doc);
    });

    return result;
  }

  [Symbol.iterator]() {
    if (this.reactive) {
      this._depend({
        addedBefore: true,
        removed: true,
        changed: true,
        movedBefore: true,
      });
    }

    let index = 0;
    const objects = this._getRawObjects({ ordered: true });

    return {
      next: () => {
        if (index < objects.length) {
          // This doubles as a clone operation.
          let element = this._projectionFn(objects[index++]);

          if (this._transform) element = this._transform(element);

          return { value: element };
        }

        return { done: true };
      },
    };
  }

  [Symbol.asyncIterator]() {
    const syncResult = this[Symbol.iterator]();
    return {
      async next() {
        return Promise.resolve(syncResult.next());
      },
    };
  }

  /**
   * @callback IterationCallback
   * @param {Object} doc
   * @param {Number} index
   */
  /**
   * @summary Call `callback` once for each matching document, sequentially and
   *          synchronously.
   * @locus Anywhere
   * @method  forEach
   * @instance
   * @memberOf Mongo.Cursor
   * @param {IterationCallback} callback Function to call. It will be called
   *                                     with three arguments: the document, a
   *                                     0-based index, and <em>cursor</em>
   *                                     itself.
   * @param {Any} [thisArg] An object which will be the value of `this` inside
   *                        `callback`.
   */
  forEach(callback, thisArg) {
    if (typeof this._selectorId !== "undefined") {
      // If find by id
      depend_options = {added: true, removed: true, changed: true};
      get_raw_objects_options = {ordered: false};
    } else {
      depend_options = {addedBefore: true, removed: true, changed: true, movedBefore: true};
      get_raw_objects_options = {ordered: true};
    }

    if (this.reactive) {
      this._depend(depend_options);
    }

    this._getRawObjects(get_raw_objects_options).forEach((element, i) => {
      // This doubles as a clone operation.
      element = this._projectionFn(element);

      if (this._transform) {
        element = this._transform(element);
      }

      callback.call(thisArg, element, i, this);
    });
  }

  getTransform() {
    return this._transform;
  }

  /**
   * @summary Map callback over all matching documents.  Returns an Array.
   * @locus Anywhere
   * @method map
   * @instance
   * @memberOf Mongo.Cursor
   * @param {IterationCallback} callback Function to call. It will be called
   *                                     with three arguments: the document, a
   *                                     0-based index, and <em>cursor</em>
   *                                     itself.
   * @param {Any} [thisArg] An object which will be the value of `this` inside
   *                        `callback`.
   */
  map(callback, thisArg) {
    const result = [];

    this.forEach((doc, i) => {
      result.push(callback.call(thisArg, doc, i, this));
    });

    return result;
  }

  // options to contain:
  //  * callbacks for observe():
  //    - addedAt (document, atIndex)
  //    - added (document)
  //    - changedAt (newDocument, oldDocument, atIndex)
  //    - changed (newDocument, oldDocument)
  //    - removedAt (document, atIndex)
  //    - removed (document)
  //    - movedTo (document, oldIndex, newIndex)
  //
  // attributes available on returned query handle:
  //  * stop(): end updates
  //  * collection: the collection this query is querying
  //
  // iff x is a returned query handle, (x instanceof
  // LocalCollection.ObserveHandle) is true
  //
  // initial results delivered through added callback
  // XXX maybe callbacks should take a list of objects, to expose transactions?
  // XXX maybe support field limiting (to limit what you're notified on)

  /**
   * @summary Watch a query.  Receive callbacks as the result set changes.
   * @locus Anywhere
   * @memberOf Mongo.Cursor
   * @instance
   * @param {Object} callbacks Functions to call to deliver the result set as it
   *                           changes
   */
  observe(options) {
    return LocalCollection._observeFromObserveChanges(this, options);
  }

  /**
   * @summary observe async version
   * @locus Anywhere
   * @memberOf Promise<Mongo.Cursor>
   * @instance
   */
  observeAsync(options) {
    return new Promise(resolve => resolve(this.observe(options)));
  }

  /**
   * @summary Watch a query. Receive callbacks as the result set changes. Only
   *          the differences between the old and new documents are passed to
   *          the callbacks.
   * @locus Anywhere
   * @memberOf Mongo.Cursor
   * @instance
   * @param {Object} callbacks Functions to call to deliver the result set as it
   *                           changes
   */
  observeChanges(options) {
    const ordered = LocalCollection._observeChangesCallbacksAreOrdered(options);

    // there are several places that assume you aren't combining skip/limit with
    // unordered observe.  eg, update's EJSON.clone, and the "there are several"
    // comment in _modifyAndNotify
    // XXX allow skip/limit with unordered observe
    if (!options._allow_unordered && !ordered && (this.skip || this.limit)) {
      throw new Error(
        "Must use an ordered observe with skip or limit (i.e. 'addedBefore' " +
          "for observeChanges or 'addedAt' for observe, instead of 'added')."
      );
    }

    if (this.fields && (this.fields._id === 0 || this.fields._id === false)) {
      throw Error('You may not observe a cursor with {fields: {_id: 0}}');
    }

    const distances =
      this.matcher.hasGeoQuery() && ordered && new LocalCollection._IdMap();

    const query = {
      cursor: this,
      dirty: false,
      distances,
      matcher: this.matcher, // not fast pathed
      ordered,
      projectionFn: this._projectionFn,
      resultsSnapshot: null,
      sorter: ordered && this.sorter,
      trace: (new Error()).stack
    };

    let qid;

    let col_name = this.colNameForStats();

    // Non-reactive queries call added[Before] and then never call anything
    // else.
    if (this.reactive) {
      qid = this.collection.next_qid++;
      this.collection.queries[qid] = query;

      this.collection.queries_count += 1;

      sameTickStatsAddToDict("minimongo-reactive-observer-registered-queries::collection:" + col_name, qid - 1, {selector: query.matcher._selector, query: query, fields: this.fields, ordered: ordered, _suppress_initial: options._suppress_initial});

      sameTickStatsInc("minimongo-reactive-observer-registered", 1);
      sameTickStatsInc("minimongo-reactive-observer-registered::collection:" + col_name + ":ordered:" + (ordered ? "1" : "0"), 1);

      sameTickStatsSetVal("minimongo-reactive-observer-total-running::collection:" + col_name, this.collection.queries_count);
    }

    query.results = this._getRawObjects({
      ordered,
      distances: query.distances,
    });

    if (this.collection.paused) {
      query.resultsSnapshot = ordered ? [] : new LocalCollection._IdMap();
    }

    // wrap callbacks we were passed. callbacks only fire when not paused and
    // are never undefined
    // Filters out blacklisted fields according to cursor's projection.
    // XXX wrong place for this?

    // furthermore, callbacks enqueue until the operation we're working on is
    // done.
    const wrapCallback = fn => {
      if (!fn) {
        return () => {};
      }

      const self = this;
      return function(/* args*/) {
        if (self.collection.paused) {
          return;
        }

        const args = arguments;

        self.collection._observeQueue.queueTask(() => {
          fn.apply(this, args);
        });
      };
    };

    query.added = wrapCallback(options.added);
    query.changed = wrapCallback(options.changed);
    query.removed = wrapCallback(options.removed);

    if (ordered) {
      query.addedBefore = wrapCallback(options.addedBefore);
      query.movedBefore = wrapCallback(options.movedBefore);
    }

    if (!options._suppress_initial && !this.collection.paused) {
      query.results.forEach(doc => {
        const fields = EJSON.clone(doc);

        delete fields._id;

        if (ordered) {
          query.addedBefore(doc._id, this._projectionFn(fields), null);
        }

        query.added(doc._id, this._projectionFn(fields));
      });
    }

    const handle = Object.assign(new LocalCollection.ObserveHandle(), {
      collection: this.collection,
      stop: () => {
        if (this.reactive) {
          delete this.collection.queries[qid];

          this.collection.queries_count -= 1;
          sameTickStatsSetVal("minimongo-reactive-observer-total-running::collection:" + col_name, this.collection.queries_count);

          sameTickStatsInc("minimongo-reactive-observer-deregistered", 1);
          sameTickStatsInc("minimongo-reactive-observer-deregistered::collection:" + col_name + ":ordered:" + (ordered ? "1" : "0"), 1);
        }
      },
    });

    if (this.reactive && Tracker.active) {
      // XXX in many cases, the same observe will be recreated when
      // the current autorun is rerun.  we could save work by
      // letting it linger across rerun and potentially get
      // repurposed if the same observe is performed, using logic
      // similar to that of Meteor.subscribe.
      Tracker.onInvalidate(() => {
        handle.stop();
      });
    }

    // run the observe callbacks resulting from the initial contents
    // before we leave the observe.
    this.collection._observeQueue.drain();

    return handle;
  }

  /**
   * @summary observeChanges async version
   * @locus Anywhere
   * @memberOf Promise<Mongo.Cursor>
   * @instance
   */
  observeChangesAsync(options) {
    return new Promise(resolve => resolve(this.observeChanges(options)));
  }

  // XXX Maybe we need a version of observe that just calls a callback if
  // anything changed.
  _depend(changers, _allow_unordered) {
    if (Tracker.active) {
      const dependency = new Tracker.Dependency();
      const notify = dependency.changed.bind(dependency);

      dependency.depend();

      const options = { _allow_unordered, _suppress_initial: true };

      ['added', 'addedBefore', 'changed', 'movedBefore', 'removed'].forEach(
        fn => {
          if (changers[fn]) {
            options[fn] = notify;
          }
        }
      );

      // observeChanges will stop() when this computation is invalidated
      this.observeChanges(options);
    }
  }

  _getCollectionName() {
    return this.collection.name;
  }

  colNameForStats() {
    let col_name = "unknown-collection";
    if (typeof this.collection.name !== "undefined") {
      col_name = this.collection.name;
    }

    return col_name;
  }

  // Returns a collection of matching objects, but doesn't deep copy them.
  //
  // If ordered is set, returns a sorted array, respecting sorter, skip, and
  // limit properties of the query provided that options.applySkipLimit is
  // not set to false (#1201). If sorter is falsey, no sort -- you get the
  // natural order.
  //
  // If ordered is not set, returns an object mapping from ID to doc (sorter,
  // skip and limit should not be set).
  //
  // If ordered is set and this cursor is a $near geoquery, then this function
  // will use an _IdMap to track each distance from the $near argument point in
  // order to use it as a sort key. If an _IdMap is passed in the 'distances'
  // argument, this function will clear it and use it for this purpose
  // (otherwise it will just create its own _IdMap). The observeChanges
  // implementation uses this to remember the distances after this function
  // returns.
  _getRawObjects(options = {}) {
    // By default this method will respect skip and limit because .fetch(),
    // .forEach() etc... expect this behaviour. It can be forced to ignore
    // skip and limit by setting applySkipLimit to false (.count() does this,
    // for example)
    const applySkipLimit = options.applySkipLimit !== false;

    let col_name = this.colNameForStats();

    // XXX use OrderedDict instead of array, and make IdMap and OrderedDict
    // compatible
    const results = options.ordered ? [] : new LocalCollection._IdMap();

    // fast path for single ID value
    if (this._selectorId !== undefined) {
      // If you have non-zero skip and ask for a single id, you get nothing.
      // This is so it matches the behavior of the '{_id: foo}' path.
      if (applySkipLimit && this.skip) {
        return results;
      }

      const selectedDoc = this.collection._docs.get(this._selectorId);

      if (selectedDoc) {
        if (options.ordered) {
          results.push(selectedDoc);
        } else {
          results.set(this._selectorId, selectedDoc);
        }
      }

      sameTickStatsInc("minimongo-find-by-id-total-scanned-docs", 1);
      sameTickStatsInc("minimongo-find-by-id-total-scanned-docs::collection:" + col_name, 1);

      return results;
    }

    // slow path for arbitrary selector, sort, skip, limit

    // in the observeChanges case, distances is actually part of the "query"
    // (ie, live results set) object.  in other cases, distances is only used
    // inside this function.
    let distances;
    if (this.matcher.hasGeoQuery() && options.ordered) {
      if (options.distances) {
        distances = options.distances;
        distances.clear();
      } else {
        distances = new LocalCollection._IdMap();
      }
    }

    let total_scanned_docs = 0;
    let docs_scan_start = new Date();

    let iterator = (doc, id) => {
      total_scanned_docs += 1;

      const matchResult = this.matcher.documentMatches(doc);

      if (matchResult.result) {
        if (options.ordered) {
          results.push(doc);

          if (distances && matchResult.distance !== undefined) {
            distances.set(id, matchResult.distance);
          }
        } else {
          results.set(id, doc);
        }
      }

      // Override to ensure all docs are matched if ignoring skip & limit
      if (!applySkipLimit) {
        return true;
      }

      // Fast path for limited unsorted queries.
      // XXX 'length' check here seems wrong for ordered
      return (
        !this.limit || this.skip || this.sorter || results.length !== this.limit
      );
    };

    this.collection._eachPossiblyMatchingDoc(this.selector, iterator);
    // this.collection._docs.forEach(iterator); # Original code

    let scan_time = (new Date()) - docs_scan_start;

    sameTickStatsInc("minimongo-find-not-by-id-total-time-ms", scan_time);
    sameTickStatsInc("minimongo-find-not-by-id-total-time-ms::collection:" + col_name, scan_time);
    sameTickStatsInc("minimongo-find-not-by-id-total-scanned-docs", total_scanned_docs);
    sameTickStatsInc("minimongo-find-not-by-id-total-scanned-docs::collection:" + col_name, total_scanned_docs);

    if (!options.ordered) {
      return results;
    }

    let sort_time_start = new Date();
    if (this.sorter) {
      results.sort(this.sorter.getComparator({ distances }));
    }
    let sort_time = (new Date()) - sort_time_start;
    sameTickStatsInc("minimongo-find-not-by-id-total-sort-time", sort_time);
    sameTickStatsInc("minimongo-find-not-by-id-total-sort-time::collection:" + col_name, sort_time);

    // Return the full set of results if there is no skip or limit or if we're
    // ignoring them
    if (!applySkipLimit || (!this.limit && !this.skip)) {
      return results;
    }

    return results.slice(
      this.skip,
      this.limit ? this.limit + this.skip : results.length
    );
  }

  _publishCursor(subscription) {
    // XXX minimongo should not depend on mongo-livedata!
    if (!Package.mongo) {
      throw new Error(
        "Can't publish from Minimongo without the `mongo` package."
      );
    }

    if (!this.collection.name) {
      throw new Error(
        "Can't publish a cursor from a collection without a name."
      );
    }

    return Package.mongo.Mongo.Collection._publishCursor(
      this,
      subscription,
      this.collection.name
    );
  }
}

// Implements async version of cursor methods to keep collections isomorphic
ASYNC_CURSOR_METHODS.forEach(method => {
  const asyncName = getAsyncMethodName(method);
  Cursor.prototype[asyncName] = function(...args) {
    try {
      this[method].isCalledFromAsync = true;
      return Promise.resolve(this[method].apply(this, args));
    } catch (error) {
      return Promise.reject(error);
    }
  };
});