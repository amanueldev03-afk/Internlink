#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
pnpm --dir packages/database db:migrate
