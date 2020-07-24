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

        close:
          label: "Close"

          className: "btn-primary"

          callback: ->
            return true

Template.merge_justdo_dialog.onCreated ->
  tpl = @

  tpl.justdos_filter_text_rev = new ReactiveVar ""
  tpl.justdos_selected_rev = new ReactiveDict()

  tpl.confirmMerge = ->
    selected_justdo_ids = []
    for justdo_id, is_selected of tpl.justdos_selected_rev.all()
      if is_selected
        selected_justdo_ids.push justdo_id

    if selected_justdo_ids.length == 0
      alert "Please select at least one justdo to be merged."
      return false
      
    merge_justdo_confirm_tpl =
      JustdoHelpers.renderTemplateInNewNode Template.merge_justdo_confirm, 
        justdo_ids: selected_justdo_ids
        enable_extensions: tpl.$("#enable-extensions").prop "checked"

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
          label: "Close"

          className: "btn-primary"

          callback: ->
            return true

    return false

  return

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

    return JustdoHelpers.filterJustosDocsArray justdos, Template.instance().justdos_filter_text_rev.get()
    
  justdoSelected: (justdo) ->
    return Template.instance().justdos_selected_rev.get(justdo._id) == true

Template.merge_justdo_dialog.events
  "keyup .justdos-selector-search": (e, tpl) ->
    tpl.justdos_filter_text_rev.set $(e.target).val()
    return true
  
  "click .justdos-filter-justdo-item": (e, tpl) ->
    justdo_id = $(e.currentTarget).data "justdo-id"
    justdo_selected = Template.instance().justdos_selected_rev.get(justdo_id) == true
    tpl.justdos_selected_rev.set justdo_id, !justdo_selected

    return true

Template.merge_justdo_confirm.onCreated ->
  tpl = @
  tpl.allow_confirm_rev = new ReactiveVar false
  tpl.is_merging_rev = new ReactiveVar false

  tpl.autorun ->
    tpl.data.justdos = APP.collections.Projects.find
      _id:
        $in: tpl.data.justdo_ids
    ,
      fields:
        _id: 1
        title: 1
    .fetch()
  
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
    Meteor.call "jdCustomMergeJustdo", tpl.data.justdo_ids, JD.activeJustdo()._id, (err, result) ->
      if err?
        alert "Merge failed!"
        console.error err
        return

      Meteor.call "removeJustdos", tpl.data.justdo_ids, (err) ->
        if err? 
          alert "Merge failed!"
          cosnole.error err
          return

        tpl.is_merging_rev.set false
        bootbox.hideAll()

        return

    return false
    


  
