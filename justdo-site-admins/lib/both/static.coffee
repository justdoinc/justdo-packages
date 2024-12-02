_.extend JustdoSiteAdmins,
  task_pane_tab_label: "Site Admins"

  custom_page_label: "Site Admins"

  modules: {}

  default_site_admin_page_view: "members"

  view_name_to_title_and_template_name: new ReactiveDict()

  # Here we use a friendly reminder (in yellow) only for admins
  license_expire_headsup_day_for_site_admins: 30
  
  # Here we use a more bold reminder (in red) for all users
  license_expire_headsup_day_for_non_site_admins: 7
  
  site_admins_server_vitals_page_refresh_interval: 1000 * 15 # 15 seconds

  installation_id_system_record_key: "installtion-id"

  renew_license_endpoint: "/renew-license"

  renew_license_fallback_endpoint: "/contact"

  # Server vitals logging
  # The server vitals are logged every log_server_vitals_interval minutes,
  # and the logs will be removed after server_vital_logs_ttl milliseconds.
  # For every long_term_server_vitals_ratio logs, the logs will be kept forever.
  log_server_vitals_interval: 1000 * 60 * 5 # 5 minutes
  long_term_server_vitals_ratio: 96 # 96 * 5 minutes = 8 hours
  server_vital_logs_ttl: 1000 * 60 * 60 * 24 * 14 # 14 days