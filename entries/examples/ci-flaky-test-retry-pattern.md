---
title: "CI Flaky Test Retry Pattern"
slug: ci-flaky-test-retry-pattern
category: testing
tags: [ci, testing, flaky-tests, retry, github-actions]
confidence: medium
author: Example Author
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Example Author
summary: "Retry flaky tests up to 3 times in CI with quarantine tracking; do not just re-run blindly"
---

## Problem

Flaky tests in CI cause false failures, wasted developer time, and erode trust in
the test suite. Simply re-running the entire pipeline is expensive and masks real issues.

## Solution

Use a structured retry-and-quarantine approach:

1. **Test-level retry** (not pipeline-level):
   ```yaml
   # GitHub Actions example with jest
   - run: npx jest --forceExit --detectOpenHandles
     env:
       JEST_RETRY_TIMES: 3
   ```

2. **Track flaky tests**: When a test passes on retry, log it:
   ```bash
   echo "FLAKY: $TEST_NAME" >> flaky-tests.log
   ```

3. **Quarantine threshold**: If a test flakes more than 3 times in a week,
   automatically move it to a quarantine suite that runs separately and
   does not block merges.

4. **Fix or delete**: Quarantined tests must be fixed within 2 sprints or
   deleted. Assign an owner when quarantining.

Anti-patterns to avoid:
- Re-running entire CI pipeline on failure (expensive, hides issues)
- Adding `sleep()` to fix timing issues (use explicit waits/polling instead)
- Marking tests as `skip` without a tracking issue

## Context

This pattern works for any CI system. The key insight is that retries should be at
the individual test level, and every retry should be tracked. Flaky tests are bugs
and should be treated as such.
