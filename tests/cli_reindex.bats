#!/usr/bin/env bats

load test_helper/common-setup

@test "reindex regenerates INDEX.md" {
  create_test_entry "reindex-test" "Reindex Test" "tooling" "test" "high"
  run tribal reindex
  [ "$status" -eq 0 ]
  grep -q "reindex-test" "$TRIBAL_PATH/INDEX.md"
}

@test "reindex handles empty entries directory" {
  run tribal reindex
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 entries"* ]]
}

@test "reindex shows correct count" {
  create_test_entry "one" "One" "debugging" "test" "high"
  create_test_entry "two" "Two" "debugging" "test" "high"
  create_test_entry "three" "Three" "debugging" "test" "high"
  run tribal reindex
  [ "$status" -eq 0 ]
  [[ "$output" == *"3 entries"* ]]
}

@test "reindex INDEX.md has correct table format" {
  create_test_entry "format-test" "Format Test" "tooling" "tag1, tag2" "medium"
  tribal reindex
  # Check header
  head -1 "$TRIBAL_PATH/INDEX.md" | grep -q "# Tribal Knowledge Index"
  # Check table has pipe delimiters
  grep "format-test" "$TRIBAL_PATH/INDEX.md" | grep -q '|'
}
