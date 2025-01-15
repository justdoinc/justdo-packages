APP.justdo_tooltips.registerTooltip
  id: "add-new-member-dialog-info"
  template: "add_new_member_dialog_info"

APP.justdo_tooltips.registerTooltip
  id: "add-new-member-dialog-info-no-proxy"
  template: "add_new_member_dialog_info_no_proxy"

Template.add_new_member_dialog_info.helpers
  isSdkBuild: -> APP.justdo_site_admins.getLicense()?.license?.is_sdk is true