_.extend GridData.prototype,
  before_db_commit_hook: (name, hook) ->
    # before_db_commit_hook(hook_name, hook(userId, doc, fieldNames, modifier, options))

    # Fires before edits

    # Gives you an opportunity to change the modifier as needed, or run additional
    # functionality.

    # Returning false in the hook function will prevent the requested edit from executing.
    # Note that all before_edit hooks will still continue to run even if the first hook returns
    # false.

    # If an edit is rejected by a hook (false returned):
    # * The edit-failed event will be fired with a Meteor.Error of type "edit-blocked-by-hook" as its first argument
    # * An info log will be logged by the looger saying that: "[grid-data] Edit was prevented by hook: #{hook_name}".

    # Notes:

    # * Within the hook function this.transform() obtains transformed version of document, if a transform was defined.
    # Change.
    # * we are changing modifier, and not doc. Changing doc won't have any effect as the document is a copy and is not what
    # ultimately gets sent down to the underlying update method.

    # Example 1, block all edits (Coffee):

    #   grid_data.before_db_commit_hook "Block all edits", -> return false

    # Example 2, block edits that attempts to a non empty title to empty (Coffee):

    #   grid_data.before_db_commit_hook "Title can't be cleared", (userId, doc, fieldNames, modifier, options) ->
    #     if doc.title? and doc.title != "" and modifier?.$set?.title? and modifier.$set.title is ""
    #        return false

    self = this

    wrapped_hook = () ->
      result = hook.apply(this, arguments)

      if result is false
        self.logger.info "Edit prevented by hook #{name}"

      result
      
    @collection.before.update wrapped_hook

