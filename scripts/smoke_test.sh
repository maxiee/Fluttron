#!/bin/bash
set -e

# Determine project root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Fluttron Smoke Test ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Run from project root so templates/ is discoverable
cd "$PROJECT_ROOT"

# Clean up any leftover temp dirs from previous runs
rm -rf /tmp/smoke_test_app /tmp/smoke_test_pkg /tmp/smoke_test_svc

# 1. Install CLI
echo "[1/7] Installing CLI..."
# Remove stale snapshot so activation always rebuilds with latest source
SNAPSHOT_DIR="$PROJECT_ROOT/packages/fluttron_cli/.dart_tool/pub/bin/fluttron_cli"
rm -f "$SNAPSHOT_DIR"/*.snapshot
dart pub global activate --source path packages/fluttron_cli

# Ensure pub global bin is on PATH
export PATH="$PATH:$HOME/.pub-cache/bin"

# 2. Create a new app
echo ""
echo "[2/7] Creating app..."
fluttron create /tmp/smoke_test_app --name SmokeTest
echo "✓ App created"

# 3. Build the app
echo ""
echo "[3/7] Building app..."
fluttron build -p /tmp/smoke_test_app
echo "✓ App built"

# 4. Check doctor
echo ""
echo "[4/7] Running doctor..."
fluttron doctor
echo "✓ Doctor passed"

# 5. Create a web package
echo ""
echo "[5/7] Creating web package..."
fluttron create /tmp/smoke_test_pkg --name smoke_pkg --type web_package
echo "✓ Web package created"

# 6. Create a host service
echo ""
echo "[6/7] Creating host service..."
fluttron create /tmp/smoke_test_svc --name smoke_svc --type host_service
echo "✓ Host service created"

# 7. Package the app
echo ""
echo "[7/7] Packaging app..."
fluttron package -p /tmp/smoke_test_app
echo "✓ App packaged"

# Cleanup
rm -rf /tmp/smoke_test_app /tmp/smoke_test_pkg /tmp/smoke_test_svc

echo ""
echo "=== All smoke tests passed ==="
