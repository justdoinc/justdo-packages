share.store_db.plugins.push
  id: "task-copy"
  title: "Task Copy"
  short_description: "Copy a set of tasks",
  full_description: """
    With this plugin you can create Templates in JustDo and/or copy a set of tasks.<br><br>
    In many cases, there are certain workflows that occur regularly, during the day to day operation of an organization. A few examples of such workflows include order processing, legal documents drafting, approval & execution, events, customer service requests, etc.  These workflows are usually based on a number of predefined action items (tasks), that should be executed.<br><br>
    Now, rather than manually entering the same list of tasks every time the workflow has to be accomplished, you can copy an entire section of JustDo (a subtree) and use it as a template for your workflow.<br><br>
    This saves time, allows the sharing of best practice, and is a good method to makes sure colleagues follow the same workflow and steps when carrying out certain activities.<br><br>
    See <a href="https://www.youtube.com/watch?v=gIty__rKWOc&feature=youtu.be" target="_blank">this video</a> to learn how to enable and use this feature.
  """
  categories: ["featured", "misc"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/task-copy/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"
  
  package_name: "justdoinc:justdo-item-duplicate-control"
  package_project_custom_feature_id: "justdo-item-duplicate-control"
  isPluginEnabledForEnvironment: -> true

  slider: [
    """
      <iframe width="100%" height="400" src="https://www.youtube.com/embed/gIty__rKWOc?ecver=1" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
    """
  ]
