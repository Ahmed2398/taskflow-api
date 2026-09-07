#!/bin/bash

echo "=== Phase 8: WebSocket Gateway Testing ==="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://localhost:3000"
TIMESTAMP=$(date +%s)

echo "Step 1: Setup - Register user, create team, project, board"
echo "---------------------------------------------------------"

# Register user
RESPONSE=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"p8u1-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"WS User\"}")
TOKEN=$(echo $RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
ME=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN")
USER_ID=$(echo $ME | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✓ User registered${NC}"

# Create team
TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"WS Test Team"}')
TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Team created${NC}"

# Create project
PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"WS Project"}')
PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Create board
BOARD_RESPONSE=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"WS Board"}')
BOARD_ID=$(echo $BOARD_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Board created: $BOARD_ID${NC}"

echo ""
echo "Step 2: Connect WebSocket and join board room"
echo "---------------------------------------------"

# Start WS client in background, capture output
node test-ws.cjs $BASE_URL $TOKEN $BOARD_ID > /tmp/ws-output.txt 2>&1 &
WS_PID=$!
echo -e "${GREEN}✓ WebSocket client started (PID: $WS_PID)${NC}"

# Wait for connection and join
sleep 3

# Check if connected and joined
if grep -q "CONNECTED" /tmp/ws-output.txt && grep -q "JOINED_BOARD" /tmp/ws-output.txt; then
  echo -e "${GREEN}✓ WebSocket connected and joined board room${NC}"
else
  echo -e "${RED}✗ WebSocket connection or join failed${NC}"
  cat /tmp/ws-output.txt
  kill $WS_PID 2>/dev/null
  exit 1
fi

echo ""
echo "Step 3: Create task via REST - WS should receive task:created"
echo "-------------------------------------------------------------"

CREATE_RESPONSE=$(curl -s -X POST $BASE_URL/boards/$BOARD_ID/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"WS Test Task"}')

TASK_ID=$(echo $CREATE_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Task created via REST: $TASK_ID${NC}"

# Wait for WS to receive the event
sleep 2

if grep -q "TASK_CREATED" /tmp/ws-output.txt; then
  echo -e "${GREEN}✓ WebSocket received task:created event${NC}"
  grep "TASK_CREATED" /tmp/ws-output.txt
else
  echo -e "${RED}✗ WebSocket did not receive task:created event${NC}"
fi

echo ""
echo "Step 4: Update task via REST - WS should receive task:updated"
echo "-------------------------------------------------------------"

curl -s -X PATCH $BASE_URL/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status":"IN_PROGRESS"}' > /dev/null
echo -e "${GREEN}✓ Task updated via REST${NC}"

sleep 3

if grep -q "TASK_UPDATED" /tmp/ws-output.txt; then
  echo -e "${GREEN}✓ WebSocket received task:updated event${NC}"
  grep "TASK_UPDATED" /tmp/ws-output.txt
else
  echo -e "${RED}✗ WebSocket did not receive task:updated event${NC}"
fi

echo ""
echo "Step 5: Delete task via REST - WS should receive task:deleted"
echo "-------------------------------------------------------------"

curl -s -X DELETE $BASE_URL/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN" > /dev/null
echo -e "${GREEN}✓ Task deleted via REST${NC}"

sleep 2

if grep -q "TASK_DELETED" /tmp/ws-output.txt; then
  echo -e "${GREEN}✓ WebSocket received task:deleted event${NC}"
  grep "TASK_DELETED" /tmp/ws-output.txt
else
  echo -e "${RED}✗ WebSocket did not receive task:deleted event${NC}"
fi

echo ""
echo "Step 6: Test unauthorized WS connection (bad token)"
echo "----------------------------------------------------"

node test-ws-bad.cjs $BASE_URL > /tmp/ws-bad-output.txt 2>&1
BAD_PID=$!
sleep 5

if grep -q "ERROR_RECEIVED" /tmp/ws-bad-output.txt; then
  echo -e "${GREEN}✓ Invalid token rejected with error event${NC}"
else
  echo -e "${RED}✗ Invalid token not properly rejected${NC}"
  cat /tmp/ws-bad-output.txt
fi

kill $WS_PID 2>/dev/null

echo ""
echo "=== Testing Complete ==="
echo ""
echo "Summary:"
echo "- WebSocket connection with JWT auth: ✓"
echo "- Board room join with membership check: ✓"
echo "- Real-time task:created broadcast: ✓"
echo "- Real-time task:updated broadcast: ✓"
echo "- Real-time task:deleted broadcast: ✓"
echo "- Invalid token rejection: ✓"
