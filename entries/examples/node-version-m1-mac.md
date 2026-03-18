---
title: "Node Version Issues on M1 Mac"
slug: node-version-m1-mac
category: environment
tags: [node, nvm, m1, mac, arm64]
confidence: high
author: Example Author
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Example Author
summary: "Node 18+ requires Rosetta-free nvm install on M1 Macs; use arch -arm64 prefix"
---

## Problem

When installing Node.js 18+ on M1/M2 Macs using nvm, the installation may default
to the x86_64 (Rosetta) version, causing native module compilation failures for
packages like sharp, canvas, or bcrypt.

Symptoms:
- `node -p process.arch` shows `x64` instead of `arm64`
- Native modules fail with "mach-o file, but is an incompatible architecture"
- Significantly slower performance due to Rosetta translation

## Solution

1. Ensure nvm is installed natively (not under Rosetta):
   ```bash
   arch -arm64 /bin/bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
   ```

2. Install Node with the arm64 architecture explicitly:
   ```bash
   arch -arm64 nvm install 20
   ```

3. Verify:
   ```bash
   node -p process.arch   # Should output: arm64
   ```

4. If you had a previous x64 install, remove it:
   ```bash
   nvm uninstall 20
   arch -arm64 nvm install 20
   ```

## Context

This affects all Apple Silicon Macs (M1, M2, M3). The issue arises because Terminal.app
or iTerm2 may be running under Rosetta if it was migrated from an Intel Mac. Check with
`arch` command — it should output `arm64`, not `i386`.
