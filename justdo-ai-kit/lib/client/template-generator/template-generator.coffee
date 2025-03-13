prompt_example_categories = [
  {
    _id: "make_a_plan"
    prompt: "ai_kit_template_example_make_a_plan"
    icon_name: "users"
    hexColor: "#027bff"
  },
  {
    _id: "develop_a_strategy"
    prompt: "ai_kit_template_example_develop_a_strategy"
    icon_name: "users"
    hexColor: "#c136d9"
  },
  {
    _id: "implement_a_system"
    prompt: "ai_kit_template_example_implement_a_system"
    icon_name: "users"
    hexColor: "#00c008"
  },
  {
    _id: "organize_an_event"
    prompt: "ai_kit_template_example_organize_an_event"
    icon_name: "users"
    hexColor: "#FF9800"
  },
  {
    _id: "launch_an_initiative"
    prompt: "ai_kit_template_example_launch_an_initiative"
    icon_name: "users"
    hexColor: "#607d8b"
  }
]

prompt_example_items =
  make_a_plan: [
    {
      title: "ai_kit_template_example_global_product_launch"
    },
    {
      title: "ai_kit_template_example_company_wide_rebranding_initiative",
    },
    {
      title: "ai_kit_template_example_strategic_partnership_program",
    },
    {
      title: "ai_kit_template_example_cross_departmental_training_program"
    }
  ]
  develop_a_strategy: [
    {
      title: "ai_kit_template_example_digital_transformation"
    },
    {
      title: "ai_kit_template_example_market_expansion"
    },
    {
      title: "ai_kit_template_example_customer_engagement"
    },
    {
      title: "ai_kit_template_example_sustainable_business_practices"
    }
  ]
  implement_a_system: [
    {
      title: "ai_kit_template_example_erp"
    },
    {
      title: "ai_kit_template_example_crm"
    },
    {
      title: "ai_kit_template_example_data_security"
    },
    {
      title: "ai_kit_template_example_remote_collaboration"
    }
  ]
  organize_an_event: [
    {
      title: "ai_kit_template_example_global_annual_conference"
    },
    {
      title: "ai_kit_template_example_cross_functional_team_workshop"
    },
    {
      title: "ai_kit_template_example_investor_relations_summit"
    },
    {
      title: "ai_kit_template_example_innovation_challenge"
    }
  ]
  launch_an_initiative: [
    {
      title: "ai_kit_template_example_corporate_sustainability_program"
    },
    {
      title: "ai_kit_template_example_employee_wellness_program"
    },
    {
      title: "ai_kit_template_example_customer_loyalty_program"
    },
    {
      title: "ai_kit_template_example_community_engagement"
    }
  ]

simple_prompt_example_items = [
  {
    title: "ai_kit_template_example_plan_trip"
    icon_name: "users"
    hexColor: "#027bff"
  },
  {
    title: "ai_kit_template_example_plan_wedding"
    icon_name: "users"
    hexColor: "#c136d9"
  },
  {
    title: "ai_kit_template_example_create_mobile_app"
    icon_name: "users"
    hexColor: "#00c008"    
  },
  {
    title: "ai_kit_template_example_write_childrens_book"
    icon_name: "users"
    hexColor: "#FF9800"
  },
  {
    title: "ai_kit_template_example_design_spaceship"
    icon_name: "users"
    hexColor: "#607d8b"
  }
]

