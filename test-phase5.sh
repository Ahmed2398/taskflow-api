#!/bin/bash

echo "=== Phase 5: Projects & Boards Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"

echo "Step 1: Setup - Register users and create team"
echo "-----------------------------------------------"

# Register User 1
echo -e "${YELLOW}Registering user1@test.com...${NC}"
RESPONSE1=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user1@test.com","password":"password123","name":"User One"}')

if echo "$RESPONSE1" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 1 registered${NC}"
  TOKEN1=$(echo $RESPONSE1 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 1 registration failed${NC}"
  echo "$RESPONSE1"
fi

# Register User 2
echo -e "${YELLOW}Registering user2@test.com...${NC}"
RESPONSE2=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user2@test.com","password":"password123","name":"User Two"}')

if echo "$RESPONSE2" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 2 registered${NC}"
  TOKEN2=$(echo $RESPONSE2 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 2 registration failed${NC}"
  echo "$RESPONSE2"
fi

# Register User 3 (non-member)
echo -e "${YELLOW}Registering user3@test.com...${NC}"
RESPONSE3=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user3@test.com","password":"password123","name":"User Three"}')

if echo "$RESPONSE3" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 3 registered${NC}"
  TOKEN3=$(echo $RESPONSE3 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 3 registration failed${NC}"
  echo "$RESPONSE3"
fi

# Create team
echo -e "${YELLOW}Creating team...${NC}"
TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Development Team"}')

if echo "$TEAM_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ Team created${NC}"
  TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Team ID: $TEAM_ID"
else
  echo -e "${RED}✗ Team creation failed${NC}"
  echo "$TEAM_RESPONSE"
fi

# Add User 2 as MEMBER
echo -e "${YELLOW}Adding User 2 to team...${NC}"
ADD_MEMBER=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"email":"user2@test.com"}')

if echo "$ADD_MEMBER" | grep -q "id"; then
  echo -e "${GREEN}✓ User 2 added to team${NC}"
else
  echo -e "${RED}✗ Failed to add User 2${NC}"
  echo "$ADD_MEMBER"
fi

echo ""
echo "Step 2: Create Project (User 1 - OWNER)"
echo "----------------------------------------"

PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Website Redesign"}')

if echo "$PROJECT_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ Project created${NC}"
  PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Project ID: $PROJECT_ID"
else
  echo -e "${RED}✗ Project creation failed${NC}"
  echo "$PROJECT_RESPONSE"
fi

echo ""
echo "Step 3: List Team Projects"
echo "--------------------------"

PROJECTS=$(curl -s -X GET $BASE_URL/teams/$TEAM_ID/projects \
  -H "Authorization: Bearer $TOKEN1")

if echo "$PROJECTS" | grep -q "Website Redesign"; then
  echo -e "${GREEN}✓ Projects listed successfully${NC}"
  echo "$PROJECTS" | head -20
else
  echo -e "${RED}✗ Failed to list projects${NC}"
  echo "$PROJECTS"
fi

echo ""
echo "Step 4: Create Board (User 1)"
echo "-----------------------------"

BOARD_RESPONSE=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Sprint 1"}')

if echo "$BOARD_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ Board created${NC}"
  BOARD_ID=$(echo $BOARD_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Board ID: $BOARD_ID"
else
  echo -e "${RED}✗ Board creation failed${NC}"
  echo "$BOARD_RESPONSE"
fi

echo ""
echo "Step 5: List Project Boards"
echo "---------------------------"

BOARDS=$(curl -s -X GET $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Authorization: Bearer $TOKEN1")

if echo "$BOARDS" | grep -q "Sprint 1"; then
  echo -e "${GREEN}✓ Boards listed successfully${NC}"
  echo "$BOARDS" | head -20
else
  echo -e "${RED}✗ Failed to list boards${NC}"
  echo "$BOARDS"
fi

echo ""
echo "Step 6: User 2 (MEMBER) creates board - Should succeed"
echo "-------------------------------------------------------"

BOARD2_RESPONSE=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"name":"Sprint 2"}')

if echo "$BOARD2_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ User 2 (MEMBER) can create board${NC}"
else
  echo -e "${RED}✗ User 2 failed to create board${NC}"
  echo "$BOARD2_RESPONSE"
fi

echo ""
echo "Step 7: User 3 (NON-MEMBER) creates project - Should fail with 403"
echo "-------------------------------------------------------------------"

PROJECT_FORBIDDEN=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN3" \
  -d '{"name":"Unauthorized Project"}')

if echo "$PROJECT_FORBIDDEN" | grep -q "403\|Forbidden\|not a member"; then
  echo -e "${GREEN}✓ TeamMemberGuard working - 403 Forbidden received${NC}"
else
  echo -e "${RED}✗ TeamMemberGuard not working - should have received 403${NC}"
  echo "$PROJECT_FORBIDDEN"
fi

echo ""
echo "Step 8: User 3 (NON-MEMBER) creates board - Should fail with 403"
echo "-----------------------------------------------------------------"

BOARD_FORBIDDEN=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN3" \
  -d '{"name":"Unauthorized Board"}')

if echo "$BOARD_FORBIDDEN" | grep -q "403\|Forbidden\|not a member"; then
  echo -e "${GREEN}✓ Service-level check working - 403 Forbidden received${NC}"
else
  echo -e "${RED}✗ Service-level check not working - should have received 403${NC}"
  echo "$BOARD_FORBIDDEN"
fi

echo ""
echo "=== Testing Complete ==="
echo ""
echo "Summary:"
echo "- Projects nested under teams: /teams/:teamId/projects"
echo "- Boards nested under projects: /projects/:projectId/boards"
echo "- TeamMemberGuard protects project endpoints"
echo "- Service-level check protects board endpoints"
echo "- Both guard-based and service-based authorization working"
