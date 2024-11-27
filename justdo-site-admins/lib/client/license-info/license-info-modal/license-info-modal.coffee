Template.license_info_modal.helpers
  isUserSiteAdmin: -> APP.justdo_site_admins.isUserSiteAdmin Meteor.user()
  isExpiring: -> Template.instance().data?.is_expiring
  isExpired: -> Template.instance().data?.is_expired
  getLicense: -> LICENSE_RV?.get()
  getShutdownDate: -> APP.justdo_site_admins.getShutdownDate()
  getLicensedUsersCount: -> 
    if LICENSE_RV?.get().unlimited_users
      return "unlimited"
    
    return LICENSE_RV?.get().licensed_users
  formatDate: (date) -> moment(date, "YYYY-MM-DD").format JustdoHelpers.getUserPreferredDateFormat()