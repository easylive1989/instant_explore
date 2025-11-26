#!/bin/bash

# Script to run Patrol E2E tests locally
# Usage: ./run_tests.sh [test_file]
#
# Examples:
#   ./run_tests.sh                          # Run all tests
#   ./run_tests.sh auth_flow_test.dart      # Run specific test

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Patrol E2E Test Runner${NC}"
echo ""

# Check if running from correct directory
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ Error: Please run this script from the frontend directory${NC}"
  exit 1
fi

# Check if Patrol CLI is installed
if ! command -v patrol &> /dev/null; then
  echo -e "${YELLOW}⚠️  Patrol CLI not found. Installing...${NC}"
  dart pub global activate patrol_cli
fi

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
  echo -e "${YELLOW}⚠️  Supabase CLI not found.${NC}"
  echo "Please install it:"
  echo "  macOS: brew install supabase/tap/supabase"
  echo "  Other: See https://supabase.com/docs/guides/cli"
  exit 1
fi

# Check if Supabase is running
if ! supabase status &> /dev/null; then
  echo -e "${YELLOW}⚠️  Local Supabase is not running. Starting...${NC}"

  # Initialize if needed
  if [ ! -f "supabase/config.toml" ]; then
    echo "Initializing Supabase..."
    supabase init
  fi

  # Start Supabase
  supabase start

  # Wait for it to be ready
  echo "Waiting for Supabase to start..."
  sleep 10
fi

# Get Supabase credentials
SUPABASE_URL="http://localhost:54321"
SUPABASE_ANON_KEY=$(supabase status -o json | jq -r '.anon_key')

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}❌ Failed to get Supabase anon key${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Local Supabase is running${NC}"
echo "   URL: $SUPABASE_URL"
echo ""

# Load environment variables from .env if it exists
if [ -f "../.env" ]; then
  echo -e "${GREEN}📄 Loading environment variables from .env${NC}"
  export $(cat ../.env | grep -v '^#' | xargs)
else
  echo -e "${YELLOW}⚠️  No .env file found. Some features may not work.${NC}"
  echo "   Create a .env file with your API keys:"
  echo "     GOOGLE_MAPS_API_KEY=your_key"
  echo "     GOOGLE_DIRECTIONS_API_KEY=your_key"
  echo "     GOOGLE_WEB_CLIENT_ID=your_client_id"
  echo ""
fi

# Determine which test to run
TEST_TARGET="integration_test"
if [ ! -z "$1" ]; then
  TEST_TARGET="integration_test/$1"
  echo -e "${GREEN}🎯 Running specific test: $1${NC}"
else
  echo -e "${GREEN}🎯 Running all tests${NC}"
fi
echo ""

# Build the patrol test command
PATROL_CMD="patrol test --target $TEST_TARGET"

# Add dart-defines
PATROL_CMD="$PATROL_CMD --dart-define=SUPABASE_URL=$SUPABASE_URL"
PATROL_CMD="$PATROL_CMD --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

if [ ! -z "$GOOGLE_MAPS_API_KEY" ]; then
  PATROL_CMD="$PATROL_CMD --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
fi

if [ ! -z "$GOOGLE_DIRECTIONS_API_KEY" ]; then
  PATROL_CMD="$PATROL_CMD --dart-define=GOOGLE_DIRECTIONS_API_KEY=$GOOGLE_DIRECTIONS_API_KEY"
fi

if [ ! -z "$GOOGLE_WEB_CLIENT_ID" ]; then
  PATROL_CMD="$PATROL_CMD --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID"
fi

if [ ! -z "$GOOGLE_IOS_CLIENT_ID" ]; then
  PATROL_CMD="$PATROL_CMD --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID"
fi

# Run the tests
echo -e "${GREEN}🚀 Starting tests...${NC}"
echo ""

if eval $PATROL_CMD; then
  echo ""
  echo -e "${GREEN}✅ Tests completed successfully!${NC}"

  # Show screenshots location if any
  if [ -d "build/app/outputs/patrol_screenshots" ]; then
    echo -e "${GREEN}📸 Screenshots saved to: build/app/outputs/patrol_screenshots/${NC}"
  fi

  exit 0
else
  echo ""
  echo -e "${RED}❌ Tests failed!${NC}"

  # Show screenshots location for debugging
  if [ -d "build/app/outputs/patrol_screenshots" ]; then
    echo -e "${YELLOW}📸 Check screenshots at: build/app/outputs/patrol_screenshots/${NC}"
  fi

  exit 1
fi