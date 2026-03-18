#!/usr/bin/env bash

# Common test setup for tribal bats tests

TRIBAL_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRIBAL_CLI="$TRIBAL_PROJECT_DIR/tribal"

setup() {
  # Create a temporary directory for each test
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"

  # Initialize tribal in temp dir
  bash "$TRIBAL_CLI" init "$TRIBAL_PATH" >/dev/null 2>&1
}

teardown() {
  # Clean up temp directory
  if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Helper: create a test entry directly (bypass CLI for speed)
create_test_entry() {
  local slug="${1:-test-entry}"
  local title="${2:-Test Entry}"
  local category="${3:-debugging}"
  local tags="${4:-test, example}"
  local confidence="${5:-medium}"
  local body="${6:-## Problem\nTest problem\n\n## Solution\nTest solution}"

  mkdir -p "$ENTRIES_DIR"
  cat > "$ENTRIES_DIR/${slug}.md" << ENTRY
---
title: "$title"
slug: $slug
category: $category
tags: [$tags]
confidence: $confidence
author: $TRIBAL_AUTHOR
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: $TRIBAL_AUTHOR
summary: "Summary for $title"
---

$(echo -e "$body")
ENTRY
}

# Helper: count entries
count_entries() {
  find "$ENTRIES_DIR" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' '
}

# Helper: get INDEX.md line count (excluding header)
get_index_line_count() {
  local index="$TRIBAL_PATH/INDEX.md"
  if [ -f "$index" ]; then
    tail -n +5 "$index" | grep -c '|' || echo 0
  else
    echo 0
  fi
}

# Helper: run tribal command
tribal() {
  bash "$TRIBAL_CLI" "$@"
}
