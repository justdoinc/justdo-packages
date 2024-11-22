_.extend JustdoSiteAdmins,
  task_pane_tab_label: "Site Admins"

  custom_page_label: "Site Admins"

  modules: {}

  default_site_admin_page_view: "members"

  view_name_to_title_and_template_name: new ReactiveDict()

  site_admins_server_vitals_page_refresh_interval: 1000 * 15 # 15 seconds

  installation_id_system_record_key: "installtion-id"