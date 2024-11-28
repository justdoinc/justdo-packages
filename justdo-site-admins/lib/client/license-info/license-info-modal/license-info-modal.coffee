Template.license_info_modal.helpers
  isUserSiteAdmin: -> APP.justdo_site_admins.isUserSiteAdmin Meteor.user()
  isExpiring: -> Template.instance().data?.is_expiring
  isExpired: -> Template.instance().data?.is_expired
  getLicense: -> APP.justdo_site_admins.getLicense().license
  getShutdownDate: -> APP.justdo_site_admins.getShutdownDate()
  getLicensedUsersCount: -> 
    if (license = APP.justdo_site_admins.getLicense().license)?.unlimited_users
      return "unlimited"
    
    return license.licensed_users
  formatDate: (date) -> moment(date, "YYYY-MM-DD").format JustdoHelpers.getUserPreferredDateFormat()