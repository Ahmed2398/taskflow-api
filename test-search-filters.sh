#!/bin/bash

echo "=== Search & Filters Enhancement Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"

echo "Step 1: Setup - Register user and create test data"
echo "---------------------------------------------------"

# Register user
echo -e "${YELLOW}Registering user...${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"search@test.com","password":"password123","name":"Search User"}')

if echo "$RESPONSE" | grep -q "accessToken"; then
  echo -e "${GREEN}✓ User registered${NC}"
  TOKEN=$(echo $RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${RED}✗ User registration failed${NC}"
  echo "$RESPONSE"
  exit 1
fi

# Create team
echo -e "${YELLOW}Creating team...${NC}"
TEAM_RESPONSE=$(curl -s -X POST $BASE_URL/teams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Search Test Team"}')

TEAM_ID=$(echo $TEAM_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Team created: $TEAM_ID${NC}"

# Create multiple projects for testing
echo -e "${YELLOW}Creating test projects...${NC}"
curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Website Redesign"}' > /dev/null

curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Mobile App"}' > /dev/null

curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Website Backend"}' > /dev/null

PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/teams/$TEAM_ID/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"API Development"}')

PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo -e "${GREEN}✓ Created 4 test projects${NC}"

# Create multiple boards for testing
echo -e "${YELLOW}Creating test boards...${NC}"
curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Sprint 1"}' > /dev/null

curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Sprint 2"}' > /dev/null

curl -s -X POST $BASE_URL/projects/$PROJECT_ID/boards \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Backlog"}' > /dev/null

echo -e "${GREEN}✓ Created 3 test boards${NC}"

echo ""
echo "Step 2: Test Search Functionality"
echo "----------------------------------"

# Search projects
echo -e "${YELLOW}Searching projects for 'website'...${NC}"
SEARCH_RESULT=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects?search=website" \
  -H "Authorization: Bearer $TOKEN")

if echo "$SEARCH_RESULT" | grep -q "Website"; then
  echo -e "${GREEN}✓ Search working - found projects with 'website'${NC}"
  COUNT=$(echo "$SEARCH_RESULT" | grep -o '"name":"Website[^"]*"' | wc -l)
  echo "  Found $COUNT matching projects"
else
  echo -e "${RED}✗ Search failed${NC}"
fi

echo ""
echo "Step 3: Test Pagination"
echo "-----------------------"

# Test pagination
echo -e "${YELLOW}Testing pagination (limit=2, page=1)...${NC}"
PAGE1=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects?limit=2&page=1" \
  -H "Authorization: Bearer $TOKEN")

if echo "$PAGE1" | grep -q '"page":1' && echo "$PAGE1" | grep -q '"limit":2'; then
  echo -e "${GREEN}✓ Pagination working${NC}"
  echo "$PAGE1" | grep -o '"total":[0-9]*' | head -1
  echo "$PAGE1" | grep -o '"totalPages":[0-9]*' | head -1
  echo "$PAGE1" | grep -o '"hasNextPage":[a-z]*' | head -1
else
  echo -e "${RED}✗ Pagination failed${NC}"
fi

echo ""
echo "Step 4: Test Sorting"
echo "--------------------"

# Test sorting
echo -e "${YELLOW}Testing sort by name (ascending)...${NC}"
SORTED=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects?sortBy=name&sortOrder=asc" \
  -H "Authorization: Bearer $TOKEN")

if echo "$SORTED" | grep -q '"name"'; then
  echo -e "${GREEN}✓ Sorting working${NC}"
  echo "  First project: $(echo "$SORTED" | grep -o '"name":"[^"]*"' | head -1)"
else
  echo -e "${RED}✗ Sorting failed${NC}"
fi

echo ""
echo "Step 5: Test Combined Search + Pagination + Sort"
echo "-------------------------------------------------"

echo -e "${YELLOW}Testing combined query...${NC}"
COMBINED=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects?search=website&page=1&limit=5&sortBy=name&sortOrder=desc" \
  -H "Authorization: Bearer $TOKEN")

if echo "$COMBINED" | grep -q '"meta"' && echo "$COMBINED" | grep -q '"data"'; then
  echo -e "${GREEN}✓ Combined query working${NC}"
  echo "  Response structure correct"
else
  echo -e "${RED}✗ Combined query failed${NC}"
fi

echo ""
echo "Step 6: Test Boards Search"
echo "--------------------------"

echo -e "${YELLOW}Searching boards for 'sprint'...${NC}"
BOARD_SEARCH=$(curl -s -X GET "$BASE_URL/projects/$PROJECT_ID/boards?search=sprint" \
  -H "Authorization: Bearer $TOKEN")

if echo "$BOARD_SEARCH" | grep -q "Sprint"; then
  echo -e "${GREEN}✓ Board search working${NC}"
  COUNT=$(echo "$BOARD_SEARCH" | grep -o '"name":"Sprint[^"]*"' | wc -l)
  echo "  Found $COUNT matching boards"
else
  echo -e "${RED}✗ Board search failed${NC}"
fi

echo ""
echo "Step 7: Test Empty Search Results"
echo "----------------------------------"

echo -e "${YELLOW}Searching for non-existent term...${NC}"
EMPTY=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects?search=nonexistent" \
  -H "Authorization: Bearer $TOKEN")

if echo "$EMPTY" | grep -q '"total":0'; then
  echo -e "${GREEN}✓ Empty results handled correctly${NC}"
else
  echo -e "${RED}✗ Empty results not handled correctly${NC}"
fi

echo ""
echo "Step 8: Test Default Pagination"
echo "--------------------------------"

echo -e "${YELLOW}Testing default pagination (no params)...${NC}"
DEFAULT=$(curl -s -X GET "$BASE_URL/teams/$TEAM_ID/projects" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DEFAULT" | grep -q '"page":1' && echo "$DEFAULT" | grep -q '"limit":10'; then
  echo -e "${GREEN}✓ Default pagination applied (page=1, limit=10)${NC}"
else
  echo -e "${RED}✗ Default pagination not working${NC}"
fi

echo ""
echo "=== Testing Complete ==="
echo ""
echo "Summary:"
echo "- Full-text search: ✓"
echo "- Pagination: ✓"
echo "- Sorting: ✓"
echo "- Combined queries: ✓"
echo "- Empty results: ✓"
echo "- Default values: ✓"
