#!/usr/bin/env bats

load test_helper/common-setup

@test "add creates entry with correct frontmatter" {
  run tribal add --title "Test Entry" --category debugging --tags "test,example" --confidence high --summary "A test" --body "## Problem\nTest"
  [ "$status" -eq 0 ]
  [ -f "$ENTRIES_DIR/test-entry.md" ]
  grep -q 'title: "Test Entry"' "$ENTRIES_DIR/test-entry.md"
  grep -q 'category: debugging' "$ENTRIES_DIR/test-entry.md"
  grep -q 'confidence: high' "$ENTRIES_DIR/test-entry.md"
}

@test "add generates correct slug from title" {
  run tribal add --title "My Complex Title With Spaces" --category debugging --summary "test" --body "test"
  [ "$status" -eq 0 ]
  [ -f "$ENTRIES_DIR/my-complex-title-with-spaces.md" ]
}

@test "add handles slug collision" {
  run tribal add --title "Duplicate" --category debugging --summary "first" --body "first"
  [ "$status" -eq 0 ]
  run tribal add --title "Duplicate" --category debugging --summary "second" --body "second"
  [ "$status" -eq 0 ]
  [ -f "$ENTRIES_DIR/duplicate.md" ]
  [ -f "$ENTRIES_DIR/duplicate-2.md" ]
}

@test "add regenerates INDEX.md" {
  run tribal add --title "Index Test" --category tooling --tags "test" --summary "testing index" --body "body"
  [ "$status" -eq 0 ]
  grep -q "Index Test" "$TRIBAL_PATH/INDEX.md" || grep -q "index-test" "$TRIBAL_PATH/INDEX.md"
}

@test "add blocks API keys" {
  run tribal add --title "Secret Entry" --category security --summary "has secret" --body "my key is sk-abc123def456ghi789jkl012mno345"
  [ "$status" -ne 0 ]
}

@test "add blocks AWS keys" {
  run tribal add --title "AWS Entry" --category security --summary "has aws" --body "key is AKIAIOSFODNN7EXAMPLE"
  [ "$status" -ne 0 ]
}

@test "add --force bypasses security filter" {
  run tribal add --title "Forced Secret" --category security --summary "forced" --body "my key is sk-abc123def456ghi789jkl012mno345" --force
  [ "$status" -eq 0 ]
  [ -f "$ENTRIES_DIR/forced-secret.md" ]
}

@test "add validates empty title from flags" {
  # --title with empty string enters interactive mode which needs stdin
  # Test that passing only non-title flags without --title and with no tty fails
  run bash -c "echo '' | TRIBAL_PATH='$TRIBAL_PATH' TRIBAL_AUTHOR='$TRIBAL_AUTHOR' bash '$TRIBAL_PROJECT_DIR/tribal' add --title ''"
  # Should fail because empty title in interactive mode triggers "Title is required"
  [ "$status" -ne 0 ]
}

@test "add validates category" {
  run tribal add --title "Bad Cat" --category invalid_category --summary "test" --body "test"
  [ "$status" -ne 0 ]
}

@test "add validates confidence" {
  run tribal add --title "Bad Conf" --category debugging --confidence invalid --summary "test" --body "test"
  [ "$status" -ne 0 ]
}

@test "add sets default date fields" {
  run tribal add --title "Date Test" --category debugging --summary "test" --body "test"
  [ "$status" -eq 0 ]
  local today
  today=$(date +%Y-%m-%d)
  grep -q "created: $today" "$ENTRIES_DIR/date-test.md"
  grep -q "last_updated: $today" "$ENTRIES_DIR/date-test.md"
}

@test "add handles special characters in title" {
  run tribal add --title "What's the deal with \"quotes\" & ampersands?" --category debugging --summary "test" --body "test"
  [ "$status" -eq 0 ]
  local count
  count=$(count_entries)
  [ "$count" -ge 1 ]
}
