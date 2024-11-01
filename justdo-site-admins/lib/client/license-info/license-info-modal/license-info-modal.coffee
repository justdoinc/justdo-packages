Template.license_info_modal.helpers
  isUserSiteAdmin: -> APP.justdo_site_admins.isUserSiteAdmin Meteor.user()
  isExpiring: -> Template.instance().data?.is_expiring
  getLicense: -> LICENSE_RV?.get()
  getLicensedUsersCount: -> 
    if LICENSE_RV?.get().unlimited_users
      return "unlimited"
    
    return LICENSE_RV?.get().licensed_users
  formatDate: (date) -> moment(date, "YYYY-MM-DD").format JustdoHelpers.getUserPreferredDateFormat()