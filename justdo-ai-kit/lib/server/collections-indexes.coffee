_.extend JustdoAiKit.prototype,
  _ensureIndexesExists: -> 
    @query_collection.createIndex {performed_by: 1, createdAt: -1} 
    @query_collection.createIndex {req_id: 1, performed_by: 1}
    return