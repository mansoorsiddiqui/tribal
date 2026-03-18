#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  create_test_entry "update-target" "Update Target" "debugging" "test" "medium"
}

@test "update fails for non-existent slug" {
  run tribal update nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "update requires slug argument" {
  run tribal update
  [ "$status" -ne 0 ]
}

@test "update with EDITOR=true succeeds (no-op editor)" {
  EDITOR=true run tribal update update-target
  [ "$status" -eq 0 ]
  # last_updated should be today
  local today
  today=$(date +%Y-%m-%d)
  grep -q "last_updated: $today" "$ENTRIES_DIR/update-target.md"
}
