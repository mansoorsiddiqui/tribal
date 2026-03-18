#!/usr/bin/env bats

load test_helper/common-setup

@test "init creates directory structure" {
  [ -d "$TRIBAL_PATH/entries" ]
}

@test "init creates INDEX.md" {
  [ -f "$TRIBAL_PATH/INDEX.md" ]
}

@test "init creates .git directory" {
  [ -d "$TRIBAL_PATH/.git" ]
}

@test "init is idempotent" {
  # Run init again — should not fail
  run tribal init "$TRIBAL_PATH"
  [ "$status" -eq 0 ]
  [ -d "$TRIBAL_PATH/entries" ]
  [ -f "$TRIBAL_PATH/INDEX.md" ]
}

@test "init respects TRIBAL_PATH env var" {
  local custom_path
  custom_path=$(mktemp -d)
  TRIBAL_PATH="$custom_path" run tribal init "$custom_path"
  [ "$status" -eq 0 ]
  [ -d "$custom_path/entries" ]
  [ -f "$custom_path/INDEX.md" ]
  rm -rf "$custom_path"
}

@test "init creates .gitignore" {
  [ -f "$TRIBAL_PATH/.gitignore" ]
}
