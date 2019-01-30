share.store_db.plugins.push
  id: "maildo"
  title: "MailDo"
  short_description: "Send emails to JustDo to create/update tasks"
  full_description: """
    MailDo is one of our most popular plugins. With MailDo, you, your team members, clients or vendors can send or forward emails straight into any task in JustDo. At your choice such emails can be attached to the task for further and future reference, or if selected so, to spawn new task(s).<br><br>
    Some popular usages of MailDo are:<br>
    <ul>
      <li>In HR department advertise an email address for candidates to send their CVs to. With any new candidate a new task is created, emails attachments (such as CVs) become file attachments in JustDo.</li>
      <li>In CRM systems - advertise a 'complaints' email address to your clients. Each email sent to this address will spawn a task for your team to respond to.</li>
      <li>When sending critical business communications to clients or vendors (quotes, orders, etc), CC (or BCC) the relevant task to keep a record of the email that was sent.</li>
    </ul>
  """
  categories: ["featured", "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/maildo/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"

  package_name: "justdoinc:justdo-inbound-emails"
  package_project_custom_feature_id: "justdo_inbound_emails"
  isPluginEnabledForEnvironment: -> env.INBOUND_EMAILS_ENABLED is "true"

  slider: []