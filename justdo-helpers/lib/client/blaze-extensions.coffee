setupBlazeExtensions = ->
  # Derived from:
  # https://stackoverflow.com/questions/27949407/how-to-get-the-parent-template-instance-of-the-current-template

  # extend Blaze.View prototype to mimick jQuery's closest for views
  _.extend Blaze.View.prototype,
    closest: (view_name) ->
      view = @

      while view
        if view.name == "Template.#{view_name}" 
          return view

        view = view.parentView

      return null

  # extend Blaze.TemplateInstance to expose added Blaze.View functionalities
  _.extend Blaze.TemplateInstance.prototype,
    closestInstance: (view_name) ->
      view = @view.closest(view_name)

      if view
        return view.templateInstance()

      return null

setupTemplateExtensions = ->
  Template.closestInstance = (view_name) ->
    if not (cur_instance = @instance())?
      return null

    return cur_instance.closestInstance(view_name)

if (Blaze = Package.blaze?.Blaze)?
  setupBlazeExtensions()

if (Template = Package.templating?.Template)?
  setupTemplateExtensions()