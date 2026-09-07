# TaskFlow API Reference

## Base URL

```
http://localhost:3000
```

## Authentication

### Register

```bash
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}

Response: { "accessToken": "...", "refreshToken": "..." }
```

### Login

```bash
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response: { "accessToken": "...", "refreshToken": "..." }
```

### Get Current User

```bash
GET /auth/me
Authorization: Bearer <accessToken>

Response: { "userId": "...", "email": "..." }
```

## Teams

### Create Team

```bash
POST /teams
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "name": "My Team"
}

Response: {
  "id": "...",
  "name": "My Team",
  "createdAt": "...",
  "members": [...]
}
```

### Get My Teams

```bash
GET /teams/mine
Authorization: Bearer <accessToken>

Response: [
  {
    "id": "...",
    "name": "My Team",
    "createdAt": "...",
    "members": [...]
  }
]
```

### Get Team Members

```bash
GET /teams/:teamId/members
Authorization: Bearer <accessToken>

Response: [
  {
    "id": "...",
    "role": "OWNER",
    "joinedAt": "...",
    "user": {
      "id": "...",
      "name": "John Doe",
      "email": "user@example.com"
    }
  }
]
```

### Add Team Member

```bash
POST /teams/:teamId/members
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: OWNER or ADMIN role

{
  "email": "friend@example.com",
  "role": "MEMBER"  // optional, defaults to MEMBER
}

Response: {
  "id": "...",
  "userId": "...",
  "teamId": "...",
  "role": "MEMBER",
  "joinedAt": "..."
}
```

### Remove Team Member

```bash
DELETE /teams/:teamId/members/:memberUserId
Authorization: Bearer <accessToken>
Requires: OWNER or ADMIN role

Response: {
  "id": "...",
  "userId": "...",
  "teamId": "...",
  "role": "...",
  "joinedAt": "..."
}
```

## Team Roles

- **OWNER** - Full control, can add/remove members
- **ADMIN** - Can add/remove members
- **MEMBER** - Basic access, cannot manage members

## Projects

### Create Project

```bash
POST /teams/:teamId/projects
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: Team membership (any role)

{
  "name": "Website Redesign"
}

Response: {
  "id": "...",
  "name": "Website Redesign",
  "createdAt": "...",
  "teamId": "..."
}
```

### Get Team Projects

```bash
GET /teams/:teamId/projects
Authorization: Bearer <accessToken>
Requires: Team membership (any role)

Response: [
  {
    "id": "...",
    "name": "Website Redesign",
    "createdAt": "...",
    "teamId": "...",
    "boards": [...]
  }
]
```

## Boards

### Create Board

```bash
POST /projects/:projectId/boards
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: Membership in project's team (any role)

{
  "name": "Sprint 1"
}

Response: {
  "id": "...",
  "name": "Sprint 1",
  "createdAt": "...",
  "projectId": "..."
}
```

### Get Project Boards

```bash
GET /projects/:projectId/boards
Authorization: Bearer <accessToken>
Requires: Membership in project's team (any role)

Response: [
  {
    "id": "...",
    "name": "Sprint 1",
    "createdAt": "...",
    "projectId": "...",
    "tasks": [...]
  }
]
```

## Tasks

### Task Statuses

- `TODO`
- `IN_PROGRESS`
- `IN_REVIEW`
- `DONE`

### Create Task

```bash
POST /boards/:boardId/tasks
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: Membership in board's team (any role)
Validation: Assignee must be a team member

{
  "title": "Design homepage",
  "description": "Create mockups",
  "status": "TODO",
  "dueDate": "2026-12-31",
  "assigneeId": "user-id-here"
}

Response: {
  "id": "...",
  "title": "Design homepage",
  "description": "Create mockups",
  "status": "TODO",
  "dueDate": "...",
  "createdAt": "...",
  "updatedAt": "...",
  "boardId": "...",
  "assigneeId": "..."
}
```

### Get Board Tasks (with Search, Filters & Pagination)

```bash
GET /boards/:boardId/tasks?search=design&status=IN_PROGRESS&assigneeId=...&page=1&limit=10&sortBy=createdAt&sortOrder=desc
Authorization: Bearer <accessToken>
Requires: Membership in board's team (any role)

Query Parameters:
- search: Full-text search on title and description
- status: Filter by TaskStatus (TODO, IN_PROGRESS, IN_REVIEW, DONE)
- assigneeId: Filter by assignee user ID
- dueBefore: Filter tasks due before date (ISO string)
- dueAfter: Filter tasks due after date (ISO string)
- page: Page number (default: 1)
- limit: Items per page (default: 10, max: 100)
- sortBy: Field to sort by (default: createdAt)
- sortOrder: Sort direction: asc/desc (default: desc)

Response: {
  "data": [...],
  "meta": {
    "total": 45,
    "page": 1,
    "limit": 10,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

### Get Single Task

```bash
GET /tasks/:taskId
Authorization: Bearer <accessToken>
Requires: Membership in task's team (any role)

Response: {
  "id": "...",
  "title": "Design homepage",
  "description": "...",
  "status": "IN_PROGRESS",
  "board": { "id": "...", "project": { "teamId": "..." } },
  "assignee": { "id": "...", "name": "...", "email": "..." },
  "comments": [...]
}
```

### Update Task

```bash
PATCH /tasks/:taskId
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: Membership in task's team (any role)
Validation: Assignee must be a team member

{
  "status": "IN_PROGRESS",
  "assigneeId": "user-id-here"
}

