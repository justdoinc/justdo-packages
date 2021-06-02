_.extend JustdoHelpers,
  renderTemplateInNewNode: (template, data, node_tag="div") ->
    # IMPORTANT: If the View is removed by some other mechanism besides Meteor or jQuery
    # (which Meteor integrates with by default), the View may continue to
    # update indefinitely.
    # Therefore you must ensure destruction of the view in these cases!

    if _.isString template
      template = Template[template]

    node = document.createElement(node_tag)
    document.body.appendChild(node)
    view = UI.renderWithData(template, data, node)

    return {
      node: node
      view: view
      template_instance: view._domrange.members[0].view._templateInstance
      getData: -> view.dataVar.get()
      destroy: ->
        Blaze.remove view

        $(node).remove()

        return
    }

  tplProp: (property) -> Template.instance()?[property]

  getBlazeTemplateForHtml: (html, options) ->
    # html can be either String or a Function that returns a String
    #
    # options will be passed to the html if it is a function

    return new Template () =>
      inner = html
      if _.isFunction inner
        inner = inner(options)

      return HTML.Raw inner

  generateRerenderForcer: ->
    bool_state = true

    return ->
      bool_state = not bool_state

      return bool_state

  withTemplateInstance: (tpl, cb) ->
    # Sets correctly Template._currentTemplateInstanceFunc to the provided tpl object
    # before calling cb and release after cb completes.
    #
    # The need for this function is to be able to call from Template.XX.onRendered
    # to methods that uses Template.closestInstance.

    templateFunc = -> tpl

    return Template._withTemplateInstanceFunc templateFunc, ->
      return Blaze._withCurrentView tpl.view, cb

  blaze:
    events:
      catchClickAndEnter: (cb) ->
        # Returns an event handler that calls cb
        # if one of the following happens:
        #   * enter key pressed on a text <input>
        #   * user clicked on <button> or submit <input>
        #
        # Usage Example
        #
        #   "click button, keydown input":
        #     JustdoHelpers.blaze.events.catchClickAndEnter ->
        #       # The following will execute if either the button
        #       # clicked or the enter pressed while editing the input
        #       console.log "Perform action"

        return (e) ->
          $target = $(e.target)

          if $target.is("""input[type="text"],input[type="password"]""")
            if e.type == "keydown" and e.which == 13 or e.keyCode == 13
              return cb.apply(@, arguments)
          else if $target.is("""input[type="submit"],input[type="button"],button,div""")
            if e.type == "click"
              return cb.apply(@, arguments)

          return

if (templating = Package.templating)?
  {Template} = templating
  
  Template.registerHelper "debugger", (input) ->
    debugger
    return "DEBUGGER"