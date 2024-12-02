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
  # The server vitals are logged every log_server_vitals_interval_ms minutes,
  # and the logs will be removed after server_vital_logs_ttl milliseconds.
  # For every long_term_server_vitals_ratio_ms logs, the logs will be kept forever.
  log_server_vitals_interval_ms: 1000 * 60 * 5 # 5 minutes
  server_vital_logs_ttl: 14 # 14 days  long_term_server_vitals_ratio: 96 # Every 96th log will be marked as long_term
