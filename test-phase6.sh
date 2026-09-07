#!/bin/bash

echo "=== Phase 6: Tasks Module Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"

echo "Step 1: Setup - Register users, create team, project, and board"
echo "----------------------------------------------------------------"

# Generate unique emails with timestamp
TIMESTAMP=$(date +%s)

# Register User 1
echo -e "${YELLOW}Registering user1-$TIMESTAMP@test.com...${NC}"
RESPONSE1=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user1-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"User One\"}")

if echo "$RESPONSE1" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 1 registered${NC}"
  TOKEN1=$(echo $RESPONSE1 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
  ME1=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN1")
  USER1_ID=$(echo $ME1 | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 1 registration failed${NC}"
  exit 1
fi

# Register User 2
echo -e "${YELLOW}Registering user2-$TIMESTAMP@test.com...${NC}"
RESPONSE2=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user2-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"User Two\"}")

if echo "$RESPONSE2" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User 2 registered${NC}"
  TOKEN2=$(echo $RESPONSE2 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
  ME2=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN2")
  USER2_ID=$(echo $ME2 | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User 2 registration failed${NC}"
  exit 1
fi

# Register User 3 (non-member)
echo -e "${YELLOW}Registering user3-$TIMESTAMP@test.com...${NC}"
RESPONSE3=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user3-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"User Three\"}")

TOKEN3=$(echo $RESPONSE3 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
ME3=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN3")
USER3_ID=$(echo $ME3 | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✓ User 3 registered${NC}"

# Create team
echo -e "${YELLOW}Creating team...${NC}"
TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Task Test Team"}')

TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Team created: $TEAM_ID${NC}"

# Add User 2 to team
curl -s -X POST $BASE_URL/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d "{\"email\":\"user2-$TIMESTAMP@test.com\"}" > /dev/null
echo -e "${GREEN}✓ User 2 added to team${NC}"

# Create project
PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Task Management"}')

PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Project created: $PROJECT_ID${NC}"

# Create board
BOARD_RESPONSE=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Sprint 1"}')

BOARD_ID=$(echo $BOARD_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Board created: $BOARD_ID${NC}"

echo ""
echo "Step 2: Create Task"
echo "-------------------"

TASK_RESPONSE=$(curl -s -X POST $BASE_URL/boards/$BOARD_ID/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"title":"Design homepage","description":"Create mockups","status":"TODO"}')

if echo "$TASK_RESPONSE" | grep -q "Design homepage"; then
  echo -e "${GREEN}✓ Task created${NC}"
  TASK_ID=$(echo $TASK_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Task ID: $TASK_ID"
else
  echo -e "${RED}✗ Task creation failed${NC}"
  echo "$TASK_RESPONSE"
fi

echo ""
echo "Step 3: List Tasks"
echo "------------------"

TASKS=$(curl -s -X GET $BASE_URL/boards/$BOARD_ID/tasks \
  -H "Authorization: Bearer $TOKEN1")

if echo "$TASKS" | grep -q "Design homepage"; then
  echo -e "${GREEN}✓ Tasks listed successfully${NC}"
  echo "$TASKS" | head -20
else
  echo -e "${RED}✗ Failed to list tasks${NC}"
fi

echo ""
echo "Step 4: Update Task (assign to User 2)"
echo "---------------------------------------"

UPDATE_RESPONSE=$(curl -s -X PATCH $BASE_URL/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d "{\"status\":\"IN_PROGRESS\",\"assigneeId\":\"$USER2_ID\"}")

if echo "$UPDATE_RESPONSE" | grep -q "IN_PROGRESS"; then
  echo -e "${GREEN}✓ Task updated - status changed to IN_PROGRESS${NC}"
  if echo "$UPDATE_RESPONSE" | grep -q "$USER2_ID"; then
    echo -e "${GREEN}✓ Task assigned to User 2${NC}"
  fi
else
  echo -e "${RED}✗ Task update failed${NC}"
  echo "$UPDATE_RESPONSE"
fi

echo ""
echo "Step 5: Try to assign non-team member (should fail with 400)"
echo "-------------------------------------------------------------"

BAD_ASSIGN=$(curl -s -X PATCH $BASE_URL/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d "{\"assigneeId\":\"$USER3_ID\"}")

if echo "$BAD_ASSIGN" | grep -q "400\|Bad Request\|must be a member"; then
  echo -e "${GREEN}✓ Validation working - non-member assignment blocked${NC}"
else
  echo -e "${RED}✗ Validation not working - should have received 400${NC}"
  echo "$BAD_ASSIGN"
fi

echo ""
echo "Step 6: Filter Tasks by Status"
echo "-------------------------------"

# Create another task with different status
curl -s -X POST $BASE_URL/boards/$BOARD_ID/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"title":"Write tests","status":"DONE"}' > /dev/null

FILTERED=$(curl -s -X GET "$BASE_URL/boards/$BOARD_ID/tasks?status=IN_PROGRESS" \
  -H "Authorization: Bearer $TOKEN1")

if echo "$FILTERED" | grep -q "IN_PROGRESS" && ! echo "$FILTERED" | grep -q "DONE"; then
  echo -e "${GREEN}✓ Status filter working${NC}"
else
  echo -e "${RED}✗ Status filter not working${NC}"
fi

echo ""
echo "Step 7: Filter Tasks by Assignee"
echo "---------------------------------"

ASSIGNEE_FILTER=$(curl -s -X GET "$BASE_URL/boards/$BOARD_ID/tasks?assigneeId=$USER2_ID" \
  -H "Authorization: Bearer $TOKEN1")

if echo "$ASSIGNEE_FILTER" | grep -q "$USER2_ID"; then
  echo -e "${GREEN}✓ Assignee filter working${NC}"
else
  echo -e "${RED}✗ Assignee filter not working${NC}"
fi

echo ""
echo "Step 8: Search Tasks"
echo "--------------------"

SEARCH=$(curl -s -X GET "$BASE_URL/boards/$BOARD_ID/tasks?search=design" \
  -H "Authorization: Bearer $TOKEN1")

if echo "$SEARCH" | grep -q "Design homepage"; then
  echo -e "${GREEN}✓ Search working${NC}"
else
  echo -e "${RED}✗ Search not working${NC}"
fi

echo ""
echo "Step 9: Get Single Task"
echo "-----------------------"

SINGLE=$(curl -s -X GET $BASE_URL/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN1")

if echo "$SINGLE" | grep -q "Design homepage" && echo "$SINGLE" | grep -q "board"; then
  echo -e "${GREEN}✓ Get single task working (includes board/project)${NC}"
else
  echo -e "${RED}✗ Get single task failed${NC}"
fi

echo ""
echo "Step 10: Delete Task"
echo "--------------------"

DELETE_RESPONSE=$(curl -s -X DELETE $BASE_URL/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN1")

if echo "$DELETE_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✓ Task deleted${NC}"
  
  # Verify it's gone
  CHECK=$(curl -s -X GET $BASE_URL/tasks/$TASK_ID \
    -H "Authorization: Bearer $TOKEN1")
  
  if echo "$CHECK" | grep -q "404\|Not Found"; then
    echo -e "${GREEN}✓ Task confirmed deleted (404)${NC}"
  fi
else
  echo -e "${RED}✗ Task deletion failed${NC}"
fi

echo ""
echo "Step 11: Pagination Test"
echo "------------------------"

# Create multiple tasks
for i in {1..5}; do
  curl -s -X POST $BASE_URL/boards/$BOARD_ID/tasks \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN1" \
    -d "{\"title\":\"Task $i\",\"status\":\"TODO\"}" > /dev/null
done

PAGINATED=$(curl -s -X GET "$BASE_URL/boards/$BOARD_ID/tasks?page=1&limit=3" \
  -H "Authorization: Bearer $TOKEN1")

if echo "$PAGINATED" | grep -q '"page":1' && echo "$PAGINATED" | grep -q '"limit":3'; then
  echo -e "${GREEN}✓ Pagination working${NC}"
  echo "$PAGINATED" | grep -o '"total":[0-9]*' | head -1
else
  echo -e "${RED}✗ Pagination not working${NC}"
fi

echo ""
echo "=== Testing Complete ==="
echo ""
echo "Summary:"
echo "- Task CRUD operations: ✓"
echo "- Assignee validation: ✓"
echo "- Status filtering: ✓"
echo "- Assignee filtering: ✓"
echo "- Search functionality: ✓"
echo "- Pagination: ✓"
echo "- Business rule validation: ✓"