Template.ai_template_generator.onCreated ->
  tpl = @

  tpl.controller = tpl.data?.controller
  if not tpl.controller?
    throw APP.justdo_ai_kit._error "AiTemplateGeneratorController is not provided to template_generator template."

  tpl.is_loading_rv = new ReactiveVar false
  tpl.prompt_example_category_rv = new ReactiveVar()
  # If this template is destroyed NOT because of creating items, stop the subscription and remove items from minimongo.
  tpl.close_due_to_create_items = false
  tpl.input_val_rv = new ReactiveVar ""
  tpl.show_dropdown_rv = new ReactiveVar false

  tpl.lockInput = ->
    $(".welcome-ai-input").prop "disabled", true
    return
  tpl.unlockInput = ->
    $(".welcome-ai-input").prop "disabled", false
    return

  tpl.showDropdown = ->
    $(".welcome-ai-dropdown").addClass "show"

  tpl.hideDropdown = ->
    $(".welcome-ai-dropdown").removeClass "show"

  tpl.showResultsDropdown = ->
    $(".welcome-ai-results").removeClass "hide"

  tpl.hideResultsDropdown = ->
    $(".welcome-ai-results").addClass "hide"

  tpl.sendRequestToOpenAI = (request) ->
    tpl.controller.setSentRequest request
    tpl.is_loading_rv.set true
    tpl.lockInput()

    if not _.isEmpty(old_stream_handler = tpl.controller.getStreamHandler())
      old_stream_handler.logResponseUsage "d"
      old_stream_handler.stopSubscription()
    
    msg = request.msg 
    if (simplify_response = tpl.showSimpleSmartBubble())
      msg = TAPi18n.__("ai_kit_template_example_simplify_prompt", {prompt: msg})

    options =
      template_id: "stream_project_template"
      template_data:
        msg: msg
      cache_token: request.cache_token
      simplify_response: simplify_response
      subOnReady: ->
        tpl.is_loading_rv.set false
        tpl.unlockInput()
        if not (stream_handler.findOne({}, {fields: {_id: 1}}))?
          JustdoSnackbar.show
            text: TAPi18n.__ "stream_response_generic_err"
        return
      subOnStop: (err) ->
        if err?
          JustdoSnackbar.show
            text: TAPi18n.__ "stream_response_generic_err"
          tpl.is_loading_rv.set false
          tpl.unlockInput()
        return

    stream_handler = APP.justdo_ai_kit.createStreamRequestAndSubscribeToResponse options
    tpl.controller.setStreamHandler stream_handler

  tpl.clearInput = ->
    if tpl.controller.isResponseExists()
      tpl.hideResultsDropdown()
      tpl.controller.getStreamHandler().stopStream()
      tpl.unlockInput()

    tpl.setInputFieldVal ""

    return

  tpl.setActivePromptExample = (category) ->
    tpl.prompt_example_category_rv.set category
    return
  
  tpl.getActivePromptExample = -> tpl.prompt_example_category_rv.get()

  tpl.getPromptExampleItems = ->
    if not (category = tpl.getActivePromptExample())?
      return
    
    examples = prompt_example_items[category._id]

    if _.isEmpty(input = tpl.input_val_rv.get())
      return examples

    return _.filter examples, (item) ->
      translated_title = TAPi18n.__ item.title
      translated_title_without_html = jQuery("<span>#{translated_title}</span>").text()

      lower_cased_trimmed_input = input.toLowerCase().trim()
      lower_cased_trimmed_title = translated_title_without_html.toLowerCase().trim()
      return lower_cased_trimmed_title.startsWith lower_cased_trimmed_input


  tpl.setInputFieldVal = (val) ->
    tpl.input_val_rv.set val
    $(".welcome-ai-input").val val
    return
  
  tpl.showSimpleSmartBubble = -> 
    # We have the regular set of smart bubbles prompt_example_categories and their prompts prompt_example_items
    # We also have a simplified set of prompts simple_prompt_example_items, which we will add i18ned "and explain to me like I am 7 years old" to the end of the prompt

    # This method is a toss of coin mechanism to decide whether to show the simplified set of prompts or not
    # The decision is stored in local storage to maintain consistency across sessions
    # The chance of showing the simplified set of prompts is controlled by the chance_simple_smart_bubble_in_use variable
    # The ai logs collection will also store whether the simplified set of prompts was used or not
    if (stored_show_simple_smart_bubble = amplify.store(JustdoAiKit.show_simple_smart_bubble_local_storage_key))?
      return stored_show_simple_smart_bubble
      
    show_simple_smart_bubble = Math.random() < JustdoAiKit.chance_simple_smart_bubble_in_use
    amplify.store JustdoAiKit.show_simple_smart_bubble_local_storage_key, show_simple_smart_bubble

    return show_simple_smart_bubble

  $(document).on "keydown", (e) ->
    if e.key == "Escape"
      tpl.clearInput()

    return

  return

