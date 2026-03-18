---
title: "Git Rebase vs Merge Policy"
slug: git-rebase-vs-merge-policy
category: process
tags: [git, rebase, merge, branching, workflow]
confidence: medium
author: Example Author
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Example Author
summary: "Use rebase for feature branches, merge commits for main; never rebase shared branches"
---

## Problem

Teams waste time debating rebase vs merge without a clear policy. Mixed approaches
create confusing git history, merge conflicts, and occasional lost commits when
someone rebases a shared branch.

## Solution

Team policy:

1. **Feature branches onto main**: Always rebase before merging
   ```bash
   git checkout feature-branch
   git rebase main
   git checkout main
   git merge --no-ff feature-branch
   ```

2. **Main merges**: Use `--no-ff` to preserve feature branch boundaries
   in history. This creates a merge commit that clearly shows what was
   integrated and when.

3. **Shared/long-lived branches**: Never rebase. Use merge to integrate
   changes from main:
   ```bash
   git checkout shared-branch
   git merge main
   ```

4. **PR settings** (GitHub): Set to "Rebase and merge" or "Squash and merge"
   for small PRs, "Create a merge commit" for larger features.

Rules:
- Never `git push --force` to main or any shared branch
- `git push --force-with-lease` is acceptable on personal feature branches only
- If rebase produces more than 5 conflicts, abort and use merge instead

## Context

This policy optimizes for readable linear history on feature branches while
preserving merge context on main. It is a compromise that works for teams of
any size.
