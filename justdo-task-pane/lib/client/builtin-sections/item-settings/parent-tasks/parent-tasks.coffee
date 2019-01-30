# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane_item_parent_tasks.onCreated ->
    _.extend @,
      error: new ReactiveVar(null)
      setError: (error) -> @error.set(error)
      clearError: -> @setError(null)
      clearInput: (input_selector) -> $(input_selector).val("")

      getServerResponseHandler: (input_selector) ->
        # input_selector will be cleared on success
        return (err) =>
          if err?
            @setError(err.reason)

            return

          if input_selector?
            @clearInput(input_selector)

          return

      getParentTaskPathIfNotTypedItem: ->
        # Returns the parent path of the current active path, only if:
        # * It is the root, or
        # * It is a non-typed item, i.e. it doesn't have the _type
        #   property
        #
        # Otherwise returns undefined

        current_path = module.activeItemPath()

        if not current_path?
          return undefined      

        parent_path =
          GridData.helpers.getParentPath(current_path)

        if GridData.helpers.isRootPath(parent_path)
          return parent_path

        parent_obj =
          module.gridControl()?.getPathObjNonReactive(parent_path) 

        if parent_obj._type?
          return undefined

        return parent_path

      getTaskIdForSeqIdInput: (input_selector) ->
        # Returns an object of the form:
        #
        # {
        #   error: null/"String with error",
        #   task_doc: an object if error is null, null otherwise 
        # }

        output = {
          error: null
          task_doc: null
        }

        ret = ->
          return output

        seq_id = $(input_selector).val().trim()

        if seq_id == ""
          return output

        if not /^\d+$/.test(seq_id)
          output.error = "Invalid Task #"

          return output

        seq_id = parseInt(seq_id, 10)

        if seq_id == 0
          # 0 is special case - means root
          output.item_id = "0"

          return output

        query = 
          project_id: module.curProj().id
          seqId: seq_id

        if not (task_doc = APP.collections.Tasks.findOne(query))?
          output.error = "Unknown task #"

          return output
        else
          output.item_id = task_doc._id

        return output

  Template.task_pane_item_parent_tasks.helpers
    error: -> Template.instance()?.error?.get()
    activeTaskParentIsNotTypedItem: ->
      tpl = Template.instance()

      return tpl.getParentTaskPathIfNotTypedItem()?

    currentTaskParentSeqId: ->
      tpl = Template.instance()

      if not (parent_path = tpl.getParentTaskPathIfNotTypedItem())?
        return "Unknown"

      if GridData.helpers.isRootPath(parent_path)
        return "project root"

      parent_obj =
        module.gridControl()?.getPathObjNonReactive(parent_path) 

      return "task ##{parent_obj.seqId}"

  Template.task_pane_item_parent_tasks.events
    "keydown .ptm-add-parent-task-form input,
     click .ptm-add-parent-task-form .ptm-add-parent-task":
      JustdoHelpers.blaze.events.catchClickAndEnter (e, tpl) ->
        # The following will execute if either the button
        # clicked or the enter pressed while editing the input
        tpl.clearError()

        input_selector = "#ptm-add-parent-seqid"

        {error, item_id} = tpl.getTaskIdForSeqIdInput(input_selector)
        new_parent_id = item_id

        if error?
          tpl.setError(error)

          return

        if not new_parent_id?
          # No new parent id provided
          tpl.clearError()

          return

        module.gridControl()?._grid_data?.addParent module.activeItemId(), {parent: new_parent_id}, tpl.getServerResponseHandler(input_selector)

        return

    "keydown .ptm-move-parent-task-form input,
     click .ptm-move-parent-task-form .ptm-move-parent-task":
      JustdoHelpers.blaze.events.catchClickAndEnter (e, tpl) ->
        # The following will execute if either the button
        # clicked or the enter pressed while editing the input
        tpl.clearError()

        input_selector = "#ptm-move-parent-seqid"

        {error, item_id} = tpl.getTaskIdForSeqIdInput(input_selector)
        target_parent_id = item_id

        if error?
          tpl.setError(error)

          return

        if not target_parent_id?
          # No target parent id provided
          tpl.clearError()

          return

        module.gridControl()?._grid_data?.movePath module.activeItemPath(), {parent: target_parent_id}, tpl.getServerResponseHandler(input_selector)

        return

    "keydown .ptm-remove-parent-task-form input,
     click .ptm-remove-parent-task-form .ptm-remove-parent-task":
      JustdoHelpers.blaze.events.catchClickAndEnter (e, tpl) ->
        # The following will execute if either the button
        # clicked or the enter pressed while editing the input
        tpl.clearError()

        input_selector = "#ptm-remove-parent-seqid"

        {error, item_id} = tpl.getTaskIdForSeqIdInput(input_selector)
        parent_id = item_id

        if error?
          tpl.setError(error)

          return

        if not parent_id?
          # No parent id provided
          tpl.clearError()

          return

        path_to_remove = "/#{module.activeItemId()}/"
        if parent_id != "0"
          path_to_remove = "/#{parent_id}" + path_to_remove

        module.gridControl()?._grid_data?.removeParent path_to_remove, tpl.getServerResponseHandler(input_selector)

        return

    "click .ptm-remove-current-parent-task": (e, tpl) ->
      if (tpl.getParentTaskPathIfNotTypedItem())?
        # Remove parent only if possible (parent path isn't typed item)
        module.gridControl()?._grid_data?.removeParent module.activeItemPath(), tpl.getServerResponseHandler()
