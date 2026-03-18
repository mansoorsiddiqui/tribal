#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="verifier-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  create_test_entry "verify-target" "Verify Target" "debugging" "test" "medium"
}

@test "verify updates last_verified date" {
  run tribal verify verify-target
  [ "$status" -eq 0 ]
  local today
  today=$(date +%Y-%m-%d)
  grep -q "last_verified: $today" "$ENTRIES_DIR/verify-target.md"
}

@test "verify updates verified_by field" {
  run tribal verify verify-target
  [ "$status" -eq 0 ]
  grep -q "verified_by: verifier-user" "$ENTRIES_DIR/verify-target.md"
}

@test "verify fails for non-existent slug" {
  run tribal verify nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "verify requires slug argument" {
  run tribal verify
  [ "$status" -ne 0 ]
}
