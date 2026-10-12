#!/usr/bin/env bash
# Downloads drift's auxiliary files needed to run the app on the web (Chrome).
#
# Places sqlite3.wasm and drift_worker.js in app/web/, matching the versions
# resolved in pubspec.lock (drift 2.31.0 / sqlite3 2.9.4).
#
# Usage (from the app folder):
#   ./tool/fetch_web_assets.sh
#
# On Android these files are NOT required.

set -euo pipefail

DRIFT_VERSION="2.31.0"
SQLITE3_VERSION="2.9.4"

DRIFT_WORKER_URL="https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/drift_worker.js"
SQLITE3_WASM_URL="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3_VERSION}/sqlite3.wasm"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$(dirname "$SCRIPT_DIR")/web"
mkdir -p "$WEB_DIR"

echo "Downloading drift_worker.js (drift ${DRIFT_VERSION})..."
curl -fsSL "$DRIFT_WORKER_URL" -o "$WEB_DIR/drift_worker.js"

echo "Downloading sqlite3.wasm (sqlite3 ${SQLITE3_VERSION})..."
curl -fsSL "$SQLITE3_WASM_URL" -o "$WEB_DIR/sqlite3.wasm"

echo "Done. Files in: $WEB_DIR"
echo "Now run: flutter run -d chrome"
