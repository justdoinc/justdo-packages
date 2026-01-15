_.extend JustdoClipboardImport,
  project_custom_feature_id: "justdo_clipboard_import" # Use underscores

  plugin_human_readable_name: "clipboard_import_plugin_name"

  task_pane_tab_label: "justdo-clipboard-import"

  add_pseudo_field: false
  pseudo_field_id: "justdo_clipboard_import"
  pseudo_field_label: "justdo-clipboard-import"
  pseudo_field_type: "string"

  custom_page_label: "justdo-clipboard-import"

  import_limit: 10000

  # Special import fields used in column selectors for clipboard import
  special_import_fields:
    "clipboard-import-no-import":
      label: "-- skip column --"
      label_i18n: "clipboard_import_skip_column"
      _id: "clipboard-import-no-import"
    "clipboard-import-index":
      label: "Original Index (will not be imported)"
      label_i18n: "clipboard_import_index_column"
      _id: "clipboard-import-index"
    "task-indent-level":
      label: "Outline Level"
      label_i18n: "clipboard_import_indent_level"
      _id: "task-indent-level"

  # Import aliases for common field name variations
  # Keys are field IDs, values are arrays of alternative names that should match the field
  import_aliases:
    title: ["name", "subject", "task name", "task", "task title", "taskname"]
    description: ["notes", "note", "status", "comments", "comment", "details"]
    owner_id: ["owner", "assigned to", "assignee", "responsible"]
    start_date: ["start", "begin", "begin date", "start time", "planned start"]
    end_date: ["end", "finish", "end time", "finish date", "planned finish"]
    due_date: ["due", "deadline"]
    priority: ["priority", "importance"]
    state: ["state", "status"]
    status: ["% complete", "percent complete", "complete", "completion"]
    "task-indent-level": ["outline level", "level", "indent", "indent level", "wbs", "hierarchy level", "task level"]
    "clipboard-import-index": ["#", "id", "index", "row number", "row index", "original index"]
