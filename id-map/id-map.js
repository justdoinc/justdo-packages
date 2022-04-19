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

  bulkSet(docs, options) {
    //
    // !IMPORTANT! We are editing the provided docs IN PLACE
    //

    // NOTE
    // The original forEach code was inefficient and replaced by JustDo to the following
    // coffeescript code:
    //
    // forEach = (iterator) ->
    //   for key, val of this._map
    //     if (iterator.call(null, val, this._idParse(key))) is false
    //       return
    //   return
    // /END NOTE

    // options:
    //
    // set_id_from_key: true/false ; (default true) if set to false, we don't assume docs has _id ; we'll add the _id based on the doc key in the docs object

    // NOT IMPLEMENTED YET:
    // NOT IMPLEMENTED YET: schema: [field_def1, field_def2, ...] # (default unset) if set, docs that will include _s: [val1, val2, ...]
    // NOT IMPLEMENTED YET:                                         will result in the addition of the fields according the schema definition
    // NOT IMPLEMENTED YET:                                         provided. the _s will be removed once modification is completed. If _s
    // NOT IMPLEMENTED YET:                                         can't be found in a doc, we simply skip it.
    // NOT IMPLEMENTED YET: field_def should be of the form: {
    // NOT IMPLEMENTED YET:   field_id: "field_id"
    // NOT IMPLEMENTED YET:   type: "date"/"auto"
    // NOT IMPLEMENTED YET: }
    
    // auto-generated see source code above
    // bulkSet = (docs, options) ->
    //   set_id_from_key = options?.set_id_from_key is true
    //   forced_column_value_in_force = _.isObject(options.forced_column_value) and not _.isEmpty(options.forced_column_value)
      
    //   if true in [set_id_from_key, forced_column_value_in_force]
    //     for doc_id, doc of docs
    //       if set_id_from_key
    //         docs[doc_id]._id = doc_id
          
    //       if forced_column_value_in_force
    //         for key, val of options.forced_column_value
    //           docs[doc_id][key] = val

    //   @emit("before-bulkSet", docs)

    //   Object.assign(@_map, docs)

    //   @emit("after-bulkSet", docs)

    //   return

    var doc, doc_id, forced_column_value_in_force, key, ref, set_id_from_key, val;
    set_id_from_key = (options != null ? options.set_id_from_key : void 0) === true;
    forced_column_value_in_force = _.isObject(options.forced_column_value) && !_.isEmpty(options.forced_column_value);
    if (true === set_id_from_key || true === forced_column_value_in_force) {
      for (doc_id in docs) {
        doc = docs[doc_id];
        if (set_id_from_key) {
          docs[doc_id]._id = doc_id;
        }
        if (forced_column_value_in_force) {
          ref = options.forced_column_value;
          for (key in ref) {
            val = ref[key];
            docs[doc_id][key] = val;
          }
        }
      }
    }
    this.emit("before-bulkSet", docs);
    Object.assign(this._map, docs);
    this.emit("after-bulkSet", docs);
  }

  remove(id) {
    var key = this._idStringify(id);

    if (key in this._map) {
      var removed_doc = this._map[key];

      this.emit("before-remove", key, removed_doc);

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
    // unsetDocFields = (id, fields) ->
    //   removed_fields = []

    //   for field in fields
    //     if field of this._map[key]
    //       removed_fields.push field

    //   if removed_fields.length == 0
    //     # Nothing changed
    //     return

    //   this.emit("before-unset-doc-fields", key, removed_fields)
      
    //   for field in removed_fields
    //     delete this._map[key][field]

    //   this.emit("after-unset-doc-fields", key, removed_fields)
      
    //   return

    var field, i, j, len, len1, removed_fields;

    removed_fields = [];

    for (i = 0, len = fields.length; i < len; i++) {
      field = fields[i];
      if (field in this._map[key]) {
        removed_fields.push(field);
      }
    }

    if (removed_fields.length === 0) {
      // Nothing changed
      return;
    }
    
    this.emit("before-unset-doc-fields", key, removed_fields);

    for (j = 0, len1 = removed_fields.length; j < len1; j++) {
      field = removed_fields[j];
      delete this._map[key][field];
    }

    this.emit("after-unset-doc-fields", key, removed_fields);
  }

  setDocFields(id, fields) {
    var key = this._idStringify(id);

    // COFFEE
    // setDocFields = (id, fields) ->
    //   previous_edited_fields_values = {}
      
    //   edited_fields = {}

    //   for field, val of fields
    //     if field != "_id" and (not EJSON.equals(val, this._map[key][field]))
    //       previous_edited_fields_values[field] = this._map[key][field]
    //       edited_fields[field] = val

    //   if Object.keys(edited_fields).length != 0
    //     this.emit("before-setDocFields", key, edited_fields, previous_edited_fields_values)
        
    //     Object.assign(this._map[key], edited_fields)

    //     this.emit("after-setDocFields", key, edited_fields, previous_edited_fields_values)

    //   return

    var edited_fields, field, previous_edited_fields_values, val;
    previous_edited_fields_values = {};
    edited_fields = {};
    for (field in fields) {
      val = fields[field];
      if (field !== "_id" && (!EJSON.equals(val, this._map[key][field]))) {
        previous_edited_fields_values[field] = this._map[key][field];
        edited_fields[field] = val;
      }
    }
    if (Object.keys(edited_fields).length !== 0) {
      this.emit("before-setDocFields", key, edited_fields, previous_edited_fields_values);
      Object.assign(this._map[key], edited_fields);
      this.emit("after-setDocFields", key, edited_fields, previous_edited_fields_values);
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
