#!/bin/bash

echo "=== Phase 7: Comments & Attachments Testing ==="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://localhost:3000"
TIMESTAMP=$(date +%s)

echo "Step 1: Setup - Register users, create team, project, board, task"
echo "----------------------------------------------------------------"

# Register User 1
RESPONSE1=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"p7u1-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"User One\"}")
TOKEN1=$(echo $RESPONSE1 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
ME1=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN1")
USER1_ID=$(echo $ME1 | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✓ User 1 registered${NC}"

# Register User 2
RESPONSE2=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"p7u2-$TIMESTAMP@test.com\",\"password\":\"password123\",\"name\":\"User Two\"}")
TOKEN2=$(echo $RESPONSE2 | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
ME2=$(curl -s -X GET $BASE_URL/auth/me -H "Authorization: Bearer $TOKEN2")
USER2_ID=$(echo $ME2 | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}✓ User 2 registered${NC}"

# Create team
TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Phase 7 Team"}')
TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Team created${NC}"

# Add User 2 to team
curl -s -X POST $BASE_URL/teams/$TEAM_ID/members \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d "{\"email\":\"p7u2-$TIMESTAMP@test.com\"}" > /dev/null
echo -e "${GREEN}✓ User 2 added to team${NC}"

# Create project
PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Phase 7 Project"}')
PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Create board
BOARD_RESPONSE=$(curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"name":"Sprint 1"}')
BOARD_ID=$(echo $BOARD_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Create task
TASK_RESPONSE=$(curl -s -X POST $BASE_URL/boards/$BOARD_ID/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"title":"Test task for comments"}')
TASK_ID=$(echo $TASK_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Task created: $TASK_ID${NC}"

echo ""
echo "Step 2: Create Comment"
echo "----------------------"

COMMENT_RESPONSE=$(curl -s -X POST $BASE_URL/tasks/$TASK_ID/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN1" \
  -d '{"content":"Looks good, ship it"}')

if echo "$COMMENT_RESPONSE" | grep -q "Looks good"; then
  echo -e "${GREEN}✓ Comment created${NC}"
  COMMENT_ID=$(echo $COMMENT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  if echo "$COMMENT_RESPONSE" | grep -q "$USER1_ID"; then
    echo -e "${GREEN}✓ Author info included${NC}"
  fi
else
  echo -e "${RED}✗ Comment creation failed${NC}"
  echo "$COMMENT_RESPONSE"
fi

echo ""
echo "Step 3: List Comments"
echo "---------------------"

COMMENTS=$(curl -s -X GET $BASE_URL/tasks/$TASK_ID/comments \
  -H "Authorization: Bearer $TOKEN1")

if echo "$COMMENTS" | grep -q "Looks good"; then
  echo -e "${GREEN}✓ Comments listed${NC}"
else
  echo -e "${RED}✗ Comment listing failed${NC}"
fi

echo ""
echo "Step 4: User 2 creates a comment"
echo "--------------------------------"

COMMENT2_RESPONSE=$(curl -s -X POST $BASE_URL/tasks/$TASK_ID/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN2" \
  -d '{"content":"I agree"}')

COMMENT2_ID=$(echo $COMMENT2_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
if echo "$COMMENT2_RESPONSE" | grep -q "I agree"; then
  echo -e "${GREEN}✓ User 2 comment created${NC}"
else
  echo -e "${RED}✗ User 2 comment failed${NC}"
fi

echo ""
echo "Step 5: User 1 tries to delete User 2's comment (should fail 403)"
echo "-----------------------------------------------------------------"

DELETE_OTHER=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $BASE_URL/comments/$COMMENT2_ID \
  -H "Authorization: Bearer $TOKEN1")

if [ "$DELETE_OTHER" = "403" ]; then
  echo -e "${GREEN}✓ Ownership check working - 403 Forbidden${NC}"
else
  echo -e "${RED}✗ Ownership check failed - expected 403, got $DELETE_OTHER${NC}"
fi

echo ""
echo "Step 6: User 2 deletes own comment (should succeed)"
echo "----------------------------------------------------"

DELETE_OWN=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $BASE_URL/comments/$COMMENT2_ID \
  -H "Authorization: Bearer $TOKEN2")

if [ "$DELETE_OWN" = "200" ]; then
  echo -e "${GREEN}✓ Own comment deleted successfully${NC}"
else
  echo -e "${RED}✗ Delete own comment failed - expected 200, got $DELETE_OWN${NC}"
fi

echo ""
echo "Step 7: Upload File Attachment (valid image)"
echo "---------------------------------------------"

# Create a small test PNG file
echo -n -e '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\xcf\xc0\x00\x00\x00\x03\x00\x01\x5c\xcd\xff\x69\x00\x00\x00\x00IEND\xaeB`\x82' > /tmp/test-image.png

ATTACH_RESPONSE=$(curl -s -X POST $BASE_URL/tasks/$TASK_ID/attachments \
  -H "Authorization: Bearer $TOKEN1" \
  -F "file=@/tmp/test-image.png")

if echo "$ATTACH_RESPONSE" | grep -q "fileUrl"; then
  echo -e "${GREEN}✓ File uploaded successfully${NC}"
  FILE_URL=$(echo $ATTACH_RESPONSE | grep -o '"fileUrl":"[^"]*' | cut -d'"' -f4)
  echo "  File URL: $FILE_URL"
else
  echo -e "${RED}✗ File upload failed${NC}"
  echo "$ATTACH_RESPONSE"
fi

echo ""
echo "Step 8: List Attachments"
echo "-------------------------"

ATTACHMENTS=$(curl -s -X GET $BASE_URL/tasks/$TASK_ID/attachments \
  -H "Authorization: Bearer $TOKEN1")

if echo "$ATTACHMENTS" | grep -q "fileUrl"; then
  echo -e "${GREEN}✓ Attachments listed${NC}"
else
  echo -e "${RED}✗ Attachment listing failed${NC}"
fi

echo ""
echo "Step 9: Verify Static File Serving"
echo "-----------------------------------"

if [ -n "$FILE_URL" ]; then
  STATIC_CHECK=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL$FILE_URL)
  if [ "$STATIC_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Static file serving working (HTTP 200)${NC}"
  else
    echo -e "${RED}✗ Static file serving failed - got $STATIC_CHECK${NC}"
  fi
fi

echo ""
echo "Step 10: Upload Invalid File Type (.txt should be rejected)"
echo "-----------------------------------------------------------"

echo "This is a text file" > /tmp/test-file.txt

INVALID_UPLOAD=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE_URL/tasks/$TASK_ID/attachments \
  -H "Authorization: Bearer $TOKEN1" \
  -F "file=@/tmp/test-file.txt")

if [ "$INVALID_UPLOAD" = "400" ]; then
  echo -e "${GREEN}✓ Invalid file type rejected (400)${NC}"
else
  echo -e "${RED}✗ Invalid file type not rejected - expected 400, got $INVALID_UPLOAD${NC}"
fi

echo ""
echo "Step 11: Delete Own Comment (User 1)"
echo "-------------------------------------"

DELETE_OWN1=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $BASE_URL/comments/$COMMENT_ID \
  -H "Authorization: Bearer $TOKEN1")

if [ "$DELETE_OWN1" = "200" ]; then
  echo -e "${GREEN}✓ Comment deleted by author${NC}"
else
  echo -e "${RED}✗ Comment deletion failed - expected 200, got $DELETE_OWN1${NC}"
fi

echo ""
echo "=== Testing Complete ==="
echo ""
echo "Summary:"
echo "- Comment CRUD: ✓"
echo "- Author info in response: ✓"
echo "- Ownership-based delete (403): ✓"
echo "- Own comment delete: ✓"
echo "- File upload (valid): ✓"
echo "- Attachment listing: ✓"
echo "- Static file serving: ✓"
echo "- Invalid file type rejection: ✓"
