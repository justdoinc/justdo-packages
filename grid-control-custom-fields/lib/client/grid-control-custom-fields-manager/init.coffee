# Note, in order to use the custom fields feature it must be enabled first, refer to the README.md

default_options = {}

options_schema =
  client:
    custom_fields_definitions:
      # The custom fields definitions we'll initiate the GridControlCustomFieldManager
      # instance with
      #
      # Can be either a custom_fields_definitions object of the form:
      #
      # {
      #   field_id: GridControlCustomFields.custom_field_definition_schema compliant object in which the field_id
      #             is same as the property field_id
      # }
      #
      # Or a ReactiveVar that returns a custom_fields_definitions object of the mentioned form.
      #
      # If a ReactiveVar will be provided, we won't validate its value, in the options_schema level.
      #
      # 
      type: "skip-type-check"
      optional: true
      defaultValue: null
      custom: ->
        if @value instanceof ReactiveVar
          # We don't validate custom_fields_definitions provided as reactive vars in the schema level.

          return

        if typeof @value != "object"
          error_msg = "grid-control-custom-fields-manager: custom_fields_definitions should be either a ReactiveVar or an Object"

          console.error error_msg

          return error_msg

        for field_id, field_definition of @value
          if field_id != field_definition.field_id
            error_msg = "grid-control-custom-fields-manager: custom_fields_definitions keys must be equal to the field_id property"

            console.error error_msg

            return error_msg

          try
            # We use clean and validate only so it'll throw on error
            JustdoHelpers.simpleSchemaCleanAndValidate(
              GridControlCustomFields.custom_field_definition_schema,
              field_definition,
              {throw_on_error: true}
            )
          catch
            error_msg = "grid-control-custom-fields-manager: custom_fields_definitions option, field '#{field_id}' definition is invalid"

            console.error error_msg

            return error_msg

        return
    custom_states_definitions:
      type: "skip-type-check"
      
      optional: true

# options_schema
# ==============
#
# If options_schema is an object, we use it to clean and validate
# the contructor options. (otherwise ignored completly).
#
# *Notes:*
#
# * by using options_schema you must define any option that
#   the constructor can receive, options that won't be defined will be
#   omitted from the @options object.
#
# * default_options above is applied to the received options before
#   we process options_schema.
#
# * If validation fails an `@_error "invalid-options", message`
#   will be thrown, with message detailing in a human readable way the
#   validation issues.
#
# options_schema format
# ---------------------
#
# An object with the schema for options defined for each
# platform (both/server/client, server/client takes
# precedence over both).
#
# *The bind_to_instance schema option*
#
# We will recognize the `bind_to_instance` schema option.
# If `bind_to_instance` is set to true the option value
# will be assigned automatically to @[option_name].
# If `bind_to_instance` is false or doesn't exist, it is
# ignored.
#
# Note, at the moment for objects that inherits from
# constructors, it is best to ignore type checking
# by setting type to: "skip-type-check"
#
# *Example:*
#
#   options_schema =
#     both:
#       tasks_collection:
#         type: "skip-type-check"
#         optional: false
#         bind_to_instance: true
#       op_b:
#         type: Number
#         optional: true
#         defaultValue: 30
#     client:
#       op_c:
#         type: Number
#         optional: false
#     server:
#       op_d:
#         type: Number
#         optional: true
#         defaultValue: 30

GridControlCustomFieldsManager = (options) ->
  # skeleton-version: v0.0.9-client-only

  # Developer, avoid changing this constuctor, to do stuff on init
  # for use below the: @_immediateInit()

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("grid-control-custom-fields-manager")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options
  if not _.isEmpty(options_schema)
    # If options_schema is set, use it to apply strict structure on
    # @options.
    #
    # Clean and validate @options according to options_schema.
    # invalid-options error will be thrown for invalid options.
    # Takes care of binding options with bind_to_instance to
    # the instance.
    @options =
      JustdoHelpers.loadOptionsWithSchema(
        options_schema, @options, {
          self: @
          additional_schema: # Adds the `events' option to the permitted fields
            events:
              type: Object
              blackbox: true
              optional: true
        }
      )

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  # React to invalidations
  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @logger.debug "Enclosing computation invalidated, destroying"
      @destroy() # defined in client/api.coffee

  # on the client, call @_immediateInit() in an isolated
  # computation to avoid our init procedures from affecting
  # the encapsulating computation (if any)
  Tracker.nonreactive =>
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits GridControlCustomFieldsManager, EventEmitter

_.extend GridControlCustomFieldsManager.prototype,
  _error: JustdoHelpers.constructor_error