#!/usr/bin/env bash
set -euo pipefail

pg_dump "${DATABASE_URL:-postgresql://internlink:internlink@localhost:5432/internlink}" > internlink-backup.sql
