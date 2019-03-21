share.store_db.plugins.push
  id: "meetings"
  title: "Meetings"
  short_description: "Plan and manage meetings"
  full_description: """
    In many organizations one of the biggest challenges is handling meetings. Starting with collecting and disseminating meeting notes and all the way to following on action items decided in a meeting.<br><br>
    With JustDo’s Meetings plugin:<br><br>
    <ul>
      <li>Every meeting starts with setting up a specific agenda and discussion topics from the list of Tasks in your JustDo.</li>
      <li>Once the agenda is set and published, every meeting participant can prepare for the meeting, take private notes as reminders to bring up during the meeting and add action items that are associated to specific agenda points. All action items are automatically added as JustDo tasks.</li>
      <li>During the meeting, meeting notes can be captured and associated with agenda items. Here you can record what was decided, who said what etc. At the same time, if action items are identified you can easily spawn new tasks to reflect them. These tasks will be internally associated with the meeting information.</li>
      <li>Once the meeting is concluded, you can share the meeting notes by email, hardcopy or any other way with the meeting participants and other stakeholders.</li>
    </ul>
    Later on:<br><br>
    <ul>
      <li>You will be able get back to any meeting to see what was discussed there.</li>
      <li>All the action items that were identified before or during the meetings will be part of JustDo and will benefit from all other features of the system.</li>
      <li>For every task that was part of one or more meetings agenda - you will be able to quickly tap into the relevant meeting notes information.</li>
    </ul>
  """
  categories: ["justdo-labs"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/meetings/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"

  package_name: "justdoinc:meetings-manager"
  package_project_custom_feature_id: "meetings_module"
  isPluginEnabledForEnvironment: -> true

  slider: []