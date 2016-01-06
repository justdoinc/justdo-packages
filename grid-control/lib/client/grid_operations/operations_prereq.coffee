prepareOpreqArgs = (prereq) ->
  return if prereq? then prereq else {}

_.extend GridControl.prototype,
  # The following methods used to generate a prerequisites object,
  # that is, an object that should be used to determine whether
  # operation's prerequisites are fulfilled before its execution.

  # These prerequisites generators receive an object as a parameter
  # and add to this object *only* the unfulfilled prerequisites.
  # The key is the prereq id the value is a human readable message to
  # be presented to the user when prereq isn't fulfilled.
  # (In case custom messages are needed, developers can disregard the
  #  message and use a custom one based on the prereq key instead).

  # The generators will make it easy to define operation prerequisites
  # Example:
  # prereq = @_opreqActivePath(@_opreqUnlocked({}))
  #
  # prereq will be an empty obj if operations lock is released and there's
  # an active path in the grid.
  # otherwise it won't be empty and its properties will list the issues.

  # Notes:
  # * The following should address only the common prerequisites, special
  # ones should be defined.
  # * All prereq generators should be reactive resources.
  # * As a standard prefix all prereq generators with _opreq (stands for
  # operation requires).

  _opreqGridReady: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @ready.get()
      prereq.grid_not_ready = "Waiting for grid to become ready"

    return prereq

  _opreqUnlocked: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @_operations_lock.get()
      prereq.ops_locked = "Waiting for operations to complete"

    return prereq

  _opreqActivePath: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @current_path.get()?
      prereq.current_path = "Select an item to perform this operation"

    return prereq

