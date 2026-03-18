#!/usr/bin/env bats

load test_helper/common-setup

@test "security filter catches OpenAI keys" {
  run tribal add --title "OpenAI Key" --category security --summary "test" --body "key: sk-abcdefghijklmnopqrstuvwxyz1234567890"
  [ "$status" -ne 0 ]
}

@test "security filter catches AWS keys" {
  run tribal add --title "AWS Key" --category security --summary "test" --body "key: AKIAIOSFODNN7EXAMPLE"
  [ "$status" -ne 0 ]
}

@test "security filter catches GitHub PATs" {
  run tribal add --title "GitHub PAT" --category security --summary "test" --body "token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
  [ "$status" -ne 0 ]
}

@test "security filter catches connection strings" {
  run tribal add --title "Mongo URI" --category security --summary "test" --body "uri: mongodb+srv://admin:hunter2@cluster.example.com/db"
  [ "$status" -ne 0 ]
}

@test "security filter catches private keys" {
  run tribal add --title "Private Key" --category security --summary "test" --body "secret: -----BEGIN RSA PRIVATE KEY----- stuff here"
  [ "$status" -ne 0 ]
}

@test "security filter passes clean content" {
  run tribal add --title "Clean Entry" --category debugging --summary "no secrets here" --body "## Problem\nJust a normal entry\n\n## Solution\nDo the thing"
  [ "$status" -eq 0 ]
}

@test "security filter --force bypasses all checks" {
  run tribal add --title "Forced" --category security --summary "forced" --body "key: sk-abcdefghijklmnopqrstuvwxyz1234567890" --force
  [ "$status" -eq 0 ]
}
