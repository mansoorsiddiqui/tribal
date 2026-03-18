#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  create_test_entry "stat-one" "Stat One" "debugging" "test" "high"
  create_test_entry "stat-two" "Stat Two" "debugging" "test" "medium"
  create_test_entry "stat-three" "Stat Three" "tooling" "test" "low"
}

@test "stats shows correct total" {
  run tribal stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total entries: 3"* ]]
}

@test "stats shows category breakdown" {
  run tribal stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"debugging"* ]]
  [[ "$output" == *"tooling"* ]]
}

@test "stats shows confidence breakdown" {
  run tribal stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"high"* ]]
  [[ "$output" == *"medium"* ]]
  [[ "$output" == *"low"* ]]
}

@test "stats handles empty knowledge base" {
  rm -f "$ENTRIES_DIR"/*.md
  run tribal stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total entries: 0"* ]]
}
