Template.drawer_license_info.helpers
  licensedUntil: -> LICENSE_RV?.get()?.expire_on
  isExpiringTextClass: ->
    is_expiring_for_all = APP.justdo_site_admins.isLicenseExpiring false
    is_expiring_for_site_admins = APP.justdo_site_admins.isLicenseExpiring true
    if is_expiring_for_all
      return "text-danger"
    
    if is_expiring_for_site_admins and APP.justdo_site_admins.isCurrentUserSiteAdmin()
      return "text-warning"
    
    return
  
  isExpiringInDays: ->
    if APP.justdo_site_admins.isLicenseExpiring()
      return moment(LICENSE_RV.get().expire_on, "YYYY-MM-DD").fromNow()
    return
Template.drawer_license_info.events
  "click .drawer-license-info": -> APP.justdo_site_admins.showLicenseExpirationReminder()