Template.ai_template_generator.onRendered ->
  @type = null

  # The element 'welcome-ai-typed' is disabled and hidden using CSS styles

  # Initialize the typed.js plugin and ensure content is reactive to language change.
  # @autorun =>
  #   @typed?.destroy?()
  #
  #   input_placeholders = TAPi18n.__("ai_wizard_input_examples").split "\n"
  #   type_speed = 30
  #   if APP.justdo_i18n?.getLang() is "zh-TW"
  #     type_speed = 50
  #
  #   @typed = new Typed ".welcome-ai-typed-text span",
  #     strings: input_placeholders
  #     typeSpeed: type_speed
  #     backSpeed: 8
  #     backDelay: 1500
  #     loop: true
  #     smartBackspace: true
  #     shuffle: true
  #
  #   return

  return

Template.ai_template_generator.helpers
  prePromptTxtI18n: ->
    tpl = Template.instance()
    return tpl.controller.getPrePromptTxtI18n()

  loadingBtnLabelI18n: ->
    if Meteor.userId()
      return "ai_wizard_loading_btn_existing_user_label"
    else
      return "ai_wizard_loading_btn_new_user_label"

  createBtnLabelI18n: ->
    if Meteor.userId()
      return "ai_wizard_create_btn_existing_user_label"
    else
      return "ai_wizard_create_btn_new_user_label"

  isLandingPage: ->
    return APP.justdo_ai_kit.app_type is "landing-app"

  isLoading: ->
    tpl = Template.instance()

    return tpl.is_loading_rv.get()

  hasInput: -> 
    tpl = Template.instance()
    return not _.isEmpty tpl.input_val_rv.get()

  isResponseExists: ->
    tpl = Template.instance()
    return tpl.controller.isResponseExists()

  rootTemplate: ->
    tpl = Template.instance()

    if _.isEmpty(stream_handler = tpl.controller.getStreamHandler())
      return
    
    root_tasks = stream_handler.find({"data.parent": -1}).fetch()

    return root_tasks

  promptBubbles: ->
    return _.shuffle prompt_example_categories

  activePromptBubble: ->
    return Template.instance().getActivePromptExample()

  promptExampleItems: ->
    tpl = Template.instance()
    return tpl.getPromptExampleItems()
  
  simplePromptExampleItems: -> 
    return _.shuffle simple_prompt_example_items

  promptBubbleBorderColor: (hexColor) ->
    hexColor = hexColor.replace("#", "")
    r = parseInt(hexColor[0..1], 16)
    g = parseInt(hexColor[2..3], 16)
    b = parseInt(hexColor[4..5], 16)

    return "rgba(#{r}, #{g}, #{b}, 0.5)"
  
  showSimpleSmartBubble: -> 
    tpl = Template.instance()
    return tpl.showSimpleSmartBubble()
  
  shouldShowExamplesDropdown: ->
    tpl = Template.instance()

    show_simple_smart_bubble = tpl.showSimpleSmartBubble()
    is_response_exists = tpl.controller.isResponseExists()
    is_loading = tpl.is_loading_rv.get()

    if show_simple_smart_bubble or is_response_exists or is_loading
      return false

    if not tpl.show_dropdown_rv.get()
      return false
    
    has_example_items = not _.isEmpty tpl.getPromptExampleItems()
    return has_example_items

