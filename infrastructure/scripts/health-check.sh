#!/usr/bin/env bash
set -euo pipefail

curl -fsS http://localhost:3001/docs >/dev/null || echo 'API not reachable'
curl -fsS http://localhost:8000/health >/dev/null || echo 'AI service not reachable'
