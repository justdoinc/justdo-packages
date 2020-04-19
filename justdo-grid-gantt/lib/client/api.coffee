_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @
    @day =  24 * 3600 * 1000

    start_of_day_epoch = moment.utc(moment().format("YYYY-MM-DD")).unix() * 1000
    @epoch_time_from_rv = new ReactiveVar (start_of_day_epoch - 5 * @day)
    @epoch_time_to_rv = new ReactiveVar (start_of_day_epoch + 6 * @day - 1000)
    console.log ">>>>",@epoch_time_from_rv.get(), @epoch_time_to_rv.get()
    @dateStringToStartOfDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g

      if not re.test date
        return Date.UTC(0)

      split_date = date.split("-")

      return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

    @dateStringToEndOfDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g
      if not re.test date
        return Date.UTC(0)
      day = 1000 * 60 * 60 * 24
      return day - 1 + self.dateStringToStartOfDayEpoch date

    @dateStringToMidDayEpoch = (date) ->
      re = /^\d\d\d\d-\d\d-\d\d$/g
      if not re.test date
        return Date.UTC(0)
      half_day = 1000 * 60 * 60 * 12
      return half_day + self.dateStringToStartOfDayEpoch date

    @timeOffsetPixels = (epoch_range, time, width_in_pixels) ->
      epoch_start = epoch_range[0]
      epoch_end = epoch_range[1]
      if time < epoch_start or time > epoch_end or epoch_end <= epoch_start
        return undefined
      return (time - epoch_start) / (epoch_end - epoch_start) * width_in_pixels

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoGridGantt.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoGridGantt.project_custom_feature_id})

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGridGantt.project_custom_feature_id,
        installer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoGridGantt.pseudo_field_id,
              label: JustdoGridGantt.pseudo_field_label
              field_type: JustdoGridGantt.pseudo_field_type
              formatter: JustdoGridGantt.pseudo_field_formatter_id
              grid_visible_column: true
              grid_editable_column: false
              grid_dependencies_fields: JustdoGridGantt.gantt_field_grid_dependencies_fields
              default_width: 400

          controller = JustdoHelpers.renderTemplateInNewNode("justdo_grid_gantt_controller")
          APP.justdo_grid_gantt.controller_node = $(controller.node)
          $("body").append(APP.justdo_grid_gantt.controller_node)

        destroyer: =>
          if JustdoGridGantt.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridGantt.pseudo_field_id

          if APP.justdo_grid_gantt.controller_node?
            APP.justdo_grid_gantt.controller_node.remove()
            APP.justdo_grid_gantt.controller_node
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
    
  is_gantt_coloum_displayed_rv: new ReactiveVar false
  