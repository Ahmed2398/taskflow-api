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

# 4. List team members
curl -X GET http://localhost:3000/teams/$TEAM_ID/members \
  -H "Authorization: Bearer $TOKEN1"

# 5. Bob tries to add someone (should fail with 403)
curl -X POST http://localhost:3000/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"email":"charlie@test.com"}'
```
