# JustDo MCP (Model Context Protocol) API

This package exposes REST API endpoints for MCP clients (AI agents, Microsoft Copilot, etc.) to interact with JustDo.

## Overview

The MCP API provides:
- **Authentication** via Bearer tokens (Meteor login tokens) or API keys
- **Tool discovery** endpoint for clients to discover available operations
- **Tool execution** endpoint for performing operations on JustDos and tasks

## API Endpoints

All endpoints are available at `/api/mcp/v1/`.

### GET /api/mcp/v1/info

Returns server information (no authentication required).

**Response:**
```json
{
  "name": "JustDo MCP Server",
  "version": "1.0.0",
  "mcp_protocol_version": "2024-11-05",
  "capabilities": {
    "tools": true,
    "resources": false,
    "prompts": false
  }
}
```

### GET /api/mcp/v1/capabilities

Returns available tools for the authenticated user.

**Headers:**
- `Authorization: Bearer <login_token>` (required)

**Response:**
```json
{
  "user_id": "abc123",
  "tools": [
    {
      "name": "list_justdos",
      "description": "List all JustDos (boards) the user has access to",
      "category": "justdo",
      "input_schema": { ... }
    },
    ...
  ]
}
```

### POST /api/mcp/v1/tools/list

MCP-compliant tools list endpoint.

**Headers:**
- `Authorization: Bearer <login_token>` (required)

**Response:**
```json
{
  "tools": [
    {
      "name": "list_justdos",
      "description": "List all JustDos (boards) the user has access to",
      "inputSchema": { ... }
    },
    ...
  ]
}
```

### POST /api/mcp/v1/tools/call

MCP-compliant tool execution endpoint.

**Headers:**
- `Authorization: Bearer <login_token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "name": "list_tasks",
  "arguments": {
    "justdo_id": "abc123",
    "limit": 10
  }
}
```

**Response (success):**
```json
{
  "content": [
    {
      "type": "text",
      "text": "{ ... JSON result ... }"
    }
  ],
  "isError": false
}
```

**Response (error):**
```json
{
  "content": [
    {
      "type": "text",
      "text": "Error message"
    }
  ],
  "isError": true
}
```

### POST /api/mcp/v1/execute

Legacy execute endpoint (alternative to MCP format).

**Headers:**
- `Authorization: Bearer <login_token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "tool": "list_tasks",
  "input": {
    "justdo_id": "abc123"
  }
}
```

**Response:**
```json
{
  "success": true,
  "result": { ... }
}
```

## Available Tools

### JustDo Operations

#### list_justdos
List all JustDos (boards) the user has access to.

**Input:** None

**Output:**
```json
{
  "justdos": [
    {
      "id": "abc123",
      "title": "My Project",
      "created_at": "2024-01-01T00:00:00Z",
      "member_count": 5
    }
  ]
}
```

#### get_justdo
Get details of a specific JustDo.

**Input:**
- `justdo_id` (required): The ID of the JustDo

**Output:**
```json
{
  "id": "abc123",
  "title": "My Project",
  "created_at": "2024-01-01T00:00:00Z",
  "member_count": 5,
  "members": [
    {
      "user_id": "user123",
      "is_admin": true
    }
  ]
}
```

#### list_justdo_members
List all members of a JustDo.

**Input:**
- `justdo_id` (required): The ID of the JustDo

**Output:**
```json
{
  "justdo_id": "abc123",
  "members": [
    {
      "user_id": "user123",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "is_admin": true
    }
  ]
}
```

### Task Operations

#### list_tasks
List tasks in a JustDo.

**Input:**
- `justdo_id` (required): The ID of the JustDo
- `owner_id` (optional): Filter by owner
- `state` (optional): Filter by state (nil, pending, in-progress, done, on-hold)
- `limit` (optional): Maximum results (default: 50, max: 200)

