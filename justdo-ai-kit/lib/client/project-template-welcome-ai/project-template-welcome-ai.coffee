Template.project_template_welcome_ai.onCreated ->
  tpl = @

  @template_generator_controller = new JustdoAiKit.AiTemplateGeneratorController
    onCreateBtnClick: ->
      sent_request = tpl.template_generator_controller.getSentRequest()
      # Set the project title
      if (template = APP.justdo_projects_templates?.getTemplateById sent_request?.cache_token)?
        project_title = TAPi18n.__ template.label_i18n
        APP.collections.Projects.update JD.activeJustdoId(), {$set: {title: project_title}}
      else
        APP.justdo_ai_kit.generateProjectTitle sent_request?.msg, (err, res) ->
          if err?
            console.error err
            return

          APP.justdo_ai_kit.logResponseUsage res.req_id, "a", res.title
          APP.collections.Projects.update JD.activeJustdoId(), {$set: {title: res.title}}
          return

      stream_handler = tpl.template_generator_controller.getStreamHandler()
      project_id = JD.activeJustdoId()
      grid_data = APP.modules.project_page.gridData()
      postNewProjectTemplateCreationCallback = (created_task_path) ->
        grid_control = grid_data.grid_control

        if not (project_id = JD.activeJustdoId())?
          return

        if _.isString created_task_path
          grid_control.once "rebuild_ready", ->
            grid_control.forceItemsPassCurrentFilter GridData.helpers.getPathItemId created_task_path
            grid_data.expandPath created_task_path
            return

        # If not all tasks are created, return here.
        if stream_handler.find().count() isnt handled_item_keys.length
          return

        stream_handler.stopSubscription()
        
        cur_proj = -> APP.modules.project_page.curProj()

        if cur_proj().isCustomFeatureEnabled JustdoPlanningUtilities.project_custom_feature_id
          grid_control.setView JustDoProjectsTemplates.template_grid_views.gantt

          APP.justdo_planning_utilities?.once "changes-queue-processed", ->
            if (first_task_id = APP.collections.Tasks.findOne({project_id}, {fields: {_id: 1}, sort: {seqId: 1}})?._id)
              task_info = APP.justdo_planning_utilities.getOrCreateTaskInfoObject(first_task_id)
              {earliest_child_start_time, latest_child_end_time} = task_info
              if earliest_child_start_time? and latest_child_end_time?
                # Set the date range presented in the gantt
                APP.justdo_planning_utilities.setEpochRange [earliest_child_start_time, latest_child_end_time], grid_control.getGridUid()

            return

        return
      handled_item_keys = []
      recursiveBulkCreateTasks = (path, template_items_arr) ->
        # template_item_keys is to keep track of the corresponding template item id for each created task
        template_item_keys = _.map template_items_arr, (item) -> item.key
        items_to_add = _.map template_items_arr, (item) ->
          item.data.project_id = project_id
          return item.data

        grid_data.bulkAddChild path, items_to_add, (err, created_task_ids) ->
          if err?
            JustdoSnackbar.show
              text: err.reason or err
            return

          for created_task_id_and_path, i in created_task_ids
            created_task_path = created_task_id_and_path[1]
            corresponding_template_item_key = template_item_keys[i]

            handled_item_keys.push corresponding_template_item_key

            child_query =
              "data.parent": corresponding_template_item_key
            if not _.isEmpty excluded_item_keys
              child_query.key =
                $nin: excluded_item_keys

            if _.isEmpty (child_template_items = stream_handler.find(child_query).fetch())
              postNewProjectTemplateCreationCallback created_task_path
            else
              recursiveBulkCreateTasks created_task_path, child_template_items

          return

        return

      query =
        "data.parent": -1

      # In case the resnpose has only 1 root task, use the child tasks as root tasks.
      if (cursor = stream_handler.find(query)).count() is 1
        item_to_ignore = cursor.fetch()
        handled_item_keys.push item_to_ignore.key
        query["data.parent"] = 0

      if not _.isEmpty(excluded_item_keys = tpl.template_generator_controller.getExcludedItemKeys())
        handled_item_keys = handled_item_keys.concat excluded_item_keys
        query.key =
          $nin: excluded_item_keys

      if _.isEmpty(template_items = stream_handler.find(query).fetch())
        return

      # Top level tasks' state should always be nil
      template_items = _.map template_items, (item) ->
        item.data.state = "nil"
        delete item.data.start_date
        delete item.data.end_date
        delete item.data.due_date
        return item
      recursiveBulkCreateTasks("/", template_items)

      # Due to the recursive nature of recursiveBulkCreateTasks, the task creation will continue after the template is destroyed.
      # Therefore we want to keep the sub alive until the task creation is done (inside postNewProjectTemplateCreationCallback).
      tpl.template_generator_controller.setStopSubscriptionUponDestroy false
      tpl.bootbox_dialog.modal "hide"
      return

  return

Template.project_template_welcome_ai.onRendered ->
  setTimeout ->
    $(".welcome-ai-skip-wrapper").addClass "show"
  , JustdoAiKit.template_generator_show_skip_btn_delay

  return

Template.project_template_welcome_ai.events
  "click .welcome-ai-skip": (e, tpl) ->
    # If template generation is skipped, create an empty task.
    APP.modules.project_page.gridData()?.addChild "/",
      title: TAPi18n.__ "untitled_task_title"
      project_id: JD.activeJustdoId()
    , -> 
      # Regardless of whether the task creation is successful, hide the modal.
      $('.project-template-ai-modal').modal "hide"
      return

    return

Template.project_template_welcome_ai.helpers
  isResponseExists: ->
    tpl = Template.instance()
    return tpl.template_generator_controller.isResponseExists()

  childTemplateData: ->
    tpl = Template.instance()
    ret =
      controller: tpl.template_generator_controller
    return ret
