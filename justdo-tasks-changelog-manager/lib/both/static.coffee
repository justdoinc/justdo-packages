_.extend TasksChangelogManager,
  # If a field is changed by the same user within hide_changelog_threshold, don't display that log.
  hide_changelog_threshold: 2 # In minutes
  ops_involve_another_task: ["moved_to_task", "add_parent", "remove_parent"]
  not_undoable_ops: ["moved_to_task"]
