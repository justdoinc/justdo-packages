Template.merge_justdo_cog_button.events
  "click .open-merge-justdo-dialog": (e, tpl) ->
    merge_justdo_dialog_tpl =
      JustdoHelpers.renderTemplateInNewNode Template.merge_justdo_dialog, {}

    bootbox.dialog
      title: "Merge JustDo"
      message: merge_justdo_dialog_tpl.node
      animate: false
      className: "merge-justdo-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        close:
          label: "Cancel"

          className: "btn-default"

          callback: ->
            return true

        merge:
          label: """
            <svg class="jd-icon-dropdown text-secondary">
              <use xlink:href="/layout/icons-feather-sprite.svg#download"/>
            </svg>
            Merge
          """

          className: "btn-primary"

          callback: =>
            return merge_justdo_dialog_tpl.template_instance.confirmMerge()

    return

Template.merge_justdo_dialog.onCreated ->
  tpl = @

  tpl.justdos_filter_text_rev = new ReactiveVar ""
  tpl.justdo_selected_rev = new ReactiveVar null

  tpl.confirmMerge = ->
    justdo_selected = tpl.justdo_selected_rev.get()
    
    if not justdo_selected?
      alert "Please select a JustDo to merge to"

      return false
      
    merge_justdo_confirm_tpl =
      JustdoHelpers.renderTemplateInNewNode Template.merge_justdo_confirm, 
        target_justdo_id: justdo_selected

    bootbox.dialog
      title: "Confirm Merge"
      message: merge_justdo_confirm_tpl.node
      animate: false
      className: "merge-justdo-confirm-dialog bootbox-new-design"
      size: "extra-large"

      onEscape: ->
        return true

      buttons:
        close:
          label: "Cancel"

          className: "btn-primary"

          callback: ->
            return true

    return false

  return

filterJustdosDocsArray = (justdos_docs, niddle) ->
  if not niddle?
    return justdos_docs

  filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(niddle)}", "i")

  results = _.filter justdos_docs, (doc) ->
    return filter_regexp.test doc.title

  return results

Template.merge_justdo_dialog.helpers
  justdos: -> 
    justdos = APP.collections.Projects.find 
      _id: 
        $ne: JD.activeJustdo()._id
      members: 
        $elemMatch:
          user_id: Meteor.userId()
          is_admin: true
    , 
      fields:
        _id: 1
        title: 1
    .fetch()

    return filterJustdosDocsArray justdos, Template.instance().justdos_filter_text_rev.get()
    
  justdoSelected: (justdo) ->
    return Template.instance().justdo_selected_rev.get() == justdo._id

Template.merge_justdo_dialog.events
  "keyup .justdos-selector-search": (e, tpl) ->
    tpl.justdos_filter_text_rev.set $(e.target).val()
    return true
  
  "click .justdos-filter-justdo-item": (e, tpl) ->
    justdo_id = $(e.currentTarget).data "justdo-id"
    tpl.justdo_selected_rev.set justdo_id

    return true

Template.merge_justdo_confirm.onCreated ->
  tpl = @
  tpl.allow_confirm_rev = new ReactiveVar false
  tpl.is_merging_rev = new ReactiveVar false

  tpl.autorun ->
    tpl.data.target_justdo = APP.collections.Projects.findOne
      _id:
        tpl.data.target_justdo_id
    ,
      fields:
        _id: 1
        title: 1
  
    return

  return

Template.merge_justdo_confirm.helpers
  allowConfirm: -> 
    tpl = Template.instance()
    return tpl.allow_confirm_rev.get() and not tpl.is_merging_rev.get()

Template.merge_justdo_confirm.events
  "keydown .confirm-merge-box": (e, tpl) ->
    if e.keyCode == 13 # Enter
      $(e.target).blur()
      tpl.$(".confirm-merge-button").click()
      return false

    return true 

  "keyup .confirm-merge-box": (e, tpl) ->
    tpl.allow_confirm_rev.set(e.target.value.toLowerCase() == "confirm")

    return true
  
  "click .confirm-merge-button": (e, tpl) ->
    tpl.is_merging_rev.set true
    src_justdo_id = JD.activeJustdo()._id
    Meteor.call "jdCustomMergeJustdo", tpl.data.target_justdo_id, src_justdo_id, (err, container_task_id) ->
      if err?
        alert "Merge failed! #{err.message}"
        console.error err
        return
      
      window.location.href = "/p/#{tpl.data.target_justdo_id}#&t=main&p=/#{container_task_id}/"
      
      bootbox.hideAll()

      Meteor.call "removeProject", src_justdo_id

    return false
