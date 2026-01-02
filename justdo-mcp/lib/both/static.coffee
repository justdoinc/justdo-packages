_.extend JustdoMcp,
  plugin_human_readable_name: "justdo-mcp"

  api_version: "1.0.0"
  
  # MCP protocol version we implement
  mcp_protocol_version: "2024-11-05"

  # Tool categories for organization
  tool_categories:
    justdo: "JustDo/Board Operations"
    task: "Task Operations"
    user: "User Operations"

  # Tool definitions - these are the tools exposed via MCP
  # Each tool has:
  #   - name: unique identifier
  #   - description: human-readable description
  #   - category: one of tool_categories keys
  #   - input_schema: JSON Schema for the tool's input
  #   - required_permission: optional permission string required to use the tool
  tool_definitions:
    # JustDo/Board tools
    "list_justdos":
      name: "list_justdos"
      description: "List all JustDos (boards) the user has access to"
      category: "justdo"
      input_schema:
        type: "object"
        properties: {}
        required: []
    
    "get_justdo":
      name: "get_justdo"
      description: "Get details of a specific JustDo (board)"
      category: "justdo"
      input_schema:
        type: "object"
        properties:
          justdo_id:
            type: "string"
            description: "The ID of the JustDo to retrieve"
        required: ["justdo_id"]

    # Task tools
    "list_tasks":
      name: "list_tasks"
      description: "List tasks in a JustDo, optionally filtered"
      category: "task"
      input_schema:
        type: "object"
        properties:
          justdo_id:
            type: "string"
            description: "The ID of the JustDo to list tasks from"
          owner_id:
            type: "string"
            description: "Optional: Filter tasks by owner ID"
          state:
            type: "string"
            enum: ["nil", "pending", "in-progress", "done", "on-hold"]
            description: "Optional: Filter tasks by state"
          limit:
            type: "integer"
            description: "Maximum number of tasks to return (default: 50)"
            default: 50
        required: ["justdo_id"]

    "get_task":
      name: "get_task"
      description: "Get details of a specific task"
      category: "task"
      input_schema:
        type: "object"
        properties:
          task_id:
            type: "string"
            description: "The ID of the task to retrieve"
        required: ["task_id"]

    "create_task":
      name: "create_task"
      description: "Create a new task in a JustDo"
      category: "task"
      required_permission: "task.add-task"
      input_schema:
        type: "object"
        properties:
          justdo_id:
            type: "string"
            description: "The ID of the JustDo to create the task in"
          title:
            type: "string"
            description: "The title of the task"
          parent_id:
            type: "string"
            description: "Optional: The ID of the parent task (for subtasks)"
          owner_id:
            type: "string"
            description: "Optional: The ID of the user to assign as owner"
          due_date:
            type: "string"
            format: "date"
            description: "Optional: Due date in YYYY-MM-DD format"
          priority:
            type: "string"
            enum: ["low", "medium", "high", "critical"]
            description: "Optional: Priority level"
        required: ["justdo_id", "title"]

    "update_task":
      name: "update_task"
      description: "Update an existing task"
      category: "task"
      input_schema:
        type: "object"
        properties:
          task_id:
            type: "string"
            description: "The ID of the task to update"
          title:
            type: "string"
            description: "New title for the task"
          state:
            type: "string"
            enum: ["nil", "pending", "in-progress", "done", "on-hold"]
            description: "New state for the task"
          owner_id:
            type: "string"
            description: "New owner ID for the task"
          due_date:
            type: "string"
            format: "date"
            description: "New due date in YYYY-MM-DD format"
          priority:
            type: "string"
            enum: ["low", "medium", "high", "critical"]
            description: "New priority level"
        required: ["task_id"]

    # User tools
    "get_current_user":
      name: "get_current_user"
      description: "Get information about the currently authenticated user"
      category: "user"
      input_schema:
        type: "object"
        properties: {}
        required: []

    "list_justdo_members":
      name: "list_justdo_members"
      description: "List all members of a JustDo"
      category: "justdo"
      input_schema:
        type: "object"
        properties:
          justdo_id:
            type: "string"
            description: "The ID of the JustDo to list members for"
        required: ["justdo_id"]
