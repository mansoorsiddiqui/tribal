#!/usr/bin/env bats

load test_helper/common-setup

@test "full workflow: init -> add -> search -> verify -> reindex" {
  # Init is done in setup, verify it worked
  [ -d "$ENTRIES_DIR" ]
  [ -f "$TRIBAL_PATH/INDEX.md" ]

  # Add an entry
  run tribal add --title "Integration Test Entry" --category debugging --tags "integration,test" --confidence high --summary "Testing full workflow" --body "## Problem\nNeed to test full workflow\n\n## Solution\nRun all commands in sequence"
  [ "$status" -eq 0 ]
  [ -f "$ENTRIES_DIR/integration-test-entry.md" ]

  # Search for it
  run tribal search "integration"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Integration Test Entry"* ]]

  # Verify it
  run tribal verify integration-test-entry
  [ "$status" -eq 0 ]
  local today
  today=$(date +%Y-%m-%d)
  grep -q "last_verified: $today" "$ENTRIES_DIR/integration-test-entry.md"

  # Reindex
  run tribal reindex
  [ "$status" -eq 0 ]
  grep -q "integration-test-entry" "$TRIBAL_PATH/INDEX.md"
}

@test "multiple entries with list and stats" {
  tribal add --title "Entry Alpha" --category debugging --tags "alpha" --confidence high --summary "Alpha entry" --body "Alpha body"
  tribal add --title "Entry Beta" --category tooling --tags "beta" --confidence medium --summary "Beta entry" --body "Beta body"
  tribal add --title "Entry Gamma" --category architecture --tags "gamma" --confidence low --summary "Gamma entry" --body "Gamma body"

  # List should show all three
  run tribal list
  [[ "$output" == *"Total: 3"* ]]

  # Stats should show all categories
  run tribal stats
  [[ "$output" == *"Total entries: 3"* ]]
  [[ "$output" == *"debugging"* ]]
  [[ "$output" == *"tooling"* ]]
  [[ "$output" == *"architecture"* ]]
}

@test "version command works" {
  run tribal version
  [ "$status" -eq 0 ]
  [[ "$output" == *"tribal"* ]]
  [[ "$output" == *"0.1.0"* ]]
}

@test "help command works" {
  run tribal help
  [ "$status" -eq 0 ]
  [[ "$output" == *"tribal"* ]]
  [[ "$output" == *"Commands"* ]]
}

@test "unknown command fails gracefully" {
  run tribal nonexistent_command
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown command"* ]]
}

@test "different authors for verify" {
  tribal add --title "Multi Author" --category process --tags "team" --confidence medium --summary "test" --body "test body"

  TRIBAL_AUTHOR="alice" run tribal verify multi-author
  [ "$status" -eq 0 ]
  grep -q "verified_by: alice" "$ENTRIES_DIR/multi-author.md"
}
