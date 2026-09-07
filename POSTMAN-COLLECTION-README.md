# 📮 Postman Collection Created!

## Files Created

✅ **TaskFlow-API.postman_collection.json** - Complete API collection
✅ **TaskFlow-API.postman_environment.json** - Environment with variables
✅ **POSTMAN-GUIDE.md** - Detailed usage guide

## Quick Import

### In Postman:
1. Click **Import** button (top left)
2. Drag & drop both JSON files
3. Select **TaskFlow Local** environment (top right dropdown)
4. Start testing! 🚀

## Smart Features

### 🔄 Auto-Save Tokens
Login/Register automatically saves `accessToken` and `refreshToken` to environment

### 🆔 Auto-Save IDs
Create Team automatically saves `teamId` for subsequent requests

### 🔐 Bearer Auth
All protected endpoints use `{{accessToken}}` variable automatically

### 📝 Pre-configured Variables
- `baseUrl`: http://localhost:3000
- `userEmail`: test@test.com
- `userPassword`: password123
- `teamName`: My Awesome Team
- `memberEmail`: friend@test.com

## Current Endpoints (Phase 4)

### Authentication (3 endpoints)
- Register User
- Login
- Get Current User

### Teams (5 endpoints)
- Create Team
- Get My Teams
- Get Team Members
- Add Team Member (OWNER/ADMIN only)
- Remove Team Member (OWNER/ADMIN only)

## Testing Flow

```
1. Register User → Token saved automatically
2. Create Team → Team ID saved automatically
3. Get My Teams → See your team
4. Add Member → Invite others
5. Get Members → View team roster
```

## Memory Tracking

✅ Collection saved to memory
✅ Will auto-update when new endpoints are added
✅ Tracks all API changes across phases

## Next Steps

1. Import files into Postman
2. Run "Register User" request
3. Run "Create Team" request
4. Test other endpoints
5. See POSTMAN-GUIDE.md for advanced usage

---

**Note:** This collection will be automatically updated as new features are added in future phases (Projects, Boards, Tasks, etc.)
