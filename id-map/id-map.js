const hasOwn = Object.prototype.hasOwnProperty;

export class IdMap extends EventEmitter {
  constructor(idStringify, idParse) {
    super();
    this.clear();
    this._idStringify = idStringify || JSON.stringify;
    this._idParse = idParse || JSON.parse;
  }

// Some of these methods are designed to match methods on OrderedDict, since
// (eg) ObserveMultiplex and _CachingChangeObserver use them interchangeably.
// (Conceivably, this should be replaced with "UnorderedDict" with a specific
// set of methods that overlap between the two.)

  get(id) {
    var key = this._idStringify(id);
    return this._map[key];
  }

  set(id, value) {
    var key = this._idStringify(id);
    this._map[key] = value;

    this.emit("after-set", key, value);
  }

  bulkSet(docs) {
    Object.assign(this._map, docs);

    this.emit("after-bulkSet", docs);
  }

  remove(id) {
    var key = this._idStringify(id);

    if (key in this._map) {
      var removed_doc = this._map[key];

      delete this._map[key];

      this.emit("after-remove", key, removed_doc);
    }
  }

  has(id) {
    var key = this._idStringify(id);
    return hasOwn.call(this._map, key);
  }

  empty() {
    for (let key in this._map) {
      return false;
    }
    return true;
  }

  clear() {
    this._map = Object.create(null);
  }

  // Iterates over the items in the map. Return `false` to break the loop.
  forEach(iterator) {
    // The original forEach code was inefficient and replaced by JustDo to the following
    // coffeescript code:
    //
    // forEach = (iterator) ->
    //   for key, val of this._map
    //     if (iterator.call(null, val, this._idParse(key))) is false
    //       return

    //   return
    
    // auto-generated see source code above
    var key, ref, val;
    ref = this._map;
    for (key in ref) {
      val = ref[key];
      if ((iterator.call(null, val, this._idParse(key))) === false) {
        return;
      }
    }
  }

  size() {
    return Object.keys(this._map).length;
  }

  setDefault(id, def) {
    var key = this._idStringify(id);
    if (hasOwn.call(this._map, key)) {
      return this._map[key];
    }
    this._map[key] = def;
    return def;
  }

  unsetDocFields(id, fields) {
    var key = this._idStringify(id);

    if (!(key in this._map)) {
      // Do nothing, unknown key
      return;
    }

    // COFFEE
    // removed_fields = []

    // for field in fields
    //   if field of this._map[key]
    //     removed_fields.push field
    //     delete this._map[key][field]
        
    // if removed_fields.length > 0
    //   this.emit("after-unset-doc-fields", key, removed_fields)

    var field, i, len, removed_fields;

    removed_fields = [];

    for (i = 0, len = fields.length; i < len; i++) {
      field = fields[i];
      if (field in this._map[key]) {
        removed_fields.push(field);
        delete this._map[key][field];
      }
    }

    if (removed_fields.length > 0) {
      this.emit("after-unsetDocFields", key, removed_fields);
    }
  }

  setDocFields(id, fields) {
    var key = this._idStringify(id);

    // COFFEE
    // edited_fields = {}
    //
    // for field, val of fields
    //   if field != "_id" and (not EJSON.equals(val, this._map[key][field]))
    //     edited_fields[field] = val
    //
    // if Object.keys(edited_fields).length != 0
    //   Object.assign(this._map[key], edited_fields)
    //
    //   this.emit("after-set-doc-fields", key, edited_fields)

    var edited_fields, field, val;

    edited_fields = {};

    for (field in fields) {
      val = fields[field];
      if (field !== "_id" && (!EJSON.equals(val, this._map[key][field]))) {
        edited_fields[field] = val;
      }
    }

    if (Object.keys(edited_fields).length !== 0) {
      Object.assign(this._map[key], edited_fields);
      this.emit("after-setDocFields", key, edited_fields);
    }
  }

  // Assumes that values are EJSON-cloneable, and that we don't need to clone
  // IDs (ie, that nobody is going to mutate an ObjectId).
  clone() {
    var clone = new IdMap(this._idStringify, this._idParse);
    this.forEach(function (value, id) {
      clone.set(id, EJSON.clone(value));
    });
    return clone;
  }
}
