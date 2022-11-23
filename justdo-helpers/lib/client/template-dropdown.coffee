# A very common usecase of a bound-element that is bound to a specific
# connected_element and renders a Meteor template as its dropdown content

TemplateDropdownProto = (connected_element) ->
  EventEmitter.call this

  @logger = Logger.get(@id)

  @$connected_element = $(connected_element)

  @initiated = false

  if @setup_basic_click_event
    # Stop propagations to avoid the click reaching body and triggering the
    # close event bound there
    @$connected_element
      .mousedown (e) =>
        e.stopPropagation()
      .click (e) =>
        e.stopPropagation()

        if @allowOpen()
          if @initiated
            @openDropdown()

  @current_dropdown_node = null

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

Util.inherits TemplateDropdownProto, EventEmitter

_.extend TemplateDropdownProto.prototype,
  id: null
  template_name: null

  template_data: undefined

  setup_basic_click_event: true

  custom_dropdown_class: ""
  custom_dropdown_content_class: ""
  custom_bound_element_options: {}

  dropdown_template_containing_node_tag: undefined # will use APP.helpers.renderTemplateInNewNode default if undefined
  dropdown_template_containing_node_class: undefined # Can have multiple classes - space separated

  _init: ->
    dropdown_html = """
      <div class="dropdown #{@id} #{@custom_dropdown_class}">
        <div class="dropdown-content #{@id}-content #{@custom_dropdown_content_class}"></div>
      </div>
    """

    dropdown_options = _.extend {}, @custom_bound_element_options,
      positionUpdateHandler: ($connected_element) =>
        @updateDropdownPosition($connected_element)
      openedHandler: => @dropdownOpenedHandler(@template_data)
      closedHandler: => @dropdownClosedHandler()

    @$dropdown =
      APP.helpers.initBoundElement dropdown_html, dropdown_options

    @initiated = true

  allowOpen: -> true

  openDropdown: ->
    if not @$dropdown.data("open")?
      @_init() # Re-init, the need to reinit might happen when blaze re-rerendered the element.

    @$dropdown.data("open")(@id, @$connected_element)

    return

  closeDropdown: ->
    @$dropdown.data("close")()

    return

  dropdownOpenedHandler: (data) ->
    @current_dropdown_node = 
      APP.helpers.renderTemplateInNewNode(@template_name, data, @dropdown_template_containing_node_tag)

    if @dropdown_template_containing_node_class?
      $(@current_dropdown_node.node).addClass(@dropdown_template_containing_node_class)

    $(".dropdown-content", @$dropdown).html @current_dropdown_node.node

    @$connected_element.addClass("open")

    @updateDropdownPosition(@$connected_element)

    @custom_bound_element_options.openedHandler?.call(@)

  dropdownClosedHandler: ->
    @custom_bound_element_options.beforeClosedHandler?.call(@)

    @$connected_element.removeClass("open")

    @destroyDropdownContentNode()

    @custom_bound_element_options.closedHandler?.call(@)

  destroyDropdownContentNode: ->
    if @current_dropdown_node?
      @current_dropdown_node.destroy()

      $(".dropdown-content", @$dropdown).html("")

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "right top"
        at: "right bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          element.element.css
            top: new_position.top
            left: new_position.left

  destroy: ->
    @$dropdown.data("destroy")?()

    @destroyDropdownContentNode()

generateNewTemplateDropdown = (id, template_name, prototype_customizations) ->
  template_dropdown_constructor = (connected_element, template_data) ->
    TemplateDropdownProto.call @, connected_element

    @template_data = template_data

    return @

  Util.inherits template_dropdown_constructor, TemplateDropdownProto

  _.extend template_dropdown_constructor.prototype,
    id: id
    template_name: template_name
  , prototype_customizations

  return template_dropdown_constructor

JustdoHelpers.generateNewTemplateDropdown = generateNewTemplateDropdown