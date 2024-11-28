Template.drawer_license_info.helpers
  licensedUntil: -> APP.justdo_site_admins.getLicense().license?.expire_on
  isExpiringTextClass: ->
    is_expiring_for_all = APP.justdo_site_admins.isLicenseExpiring false
    is_expiring_for_site_admins = APP.justdo_site_admins.isLicenseExpiring true
    if is_expiring_for_all
      return "text-danger"
    
    if is_expiring_for_site_admins and APP.justdo_site_admins.isCurrentUserSiteAdmin()
      return "text-warning"
    
    return
  
  isExpired: -> APP.justdo_site_admins.isLicenseExpired()
  
  isExpiringInDays: ->
    if APP.justdo_site_admins.isLicenseExpiring()
      license = APP.justdo_site_admins.getLicense().license
      return moment(license.expire_on, "YYYY-MM-DD").fromNow()
    return
Template.drawer_license_info.events
  "click .drawer-license-info": -> APP.justdo_site_admins.showLicenseExpirationReminder()