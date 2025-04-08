_.extend JustdoAccounts.prototype,
  editUserAvatarColor: (user_id, cb) ->
    performing_user_id = Meteor.userId()

    APP.projects.ensureUsersPublicBasicUsersInfoLoaded user_id, (err) =>
      if err?
        cb? err
        return

      if not JustdoAvatar.isAvatarNotSetOrBase64Svg(user_id)
        cb? @_error "not-supported", "Cannot override user uploaded avatar."
        return

      user_doc = Meteor.users.findOne(user_id)

      message_template =
        APP.helpers.renderTemplateInNewNode(Template.loginDropdownEditAvatarColorsBootboxMessage, {user_doc})

      bootbox.dialog
        title: TAPi18n.__ "logged_in_dropdown_avatar_colors_editors"
        message: message_template.node
        animate: false
        className: "avatars-colors-editor bootbox-new-design"

        onEscape: ->
          return true

        buttons:
          cancel:
            label: TAPi18n.__ "cancel"

            className: "btn-light"

            callback: ->
              return true

          submit:
            label: TAPi18n.__ "save"
            callback: =>
              avatar_bg = $(".bg-color-picker input").val()
              avatar_fg = $(".fg-color-picker input").val()

              # If user is editing its own avatar colors, update the user doc directly
              if performing_user_id is user_id
                new_avatar = JustdoAvatar.getInitialsSvg JustdoHelpers.getUserMainEmail(user_doc), user_doc.profile.first_name, user_doc.profile.last_name, {avatar_bg, avatar_fg}
                Meteor.users.update(user_id, {$set: {"profile.avatar_bg": avatar_bg, "profile.avatar_fg": avatar_fg, "profile.profile_pic": new_avatar}})
                cb?()
              else
                Meteor.call "editUserAvatarColor", avatar_bg, avatar_fg, user_id, cb

              return true

      return

    return

Template.loginDropdownEditAvatarColorsBootboxMessage.onCreated ->
  @color_picker_ready = new ReactiveVar false
  @color_picker = null

  module.dynamicImport('meteor/justdoinc:justdo-color-picker').then (m) =>
    @color_picker = m.ColorPicker

    @color_picker_ready.set true

    return

Template.loginDropdownEditAvatarColorsBootboxMessage.helpers
  isPickerReady: ->
    return Template.instance().color_picker_ready.get()

Template.loginDropdownEditAvatarColorsBootboxEditor.onCreated ->
  # Find current avatar's initials colors
  {avatar_bg, avatar_fg} = JustdoAvatar.extractColorsFromBase64Svg @data.user_doc.profile.profile_pic

  @avatar_bg = new ReactiveVar avatar_bg
  @avatar_fg = new ReactiveVar avatar_fg

  return


Template.loginDropdownEditAvatarColorsBootboxEditor.onRendered ->
  tpl = Template.instance()
  parent_tpl = Template.closestInstance "loginDropdownEditAvatarColorsBootboxMessage"

  ColorPicker = parent_tpl.color_picker


  avatar_bg = tpl.avatar_bg.get()
  avatar_fg = tpl.avatar_fg.get()

  palettes = [
    "#D1F2A5", "#EFFAB4", "#FFC48C", "#FF9F80", "#F56991",
    "#ffffff", "#ECD078", "#D95B43", "#C02942", "#542437", "#53777A",
    "#000000", "#774F38", "#E08E79", "#F1D4AF", "#ECE5CE", "#C5E0DC",
    '#646fff', '#fffa1d', '#ffa21f', '#ff391d'
    ]

  new ColorPicker $(".bg-color-picker").get(0),
    color: avatar_bg
    palettes: palettes
    onUpdate: (rgb) ->
      tpl.avatar_bg.set(ColorPicker.prototype.RGBtoHEX.apply(ColorPicker.prototype, rgb))

  new ColorPicker $(".fg-color-picker").get(0),
    color: avatar_fg
    palettes: palettes
    onUpdate: (rgb) ->
      tpl.avatar_fg.set(ColorPicker.prototype.RGBtoHEX.apply(ColorPicker.prototype, rgb))

Template.loginDropdownEditAvatarColorsBootboxEditor.helpers
  profileWithPickedColors: ->
    tpl = Template.instance()

    user_doc = @user_doc

    # Avoid affecting real doc
    user_doc.profile = _.extend({}, user_doc.profile)

    user_doc.profile.avatar_fg = tpl.avatar_fg.get()
    user_doc.profile.avatar_bg = tpl.avatar_bg.get()

    delete user_doc.profile.profile_pic

    return user_doc