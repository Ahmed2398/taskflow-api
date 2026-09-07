#!/bin/bash

echo "=== Phase 4: Users & Teams Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"

echo "Step 1: Register two users"
echo "----------------------------"

# Register first user
echo -e "${YELLOW}Registering test@test.com...${NC}"
RESPONSE1=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123","name":"Test User"}')

if echo "$RESPONSE1" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 1 registered successfully${NC}"
  TOKEN1=$(echo $RESPONSE1 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 1 registration failed${NC}"
  echo "$RESPONSE1"
fi

# Register second user
echo -e "${YELLOW}Registering friend@test.com...${NC}"
RESPONSE2=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"friend@test.com","password":"password123","name":"Friend User"}')

if echo "$RESPONSE2" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 2 registered successfully${NC}"
  TOKEN2=$(echo $RESPONSE2 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 2 registration failed${NC}"
  echo "$RESPONSE2"
fi

echo ""
echo "Step 2: Create a team as User 1 (becomes OWNER)"
echo "------------------------------------------------"

TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"My Awesome Team"}')

if echo "$TEAM_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ Team created successfully${NC}"
  TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Team ID: $TEAM_ID"
else
  echo -e "${RED}✗ Team creation failed${NC}"
  echo "$TEAM_RESPONSE"
fi

echo ""
echo "Step 3: Get User 1's teams"
echo "--------------------------"

MY_TEAMS=$(curl -s -X GET $BASE_URL/teams/mine \
  -H "Authorization: Bearer $TOKEN1")

echo "$MY_TEAMS" | head -20

echo ""
echo "Step 4: Add User 2 to the team as MEMBER"
echo "-----------------------------------------"

ADD_MEMBER=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"email":"friend@test.com"}')

if echo "$ADD_MEMBER" | grep -q "id"; then
  echo -e "${GREEN}✓ Member added successfully${NC}"
else
  echo -e "${RED}✗ Failed to add member${NC}"
  echo "$ADD_MEMBER"
fi

echo ""
echo "Step 5: List team members"
echo "-------------------------"

MEMBERS=$(curl -s -X GET $BASE_URL/teams/$TEAM_ID/members \
  -H "Authorization: Bearer $TOKEN1")

echo "$MEMBERS" | head -30

echo ""
echo "Step 6: Test RolesGuard - User 2 (MEMBER) tries to add another member"
echo "----------------------------------------------------------------------"

FORBIDDEN_TEST=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"email":"another@test.com"}')

if echo "$FORBIDDEN_TEST" | grep -q "403\|Forbidden\|Insufficient permissions"; then
  echo -e "${GREEN}✓ RolesGuard working correctly - 403 Forbidden received${NC}"
else
  echo -e "${RED}✗ RolesGuard not working - should have received 403${NC}"
  echo "$FORBIDDEN_TEST"
fi

echo ""
echo "=== Testing Complete ==="
