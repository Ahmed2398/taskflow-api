# TaskFlow API - Postman Collection Guide

## 📦 Files

- **TaskFlow-API.postman_collection.json** - Complete API collection with all endpoints
- **TaskFlow-API.postman_environment.json** - Environment variables for local development

## 🚀 Quick Start

### 1. Import into Postman

**Import Collection:**
1. Open Postman
2. Click "Import" button (top left)
3. Select `TaskFlow-API.postman_collection.json`
4. Collection will appear in your sidebar

**Import Environment:**
1. Click "Import" button
2. Select `TaskFlow-API.postman_environment.json`
3. Select "TaskFlow Local" from environment dropdown (top right)

### 2. Test the API

**Recommended Testing Flow:**

1. **Register User** (Authentication folder)
   - Automatically saves `accessToken` and `refreshToken`
   - Edit variables in request body if needed

2. **Create Team** (Teams folder)
   - Uses saved `accessToken` automatically
   - Automatically saves `teamId`

3. **Get My Teams** (Teams folder)
   - See your newly created team

4. **Add Team Member** (Teams folder)
   - Change `memberEmail` variable to add different users
   - Requires OWNER or ADMIN role

5. **Get Team Members** (Teams folder)
   - View all team members with roles

## 🔧 Environment Variables

### Auto-Populated (by test scripts)
- `accessToken` - JWT access token (15min expiry)
- `refreshToken` - JWT refresh token (7 day expiry)
- `teamId` - Last created team ID

### Configurable
- `baseUrl` - API base URL (default: http://localhost:3000)
- `userEmail` - Email for registration/login
- `userPassword` - Password for registration/login
- `userName` - Display name for registration
- `teamName` - Name for new teams
- `memberEmail` - Email of user to add to team
- `memberUserId` - User ID for removing members

## 📝 Request Features

### Automatic Token Management
Login and Register requests automatically save tokens to environment:
```javascript
// Test script in Login/Register
if (response.accessToken) {
    pm.environment.set('accessToken', response.accessToken);
    pm.environment.set('refreshToken', response.refreshToken);
}
```

### Automatic ID Capture
Create Team request automatically saves team ID:
```javascript
// Test script in Create Team
if (response.id) {
    pm.environment.set('teamId', response.id);
}
```

### Bearer Token Authentication
All protected endpoints use `{{accessToken}}` variable automatically.

## 📚 API Endpoints

### Authentication
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | /auth/register | Register new user | No |
| POST | /auth/login | Login user | No |
| GET | /auth/me | Get current user | Yes |

### Teams
| Method | Endpoint | Description | Auth Required | Role Required |
|--------|----------|-------------|---------------|---------------|
| POST | /teams | Create team | Yes | - |
| GET | /teams/mine | Get user's teams | Yes | - |
| GET | /teams/:teamId/members | List members | Yes | - |
| POST | /teams/:teamId/members | Add member | Yes | OWNER/ADMIN |
| DELETE | /teams/:teamId/members/:userId | Remove member | Yes | OWNER/ADMIN |

## 🎯 Testing Scenarios

### Scenario 1: Basic Team Creation
1. Register User → saves token
2. Create Team → saves teamId
3. Get My Teams → verify team exists

### Scenario 2: Team Collaboration
1. Register User 1 → save as `accessToken`
2. Create Team → save `teamId`
3. Register User 2 → note their email
4. Switch back to User 1's token
5. Add Team Member (User 2's email)
6. Get Team Members → verify both users

### Scenario 3: Role-Based Access (403 Test)
1. Register User 1 (becomes OWNER)
2. Create Team
3. Register User 2
4. User 1 adds User 2 as MEMBER
5. Switch to User 2's token
6. Try to add another member → Should get 403 Forbidden

## 🔐 Team Roles

- **OWNER** - Full control, can manage all members
- **ADMIN** - Can add/remove members
- **MEMBER** - Basic access, cannot manage members

## 🐛 Troubleshooting

### Token Expired (401)
- Run Login request again to get fresh tokens
- Access tokens expire after 15 minutes

### Forbidden (403)
- Check your role in the team
- Only OWNER/ADMIN can add/remove members

### Team Not Found (404)
- Verify `teamId` variable is set
- Run "Create Team" to generate new team

### User Already in Team (409)
- Member already exists in this team
- Use different email or remove first

## 💡 Tips

1. **Use Collection Runner** for automated testing
2. **Duplicate requests** to test with different users
3. **Save responses** as examples for documentation
4. **Use Pre-request Scripts** for complex test setups
5. **Monitor Console** to see auto-saved variables

## 🔄 Future Updates

This collection will be automatically updated when new endpoints are added:
- Projects module
- Boards module
- Tasks module
- Comments module
- Attachments module

Check the collection version and re-import if updates are available.

## 📞 Support

If you encounter issues:
1. Check server is running: `npm run start:dev`
2. Verify environment is selected in Postman
3. Check console for error messages
4. Review API-REFERENCE.md for endpoint details
