#!/bin/bash
# =============================================================================
# Fluttron Web Package Acceptance Test Script (PRD §13)
# =============================================================================
#
# This script performs manual acceptance testing for the web package feature
# as defined in PRD §13 of docs/feature/fluttron_web_package_prd.md
#
# Prerequisites:
# - Flutter SDK installed and in PATH
# - Node.js and pnpm installed
# - Dart CLI globally activated: dart pub global activate --path packages/fluttron_cli
#
# Usage:
#   ./scripts/acceptance_test.sh [--cleanup]
#
# Options:
#   --cleanup    Remove test projects after completion
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="${PROJECT_ROOT}/.acceptance_test_tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cleanup=false
if [[ "$1" == "--cleanup" ]]; then
    cleanup=true
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Fluttron Web Package Acceptance Test${NC}"
echo -e "${BLUE}PRD §13 Verification Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Prerequisite checks
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter not found in PATH${NC}"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}ERROR: pnpm not found in PATH${NC}"
    exit 1
fi

if ! command -v dart &> /dev/null; then
    echo -e "${RED}ERROR: Dart not found in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites satisfied${NC}"
echo ""

# Prepare test directory
echo -e "${YELLOW}Preparing test environment...${NC}"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# =============================================================================
# PRD §13.1: Create Web Package
# =============================================================================
echo ""
echo -e "${BLUE}=== PRD §13.1: Create Web Package ===${NC}"
echo ""

echo -e "${YELLOW}Step 1: Creating web package with fluttron CLI...${NC}"
dart run "${PROJECT_ROOT}/packages/fluttron_cli/bin/fluttron.dart" create ./test_package --name test_package --type web_package

if [[ ! -d "test_package" ]]; then
    echo -e "${RED}FAILED: test_package directory not created${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Package directory created${NC}"

echo -e "${YELLOW}Step 2: Running pnpm install...${NC}"
cd test_package/frontend
pnpm install --silent
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo -e "${YELLOW}Step 3: Running pnpm run js:build...${NC}"
pnpm run js:build
if [[ ! -f "web/ext/main.js" ]]; then
    echo -e "${RED}FAILED: web/ext/main.js not found after build${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend built successfully${NC}"

echo -e "${YELLOW}Step 4: Running dart analyze...${NC}"
cd ..
dart analyze --fatal-infos
echo -e "${GREEN}✓ Static analysis passed${NC}"

echo -e "${GREEN}PRD §13.1: PASSED${NC}"

# =============================================================================
# PRD §13.2: Use Web Package in App
# =============================================================================
echo ""
echo -e "${BLUE}=== PRD §13.2: Use Web Package in App ===${NC}"
echo ""

cd "$TEST_DIR"

echo -e "${YELLOW}Step 1: Creating Fluttron app...${NC}"
dart run "${PROJECT_ROOT}/packages/fluttron_cli/bin/fluttron.dart" create ./test_app --name test_app

if [[ ! -d "test_app" ]]; then
    echo -e "${RED}FAILED: test_app directory not created${NC}"
    exit 1
fi
echo -e "${GREEN}✓ App directory created${NC}"

echo -e "${YELLOW}Step 2: Adding web package dependency...${NC}"
cd test_app/ui

# Add dependency to pubspec.yaml
cat >> pubspec.yaml <<EOF

  test_package:
    path: ../../test_package
EOF
echo -e "${GREEN}✓ Dependency added to pubspec.yaml${NC}"

echo -e "${YELLOW}Step 3: Running flutter pub get...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies resolved${NC}"

echo -e "${YELLOW}Step 4: Building app with fluttron build...${NC}"
cd "$TEST_DIR/test_app"
dart run "${PROJECT_ROOT}/packages/fluttron_cli/bin/fluttron.dart" build -p .
echo -e "${GREEN}✓ Build completed${NC}"

echo -e "${YELLOW}Step 5: Verifying JS injection in host/assets/www/index.html...${NC}"
if grep -q "ext/packages/test_package/main.js" host/assets/www/index.html; then
    echo -e "${GREEN}✓ JS bundle injected correctly${NC}"
else
    echo -e "${RED}FAILED: JS bundle not found in index.html${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 6: Verifying registration code generation...${NC}"
if [[ -f "ui/lib/generated/web_package_registrations.dart" ]]; then
    if grep -q "registerFluttronWebPackages" ui/lib/generated/web_package_registrations.dart; then
        echo -e "${GREEN}✓ Registration code generated${NC}"
    else
        echo -e "${RED}FAILED: registerFluttronWebPackages not found in generated code${NC}"
        exit 1
    fi
else
    echo -e "${RED}FAILED: Generated file not found${NC}"
    exit 1
fi

echo -e "${GREEN}PRD §13.2: PASSED${NC}"

# =============================================================================
# PRD §13.3: End-to-End (Optional - requires macOS)
# =============================================================================
echo ""
echo -e "${BLUE}=== PRD §13.3: End-to-End Runtime ===${NC}"
echo ""

if [[ "$(uname)" == "Darwin" ]]; then
    echo -e "${YELLOW}Step 1: Running app on macOS...${NC}"
    echo -e "${YELLOW}Note: This step requires macOS and may take a while.${NC}"
    echo -e "${YELLOW}Skipping automatic run. To test manually:${NC}"
    echo ""
    echo "  cd $TEST_DIR/test_app"
    echo "  dart run ${PROJECT_ROOT}/packages/fluttron_cli/bin/fluttron.dart run -p . -d macos"
    echo ""
    echo -e "${YELLOW}Expected behavior:${NC}"
    echo "  - App launches successfully"
    echo "  - Web package view factory is callable"
    echo "  - No runtime errors in console"
    echo ""
    echo -e "${GREEN}PRD §13.3: MANUAL VERIFICATION REQUIRED${NC}"
else
    echo -e "${YELLOW}Skipping PRD §13.3 - not on macOS${NC}"
    echo -e "${GREEN}PRD §13.3: SKIPPED (non-macOS environment)${NC}"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Acceptance Test Summary${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}✓ PRD §13.1: Create Web Package - PASSED${NC}"
echo -e "${GREEN}✓ PRD §13.2: Use Web Package in App - PASSED${NC}"
echo -e "${YELLOW}○ PRD §13.3: End-to-End - MANUAL/SKIPPED${NC}"
echo ""

if $cleanup; then
    echo -e "${YELLOW}Cleaning up test directory...${NC}"
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
else
    echo -e "${YELLOW}Test projects retained at: $TEST_DIR${NC}"
    echo -e "${YELLOW}To clean up: rm -rf $TEST_DIR${NC}"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}All automated acceptance tests PASSED!${NC}"
echo -e "${GREEN}============================================${NC}"
