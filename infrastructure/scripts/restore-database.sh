#!/usr/bin/env bash
set -euo pipefail

psql "${DATABASE_URL:-postgresql://internlink:internlink@localhost:5432/internlink}" < internlink-backup.sql
