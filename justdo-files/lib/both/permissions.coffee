APP.justdo_permissions.registerPermissionsCategory "justdo-files",
  default_task_permissions_value: {condition: "all"}
  default_justdo_permissions_value: {condition: "all"}

APP.justdo_permissions.registerTaskPermission "justdo-files.remove-file-by-non-uploader",
  label: "Remove a file by users other than the one uploaded it"
  description: """
    Controls the ability to remove a file by users other than the one uploaded it.
  """

APP.justdo_permissions.registerTaskPermission "justdo-files.rename-file-by-non-uploader",
  label: "Rename a file by users other than the one uploaded it"
  description: """
    Controls the ability to rename a file by users other than the one uploaded it.
  """