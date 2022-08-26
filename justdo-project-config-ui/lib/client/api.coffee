# The code below, for the most part, copied to justdo-user-config-ui
# if you fix a bug, consider doing it there as well.
_.extend JustdoProjectConfigUI.prototype,
  getSections: ->
    @sections_dep.depend()

    return @sections

  getSectionsForPresentations: ->
    # Derive an array from @sections, ordered by "priority"
    sections = _.sortBy @getSections(), "priority"
    sections = _.map sections, (section) ->
      # Shallow copy
      section = _.extend {}, section

      section.templates = _.sortBy section.templates, "priority"

      return section

    # Remove sections with no templates
    sections = _.filter sections, (section) -> not _.isEmpty(section.templates)

    return sections

  show: (options) ->
    options = _.extend {dialog_title: "Configure this JustDo"}, options

    template_data =
      sections: =>
        sections = @getSectionsForPresentations()
        sections_general = []
        sections_extensions = []

        for section in sections
          if section.id == "extensions"
            sections_extensions.push section
          else
            sections_general.push section

        return {"general": sections_general, "extensions": sections_extensions}

    message_template =
      APP.helpers.renderTemplateInNewNode(Template.project_config_dialog, template_data)

    bootbox.dialog
      message: message_template.node
      animate: false
      className: "project-configuration-dialog bootbox-new-design"

      onEscape: ->
        return true

    return

  showCustomFieldsConfigurationOnly: ->
    @show({dialog_title: "Configure Custom Fields"})
    $('.project-configuration-dialog [section-id]:not([section-id="custom-fields"])').hide()

    return

  registerConfigSection: (section_id, settings) ->
    if not section_id?
      throw @_error "missing-argument", "section_id must be set"

    if not settings?
      throw @_error "missing-argument", "settings must be set"

    if section_id of @sections
      throw @_error "section-id-already-exists", "section_id #{section_id} already defined"

    settings = _.pick settings, "title", "priority"

    settings = _.extend {}, settings,
      id: section_id
      templates: {}

    # title can be null/undefined, so no need to test it

    if not settings.priority?
      throw @_error "invalid-argument", "settings.priority must be set"

    @sections[section_id] = settings
    @sections_dep.changed()

    return

  unregisterConfigSection: (section_id) ->
    delete @sections[section_id]
    @sections_dep.changed()

    return

  registerConfigTemplate: (template_id, settings) ->
    if not template_id?
      throw @_error "missing-argument", "template_id must be set"

    if not settings?
      throw @_error "missing-argument", "settings must be set"

    settings = _.pick settings, "section", "template", "priority"

    if not (section_id = settings.section)?
      throw @_error "invalid-argument", "settings.section must be set"

    if section_id not of @sections
      throw @_error "unknown-section", "Unknown section id: #{section_id}"

    if @sections[section_id].templates[template_id]?
      throw @_error "tempate-already-defined", "Template id #{template_id} already defined for section #{section_id}"

    if not Template[settings.template]?
      throw @_error "invalid-argument", "Unknown template name: #{settings.template}"

    if not settings.priority?
      throw @_error "invalid-argument", "settings.priority must be set"

    settings = _.extend {}, settings,
      id: template_id

    @sections[section_id].templates[template_id] = settings
    @sections_dep.changed()

    return

  unregisterConfigTemplate: (section_id, template_id) ->
    if not @sections[section_id].templates[template_id]
      console.warn "Unknown section/template #{section_id}/#{template_id}"
      return
    
    delete @sections[section_id].templates[template_id]
    @sections_dep.changed()

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
