---
title: "Docker DNS Resolution Failures on Linux"
slug: docker-dns-resolution-linux
category: debugging
tags: [docker, dns, linux, networking, systemd-resolved]
confidence: high
author: Example Author
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Example Author
summary: "Docker containers fail DNS on Linux with systemd-resolved; fix by configuring daemon.json dns"
---

## Problem

Docker containers on Ubuntu/Fedora fail to resolve DNS names. `apt-get update` or
`pip install` inside containers fails with "Temporary failure resolving..." errors.

Root cause: systemd-resolved uses 127.0.0.53 as the local DNS stub, which is not
reachable from inside Docker's network namespace.

## Solution

1. Create or edit `/etc/docker/daemon.json`:
   ```json
   {
     "dns": ["8.8.8.8", "8.8.4.4"]
   }
   ```

2. Restart Docker:
   ```bash
   sudo systemctl restart docker
   ```

3. Alternatively, for corporate environments with internal DNS, find the real upstream
   DNS server:
   ```bash
   resolvectl status | grep "DNS Servers"
   ```
   Then use that IP in `daemon.json` instead of Google's DNS.

## Context

This is the most common Docker networking issue on modern Linux distros using
systemd-resolved (Ubuntu 18.04+, Fedora 33+). It does not affect macOS Docker Desktop
since it handles DNS differently through its VM layer.