Template.ai_template_generator.events
  "click .welcome-ai-btn-generate": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()

    # If request is empty, use the first example prompt from the dropdown.
    if not _.isEmpty request
      tpl.sendRequestToOpenAI {msg: request}
      return

    $(".welcome-ai-input").focus()

    return

  "keyup .welcome-ai-input": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()

    if e.keyCode is 13
      $(".welcome-ai-btn-generate").click()
    return

  # This is to handle the checkbox logic for the AI response items:
  # If a child item is checked, all its parent items will be checked;
  # If a parent item is unchecked, all its child items will be unchecked.
  "click .welcome-ai-result-item-content": (e, tpl) ->
    $item_content = $(e.target).closest(".welcome-ai-result-item-content")
    $checkbox = $item_content.find(".welcome-ai-result-item-checkbox")
    check_state = null

    if $checkbox.hasClass "checked"
      check_state = false
      $checkbox.removeClass "checked"
    else
      check_state = true
      $checkbox.addClass "checked"

    # Checks/unchecks child tasks
    $item_content.siblings().each (i, el) ->
      $(el).find(".welcome-ai-result-item-checkbox").each (i, el_checkbox) ->
        if check_state
          $(el_checkbox).addClass "checked"
        else
          $(el_checkbox).removeClass "checked"

        return
      return

    if check_state
      # Ensure all parents are checked
      $item = $(e.target).closest(".welcome-ai-result-item")
      while ($parent_content = $item.siblings(".welcome-ai-result-item-content")).length > 0
        $parent_content.find(".welcome-ai-result-item-checkbox").addClass "checked"
        $item = $parent_content.closest(".welcome-ai-result-item")

    excluded_item_keys = $(".welcome-ai-result-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get()
    tpl.controller.setExcludedItemKeys excluded_item_keys

    return

  "click .welcome-ai-create-btn": (e, tpl) ->
    if tpl.is_loading_rv.get()
      return

    controller = tpl.controller
    stream_handler = tpl.controller.getStreamHandler()

    excluded_items = []
    choice = "a"
    if not _.isEmpty(excluded_items = controller.getExcludedItemKeys())
      choice = "p"

    query =
      key:
        $nin: excluded_items
    choice_data = stream_handler.find(query).fetch()
    stream_handler.logResponseUsage choice, choice_data

    controller.onCreateBtnClick()
    return

  "click .welcome-ai-stop-generation": (e, tpl) ->
    tpl.controller.getStreamHandler().stopStream()
    tpl.unlockInput()
    $(".welcome-ai-input").focus()
    return

  "focus .welcome-ai-input, click .welcome-ai-input": (e, tpl) ->
    if tpl.controller.isResponseExists()
      tpl.showResultsDropdown()
    
    tpl.show_dropdown_rv.set true

    $(".welcome-ai-input-wrapper").addClass "hide-typed-element"

    return

  "blur .welcome-ai-input": (e, tpl) ->
    tpl.show_dropdown_rv.set false

    if not _.isEmpty $(".welcome-ai-input").val()
      return

    $(".welcome-ai-input-wrapper").removeClass "hide-typed-element"
    return

  "keyup .welcome-ai-input": (e, tpl) ->
    if e.keyCode is 13
      $(".welcome-ai-btn-generate").click()

    if not _.isEmpty(input_val = $(".welcome-ai-input").val())
      $(".welcome-ai-input-wrapper").addClass "hide-typed-element"
    
    tpl.input_val_rv.set input_val

    return

  "click .welcome-ai-prompt-bubble": (e, tpl) ->
    item_data = Blaze.getData(e.target)
    tpl.setActivePromptExample item_data
    
    tpl.setInputFieldVal TAPi18n.__(item_data.prompt)
    $welcome_ai_input = $(".welcome-ai-input")
    $welcome_ai_input.focus()

    return

  "click .welcome-ai-prompt-example, click .simplified-ai-prompt-bubble": (e, tpl) ->
    tpl.setInputFieldVal jQuery("<span>#{TAPi18n.__ @title}</span>").text()
    $(".welcome-ai-btn-generate").click()
    return

  "mousedown .welcome-ai-prompt-example": (e) ->
    # Prevent the input field from losing focus when clicking on the prompt example.
    e.preventDefault()
    return

  "click .welcome-ai-clear": (e, tpl) ->
    tpl.clearInput()
    tpl.controller.clearResponse()

    return

Template.ai_template_generator.onDestroyed ->
  @typed?.destroy?()

  if @controller.stopSubscriptionUponDestroy()
    # If template is closed before any prompt, getStreamHandler would return nothing. Therefore exists check is necessary.
    @controller.getStreamHandler().stopSubscription?()

  return

Template.ai_template_item.onCreated ->
  @parentTemplateInstance = -> Blaze.getView("Template.ai_template_generator").templateInstance()
  return

Template.ai_template_item.helpers
  childTemplate: ->
    tpl = Template.instance()
    parent_tpl = tpl.parentTemplateInstance()
    return parent_tpl.controller.getStreamHandler().find({"data.parent": @key}).fetch()
