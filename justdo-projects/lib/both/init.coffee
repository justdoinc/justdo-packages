Projects = (options) ->
  EventEmitter.call this

  JustdoHelpers.setupHandlersRegistry(@)

  @main_logger_name = "Projects"
  @logger = Logger.get @main_logger_name

  @projects_collection = options.projects_collection
  @items_collection = options.items_collection
  @items_private_data_collection = options.items_private_data_collection

  if Meteor.isServer
    @removed_projects_archive_collection = options.removed_projects_archive_collection
    @removed_projects_items_archive_collection = options.removed_projects_items_archive_collection # Stores only items that were removed during project removal - not all removed items
    @removed_projects_items_private_data_archive_collection = options.removed_projects_items_private_data_archive_collection

  # Note - @hash_requests_handler can be undefined, don't assume existence!
  @hash_requests_handler = options.hash_requests_handler 

  @options = options

  # Implemented in /lib/both/schema.coffee
  @_attachSchema()

  @_grid_data_com = new GridDataCom @items_collection, @items_private_data_collection
  GridControlCustomFields.enableJustdoCustomFieldsForJustdoProject(@)

  @custom_compound_bulk_update = {}

  # To avoid security risk, we are whitelisting the allowed bulkUpdates
  @allowed_bulk_update_modifiers = [
    {
      $pull:
        users:
          $in: [String]
    }
    {
      $push: # Kept for legacy code in mobiles. It is converted to addToSet later
        users:
          $each: [String]
    }
    {
      $addToSet:
        users:
          $each: [String]
    }
    {
      $set:
        owner_id: String
        pending_owner_id: null
    }
    {
      $set:
        pending_owner_id: null
    }
  ]

  # env (server/client) specific init
  @_init()

  @_initModules()

  return @

Util.inherits Projects, EventEmitter

_.extend Projects.prototype,
  setJustdoAccountsObject: (justdo_accounts) ->
    @justdo_accounts = justdo_accounts

    return

  _initModules: ->
    @modules = {}

    for module_name, module_def of PACK.modules
      # We want each module_obj `this` keyword to be a prototypical
      # inheritence of the main projects obj with minor modifications
      module_obj = Object.create(@)
      module_obj.logger = Logger.get "#{@main_logger_name}::#{module_name}"

      _.extend module_obj, module_def

      @modules[module_name] = module_obj

      if module_obj.initBoth?
        module_obj.initBoth.call(module_obj)

      if Meteor.isServer and module_obj.initServer?
        module_obj.initServer.call(module_obj)

      if Meteor.isClient and module_obj.initClient?
        module_obj.initClient.call(module_obj)

  _error: JustdoHelpers.constructor_error