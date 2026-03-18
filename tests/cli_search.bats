#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  # Call common setup first
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  # Create test entries
  create_test_entry "docker-dns" "Docker DNS Issue" "debugging" "docker, dns, linux" "high" "## Problem\nDNS fails in containers\n\n## Solution\nFix daemon.json"
  create_test_entry "node-version" "Node Version Problem" "environment" "node, nvm, mac" "medium" "## Problem\nWrong node arch\n\n## Solution\nUse arch -arm64"
  create_test_entry "old-entry" "Old Debugging Tip" "debugging" "legacy, old" "low" "## Problem\nOld issue\n\n## Solution\nOld fix"
}

@test "search finds entry by tag match" {
  run tribal search "docker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Docker DNS"* ]]
}

@test "search finds entry by title match" {
  run tribal search "Node Version"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node Version"* ]]
}

@test "search finds entry by body match" {
  run tribal search "daemon.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Docker DNS"* ]]
}

@test "search --category filter works" {
  run tribal search "docker" --category environment
  # Should not find docker entry since it's in debugging category
  [[ "$output" != *"Docker DNS"* ]] || [ "$status" -ne 0 ]
}

@test "search --test returns exit 0 for found results" {
  run tribal search "docker" --test
  [ "$status" -eq 0 ]
}

@test "search --test returns exit 1 for no results" {
  run tribal search "nonexistent_xyz_query" --test
  [ "$status" -eq 1 ]
}

@test "search returns no results gracefully" {
  run tribal search "zzz_no_match_zzz"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No results"* ]]
}

@test "search requires query" {
  run tribal search
  [ "$status" -ne 0 ]
}

@test "search tag match ranks higher than body match" {
  # "docker" is a tag in docker-dns, should rank higher than body-only matches
  run tribal search "docker"
  [ "$status" -eq 0 ]
  # First result should be the docker entry
  local first_result
  first_result=$(echo "$output" | grep -m1 '\[')
  [[ "$first_result" == *"Docker DNS"* ]]
}
