#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  create_test_entry "entry-one" "Entry One" "debugging" "test" "high"
  create_test_entry "entry-two" "Entry Two" "tooling" "test" "medium"
  create_test_entry "entry-three" "Entry Three" "debugging" "test" "low"
}

@test "list shows all entries" {
  run tribal list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Entry One"* ]]
  [[ "$output" == *"Entry Two"* ]]
  [[ "$output" == *"Entry Three"* ]]
  [[ "$output" == *"Total: 3"* ]]
}

@test "list --category filters correctly" {
  run tribal list --category debugging
  [ "$status" -eq 0 ]
  [[ "$output" == *"Entry One"* ]]
  [[ "$output" == *"Entry Three"* ]]
  [[ "$output" != *"Entry Two"* ]]
}

@test "list shows correct count with filter" {
  run tribal list --category tooling
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total: 1"* ]]
}

@test "list handles empty knowledge base" {
  rm -f "$ENTRIES_DIR"/*.md
  run tribal list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total: 0"* ]]
}
