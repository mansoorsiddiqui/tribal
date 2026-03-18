#!/usr/bin/env bats

load test_helper/common-setup

@test "index has correct header" {
  tribal reindex
  head -1 "$TRIBAL_PATH/INDEX.md" | grep -q "# Tribal Knowledge Index"
}

@test "index has table format with pipes" {
  create_test_entry "idx-test" "Index Test" "debugging" "test" "high"
  tribal reindex
  grep "idx-test" "$TRIBAL_PATH/INDEX.md" | grep -q '|'
}

@test "index handles zero entries" {
  tribal reindex
  # Should have header but no data rows
  local lines
  lines=$(wc -l < "$TRIBAL_PATH/INDEX.md")
  [ "$lines" -le 5 ]
}

@test "index includes all entries" {
  create_test_entry "idx-a" "Entry A" "debugging" "test" "high"
  create_test_entry "idx-b" "Entry B" "tooling" "test" "medium"
  create_test_entry "idx-c" "Entry C" "process" "test" "low"
  tribal reindex
  grep -c '|.*idx-' "$TRIBAL_PATH/INDEX.md" | grep -q '3'
}

@test "index entries are sorted" {
  create_test_entry "zzz-last" "ZZZ Last" "debugging" "test" "high"
  create_test_entry "aaa-first" "AAA First" "debugging" "test" "high"
  tribal reindex
  # aaa should appear before zzz
  local aaa_line zzz_line
  aaa_line=$(grep -n "aaa-first" "$TRIBAL_PATH/INDEX.md" | head -1 | cut -d: -f1)
  zzz_line=$(grep -n "zzz-last" "$TRIBAL_PATH/INDEX.md" | head -1 | cut -d: -f1)
  [ "$aaa_line" -lt "$zzz_line" ]
}

@test "index shows tags without brackets" {
  create_test_entry "tag-test" "Tag Test" "debugging" "docker, linux" "high"
  tribal reindex
  local line
  line=$(grep "tag-test" "$TRIBAL_PATH/INDEX.md")
  [[ "$line" != *"["* ]]
}
