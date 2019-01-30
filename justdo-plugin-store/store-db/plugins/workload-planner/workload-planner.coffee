share.store_db.plugins.push
  id: "workload-planner"
  title: "Workload Planner"
  short_description: "Manage tasks by terms",
  full_description: """
    With the Workload Planner enabled, you can mark tasks that are set to be accomplished in the Short-Term, Mid-Term or Long-Term. So for example, from a backlog of tasks, you can choose which ones should be executed 'soon' (whatever 'soon' means for you - few days, a couple of weeks or more), and mark those tasks as 'Short-Term'. Once you categorize tasks this way, a Plan by Term view can be selected, grouping tasks by members and terms, and you will be able to see what's planned for the short term, mid-term, long term or unassigned).<br><br>
    In conjunction with the Resource Management plugin, you will also be able to see how much time is planned and how much of the work was already executed per member.<br><br>
    Once the information is presented, you can verify if every team member has the right amount of work on his plate - not too little and not to much - and set him/her up for success. If needed, you'll be able to move tasks around and transfer them between JustDo members. If you identify that too much work is set for the term, you can reassign tasks from short-term to mid-term (for example) or vice versa.<br><br>
    See <a href="https://drive.google.com/file/d/1MAxA4QaoaTNHSuGw_NTb1NkE6F8Qi96w/view" target="_blank">this video</a> to learn how to enable and use this feature, and <a href="https://drive.google.com/file/d/1JzPnIVWUoBi8BGmpgFRJLLzFV-nRIDLy/view" target="_blank">this video</a> to see how the workload planner is working in conjunction with the resource management module.
  """
  categories: ["featured", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/workload-planner/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"
  
  package_name: "justdoinc:justdo-workload-planner"
  package_project_custom_feature_id: "justdo_workload_planner"
  isPluginEnabledForEnvironment: -> true

  slider: [
    """
      <iframe width="100%" height="400" src="https://drive.google.com/file/d/1MAxA4QaoaTNHSuGw_NTb1NkE6F8Qi96w/preview" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
    """
  ]
