_.extend JustdoChat.prototype,
  _setupMessageCardDropdown: ->
    # Create Chat dropdown
    MessageCardDropdown = JustdoHelpers.generateNewTemplateDropdown "message-card-dropdown", "message_card_dropdown",
      custom_bound_element_options:
        close_button_html: null
        close_on_bound_elements_show: false

      updateDropdownPosition: ($connected_element) ->
        @$dropdown
          .position
            of: $connected_element
            my: "left top"
            at: "left bottom"
            collision: "fit fit"
            using: (new_position, details) =>
              target = details.target
              element = details.element
              element.element.addClass "animate slideIn shadow-lg bg-white"
              element.element.css
                top: new_position.top - 8
                left: new_position.left - 2
              return

        return  
    
    # Append helper - invisible $connected_element for dropdown
    $("body").append("<div class='message-card-dropdown-helper'></div>")
    $message_card_dropdown_container = $(".message-card-dropdown-helper")

    message_card_dropdown = new MessageCardDropdown($message_card_dropdown_container[0])

    # Show dropdown on Right click
    $("body").on "contextmenu", ".message-card", (e) =>
      e.preventDefault()

      # Move helper to the mouse click position
      $message_card_dropdown_container.offset {top: e.pageY, left: e.pageX}

      # Open dropdown
      Meteor.defer ->
        message_card_dropdown.openDropdown()
      
      # Retrive closest message board data
      $message_board = $(e.currentTarget).closest(".messages-board-viewport")
      $message_board_data = Blaze.getData($message_board[0])
      # Retrive channel object
      channel_obj = $message_board_data.getChannelObject()

      message_obj = Blaze.getData(e.currentTarget)
      message_id = message_obj._id

      message_card_dropdown.template_data = 
        channel_obj: channel_obj
        message_obj: message_obj
        itemsGenerator: -> JD.getPlaceholderItems("message-card-dropdown")
        footerItemsGenerator: -> JD.getPlaceholderItems("message-card-dropdown-footer")
      return
    
    JD.registerPlaceholderItem "who-read-message",
      domain: "message-card-dropdown"
      position: 100
      data:
        template: "message_card_dropdown_who_read_message"
    
    JD.registerPlaceholderItem "reply-message",
      domain: "message-card-dropdown"
      position: 200
      data:
        template: "message_card_dropdown_reply_message"
    
    JD.registerPlaceholderItem "footer-created-at",
      domain: "message-card-dropdown-footer"
      position: 100
      data:
        template: "message_card_dropdown_footer_created_at"
        
    return

Template.message_card_dropdown.helpers 
  items: ->
    tpl = Template.instance()
    return tpl.data.itemsGenerator?() or []
  
  hideFooter: ->
    tpl = Template.instance()
    return tpl.data.hide_footer
  
  footerItems: ->
    tpl = Template.instance()
    return tpl.data.footerItemsGenerator?() or []
  
  extendedTemplateData: ->
    tpl = Template.instance()
    template_data = _.extend {}, tpl.data, @templateData
    return template_data

Template.message_card_dropdown_footer_created_at.helpers
  messageCreatedAt: ->
    tpl = Template.instance()
    message_obj = tpl.data.message_obj
    return moment(message_obj.createdAt).format("DD MMMM, HH:mm")

Template.message_card_dropdown_who_read_message.onCreated ->
  @channelHasMoreThanTwoSubscribers = ->
    subscribers = @data.channel_obj.getSubscribersArray()
    return subscribers.length > 2
  
  if not @channelHasMoreThanTwoSubscribers()
    return

  WhoReadMessageDropdown = JustdoHelpers.generateNewTemplateDropdown "who-read-message-dropdown", "message_card_dropdown",
    custom_bound_element_options:
      close_button_html: null

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $(".who-read-message")
          my: "left top"
          at: "right top"
          collision: "flip fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg bg-white"
            element.element.css
              top: new_position.top - 8
              left: new_position.left - 2
            return

      return  

  # Append helper - invisible $connected_element for dropdown
  $("body").append("<div class='who-read-message-dropdown-helper'></div>")
  @$who_read_message_dropdown_container = $(".who-read-message-dropdown-helper")
  @who_read_message_dropdown = new WhoReadMessageDropdown(@$who_read_message_dropdown_container[0])

  return

Template.message_card_dropdown_who_read_message.onDestroyed ->
  @$who_read_message_dropdown_container?.remove()
  @who_read_message_dropdown?.destroy()
  return

Template.message_card_dropdown_who_read_message.helpers
  readCount: ->
    tpl = Template.instance()
    read_subscribers = tpl.data.channel_obj.getSubscribersWhoReadMessage(tpl.data.message_obj)
    return read_subscribers.length
  
  myMessage: ->
    tpl = Template.instance()
    return tpl.data.message_obj.author is Meteor.userId()
  
  channelHasMoreThanTwoSubscribers: ->
    tpl = Template.instance()
    return tpl.channelHasMoreThanTwoSubscribers()

Template.message_card_dropdown_who_read_message.events
  "mouseover .who-read-message": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    if not tpl.channelHasMoreThanTwoSubscribers()
      return
    
    if tpl.who_read_message_dropdown.isOpenDropdown()
      return
      
    channel_obj = tpl.data.channel_obj
    message_obj = tpl.data.message_obj

    # Move helper to the mouse click position
    tpl.$who_read_message_dropdown_container.offset {top: e.currentTarget.offsetHeight + e.pageY, left: e.currentTarget.offsetWidth + e.pageX}

    # Open dropdown
    Meteor.defer ->
      tpl.who_read_message_dropdown.openDropdown()
    
    tpl.who_read_message_dropdown.template_data = 
      channel_obj: channel_obj
      message_obj: message_obj
      itemsGenerator: -> 
        read_subscribers = channel_obj.getSubscribersWhoReadMessage(message_obj)
        subscriber_docs_without_self = _.map read_subscribers, (subscriber_doc) ->
          user_doc = Meteor.users.findOne subscriber_doc.user_id
          return {template: "message_card_dropdown_who_read_message_item", templateData: user_doc}
        
        return subscriber_docs_without_self
    return
  
  "mouseleave .who-read-message": (e, tpl) ->
    if $(e.relatedTarget).hasClass("who-read-message-item")
      return

    tpl.who_read_message_dropdown?.closeDropdown()
    return