**Output:**
```json
{
  "tasks": [
    {
      "id": "task123",
      "seq_id": 42,
      "title": "Complete task",
      "state": "in-progress",
      "owner_id": "user123",
      "due_date": "2024-12-31T00:00:00Z",
      "priority": "high",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### get_task
Get details of a specific task.

**Input:**
- `task_id` (required): The ID of the task

**Output:**
```json
{
  "id": "task123",
  "seq_id": 42,
  "justdo_id": "abc123",
  "title": "Complete task",
  "description": "Task details...",
  "state": "in-progress",
  "owner_id": "user123",
  "due_date": "2024-12-31T00:00:00Z",
  "start_date": "2024-01-01T00:00:00Z",
  "follow_up": null,
  "priority": "high",
  "created_at": "2024-01-01T00:00:00Z",
  "parent_ids": ["parent123"]
}
```

#### create_task
Create a new task.

**Input:**
- `justdo_id` (required): The ID of the JustDo
- `title` (required): Task title
- `parent_id` (optional): Parent task ID (for subtasks)
- `owner_id` (optional): Owner user ID
- `due_date` (optional): Due date (YYYY-MM-DD)
- `priority` (optional): low, medium, high, critical

**Output:**
```json
{
  "success": true,
  "task_id": "new_task_id",
  "message": "Task created successfully"
}
```

#### update_task
Update an existing task.

**Input:**
- `task_id` (required): The ID of the task
- `title` (optional): New title
- `state` (optional): New state
- `owner_id` (optional): New owner
- `due_date` (optional): New due date
- `priority` (optional): New priority

**Output:**
```json
{
  "success": true,
  "task_id": "task123",
  "message": "Task updated successfully"
}
```

### User Operations

#### get_current_user
Get information about the authenticated user.

**Input:** None

**Output:**
```json
{
  "id": "user123",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "created_at": "2024-01-01T00:00:00Z"
}
```

## Authentication

### Using Bearer Token (Recommended)

Use the Meteor login token as a Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_LOGIN_TOKEN" \
     https://your-justdo-instance.com/api/mcp/v1/capabilities
```

### Using API Key

Alternatively, use the X-API-Key header:

```bash
curl -H "X-API-Key: YOUR_API_KEY" \
     https://your-justdo-instance.com/api/mcp/v1/capabilities
```

### Getting a Login Token

A login token can be obtained by:
1. Logging in through the web app and extracting the `meteor_login_token` cookie
2. Using the Meteor DDP `login` method programmatically
3. (Future) Using OAuth 2.0 token exchange

## Integration with MCP Clients

### Using with Microsoft Copilot

To integrate with Microsoft Copilot:

1. Configure your MCP server to connect to the JustDo MCP API endpoints
2. Use OAuth 2.0 authentication (configure token exchange endpoint)
3. The MCP server will discover available tools via `/api/mcp/v1/tools/list`
4. Tool calls will be executed via `/api/mcp/v1/tools/call`

### Building a Standalone MCP Server

Example structure for a standalone MCP server (Phase 2):

```javascript
import { Server } from "@modelcontextprotocol/sdk/server";

const server = new Server({
  name: "justdo-mcp-server",
  version: "1.0.0"
});

// Fetch tools from JustDo
server.setRequestHandler("tools/list", async () => {
  const response = await fetch(`${JUSTDO_URL}/api/mcp/v1/tools/list`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${userToken}` }
  });
  return response.json();
});

// Execute tools on JustDo
server.setRequestHandler("tools/call", async (request) => {
  const response = await fetch(`${JUSTDO_URL}/api/mcp/v1/tools/call`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${userToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      name: request.params.name,
      arguments: request.params.arguments
    })
  });
  return response.json();
});
```

## Configuration

The MCP API is enabled by default. Configuration options:

- `api_base_path`: Base path for API endpoints (default: `/api/mcp/v1`)

## Security Considerations

1. **All endpoints require authentication** except `/info`
2. **Permission checks** are enforced at the tool execution level
3. **Rate limiting** should be configured at the infrastructure level
4. **CORS** headers should be configured appropriately for cross-origin requests
5. **HTTPS** should be enforced in production

## Extending with New Tools

To add new tools:

1. Add the tool definition to `JustdoMcp.tool_definitions` in `static.coffee`
2. Add the tool implementation as `_tool<ToolName>` method in `server/api.coffee`
3. Add the case to the `executeTool` switch statement

