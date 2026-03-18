---
title: "PostgreSQL Connection Pooling with PgBouncer"
slug: postgres-connection-pooling
category: architecture
tags: [postgres, pgbouncer, connection-pooling, database, performance]
confidence: high
author: Example Author
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Example Author
summary: "Use PgBouncer in transaction mode for connection pooling; avoid session-level features"
---

## Problem

Application hits PostgreSQL max_connections limit (default: 100) under load. Increasing
max_connections degrades performance due to memory overhead per connection (~10MB each).
Serverless/lambda deployments exacerbate this since each invocation opens a new connection.

## Solution

Deploy PgBouncer as a connection pooler between the application and PostgreSQL:

1. Install: `apt-get install pgbouncer`

2. Configure `/etc/pgbouncer/pgbouncer.ini`:
   ```ini
   [databases]
   mydb = host=localhost port=5432 dbname=mydb

   [pgbouncer]
   listen_port = 6432
   pool_mode = transaction
   max_client_conn = 1000
   default_pool_size = 20
   ```

3. Point application connection string to port 6432 instead of 5432.

Key considerations for transaction pooling mode:
- Do NOT use prepared statements (they are session-scoped)
- Do NOT use SET commands (they leak between clients)
- Do NOT use LISTEN/NOTIFY
- Do NOT use advisory locks
- Session-level temp tables will not work

## Context

Transaction mode is the right default for web applications. Only use session mode if
you need prepared statements and are willing to accept lower connection multiplexing.
