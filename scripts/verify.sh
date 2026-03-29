#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

echo "==> Building Leaf (Debug, macOS)"
xcodebuild -project Leaf/Leaf.xcodeproj -scheme Leaf -destination 'platform=macOS' build