Response: {
  "id": "...",
  "title": "Design homepage",
  "status": "IN_PROGRESS",
  "assigneeId": "..."
}
```

### Delete Task

```bash
DELETE /tasks/:taskId
Authorization: Bearer <accessToken>
Requires: Membership in task's team (any role)

Response: {
  "id": "...",
  "title": "Design homepage",
  "status": "..."
}
```

## Comments

### Create Comment

```bash
POST /tasks/:taskId/comments
Authorization: Bearer <accessToken>
Content-Type: application/json
Requires: Membership in task's team (any role)

{
  "content": "Looks good, ship it"
}

Response: {
  "id": "...",
  "content": "Looks good, ship it",
  "createdAt": "...",
  "taskId": "...",
  "authorId": "...",
  "author": { "id": "...", "name": "..." }
}
```

### Get Task Comments

```bash
GET /tasks/:taskId/comments
Authorization: Bearer <accessToken>
Requires: Membership in task's team (any role)

Response: [
  {
    "id": "...",
    "content": "Looks good, ship it",
    "createdAt": "...",
    "author": { "id": "...", "name": "..." }
  }
]
```

### Delete Comment

```bash
DELETE /comments/:commentId
Authorization: Bearer <accessToken>
Requires: Comment ownership (only author can delete)

Response: {
  "id": "...",
  "content": "..."
}
```

## Attachments

### Upload File Attachment

```bash
POST /tasks/:taskId/attachments
Authorization: Bearer <accessToken>
Content-Type: multipart/form-data
Requires: Membership in task's team (any role)
File limits: Max 5MB, allowed types: png, jpeg, jpg, pdf, docx

Body (form-data):
  file: <binary file data>

Response: {
  "id": "...",
  "fileName": "screenshot.png",
  "fileUrl": "/uploads/1234567890-abc.png",
  "createdAt": "...",
  "taskId": "..."
}
```

### Get Task Attachments

```bash
GET /tasks/:taskId/attachments
Authorization: Bearer <accessToken>
Requires: Membership in task's team (any role)

Response: [
  {
    "id": "...",
    "fileName": "screenshot.png",
    "fileUrl": "/uploads/1234567890-abc.png",
    "createdAt": "..."
  }
]
```

### Access Uploaded Files

```bash
GET /uploads/<filename>
```

Files are served statically at `http://localhost:3000/uploads/<filename>`

## WebSocket Events (Real-time)

The API supports real-time updates via Socket.io. Connect with JWT authentication and join board rooms to receive live task updates.

### Connection

```javascript
const socket = io('http://localhost:3000', {
  auth: { token: '<accessToken>' },
});
```

The token is verified on connection. Invalid tokens receive an `error` event and are disconnected.

### Client → Server Events

#### `board:join`

Join a board's room to receive real-time updates. Team membership is verified.

```javascript
socket.emit('board:join', { boardId: '<boardId>' });
```

Response: `board:joined` event with `{ boardId }`

#### `board:leave`

Leave a board's room.

```javascript
socket.emit('board:leave', { boardId: '<boardId>' });
```

### Server → Client Events

#### `task:created`

Emitted when a task is created on the board.

```json
{ "id": "...", "title": "...", "status": "TODO", "boardId": "..." }
```

#### `task:updated`

Emitted when a task is updated on the board.

```json
{ "id": "...", "title": "...", "status": "IN_PROGRESS", "boardId": "..." }
```

#### `task:deleted`

Emitted when a task is deleted from the board.

```json
{ "taskId": "..." }
```

#### `error`

Emitted on authentication failure or membership denial.

```json
"Unauthorized" | "Board not found" | "Not a member of this board's team"
```

### Architecture

- `TasksService` emits events via `EventEmitter2` (decoupled from the gateway)
- `BoardsGateway` listens for events and broadcasts to `board:<boardId>` rooms
- Clients must explicitly join a board room to receive updates
- JWT is verified on socket connection, team membership on room join

## Error Responses

### 400 Bad Request

```json
{
  "statusCode": 400,
  "message": ["email must be an email"],
  "error": "Bad Request"
}
```

### 401 Unauthorized

```json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

### 403 Forbidden

```json
{
  "statusCode": 403,
  "message": "Insufficient permissions for this team",
  "error": "Forbidden"
}
```

### 404 Not Found

```json
{
  "statusCode": 404,
  "message": "Team not found",
  "error": "Not Found"
}
```

### 409 Conflict

```json
{
  "statusCode": 409,
  "message": "Email already in use",
  "error": "Conflict"
}
```

## Example Workflow

```bash
# 1. Register two users
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@test.com","password":"pass123","name":"Alice"}'
# Save accessToken as TOKEN1

curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@test.com","password":"pass123","name":"Bob"}'
# Save accessToken as TOKEN2

# 2. Alice creates a team
curl -X POST http://localhost:3000/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Project Alpha"}'
# Save team id as TEAM_ID

# 3. Alice adds Bob to the team
curl -X POST http://localhost:3000/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"email":"bob@test.com"}'

# 4. Alice creates a project
curl -X POST http://localhost:3000/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Website Redesign"}'
# Save project id as PROJECT_ID

# 5. Bob creates a board (as team member)
curl -X POST http://localhost:3000/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"name":"Sprint 1"}'

# 6. List project boards
curl -X GET http://localhost:3000/projects/$PROJECT_ID/boards \
  -H "Authorization: Bearer $TOKEN1"

# 7. Bob tries to add a team member (should fail with 403 - needs OWNER/ADMIN)
curl -X POST http://localhost:3000/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"email":"charlie@test.com"}'
```
