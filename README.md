<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:39ee4d1ad748add3b798356a41d8bbf38feb6303254463f3ef022a379680680d -->

# InternLink

InternLink is an AI-powered university internship and career development platform.

## Monorepo structure

- `apps/web` – React + Vite frontend
- `apps/api` – NestJS backend API
- `apps/worker` – job workers and scheduled tasks
- `services/ai-service` – FastAPI AI service
- `packages/database` – Prisma schema and database helpers
- `packages/contracts` – shared DTO and API contracts
- `packages/config` – shared tooling configuration
- `packages/utils` – shared utilities
- `infrastructure` – Docker, Nginx, monitoring, deployment templates
- `docs` – project documentation

## Prerequisites

- Node.js 20+
- pnpm 9+
- Python 3.11+
- PostgreSQL client tools (optional but recommended)
- Docker + Docker Compose (for local container orchestration)

## Quick start

1. Install dependencies:
   pnpm install
2. Create local environment files from the examples:
   cp .env.example .env
   cp .env.example packages/database/.env
   cp apps/api/.env.example apps/api/.env
   # Copy the local database URLs for both API and Prisma commands:
   rg '^(DATABASE_URL|DIRECT_URL)=' .env.example > packages/database/.env
   cp apps/web/.env.example apps/web/.env
   cp apps/worker/.env.example apps/worker/.env
   cp services/ai-service/.env.example services/ai-service/.env
3. Start infrastructure:
   docker compose up -d postgres redis minio
4. Generate the client, apply migrations, and seed the local database:
   pnpm --dir packages/database db:generate
   pnpm --dir packages/database db:migrate:deploy
   pnpm --dir packages/database db:seed
   Start API:
   pnpm --dir apps/api start:dev
5. Start worker:
   pnpm --dir apps/worker dev
6. Start web:
   pnpm --dir apps/web dev
7. Start AI service:
   cd services/ai-service && python3 -m venv .venv && source .venv/bin/activate && PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cpu pip install -e .
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

## Docker on a memory-limited machine

Dockerfiles describe how to build the services; `compose.yaml` starts them. On Ubuntu, use Docker Engine with the Compose plugin. Docker Desktop is not required. The AI container is opt-in because its ML dependencies use more disk and memory.

Start only the infrastructure containers:

```sh
docker compose up -d postgres redis minio
docker compose ps
```

Then run the apps locally in separate terminals:

```sh
pnpm --dir apps/api start:dev
pnpm --dir apps/web dev
pnpm --dir apps/worker dev
```

To run the containerized Node services too, use `docker compose up -d postgres redis minio api web worker`. Add `--profile ai` only when you want to build and run the AI container:

```sh
docker compose --profile ai up -d ai-service
```

Inspect services with `docker compose ps` and `docker compose logs -f api`. Stop containers while keeping their data volumes with `docker compose down`; avoid `docker compose down -v` unless you intend to delete the database and object-storage data.

## Database setup

For local Docker PostgreSQL, copy the root example into
`packages/database/.env` as shown above. Start PostgreSQL, then generate the
Prisma Client, apply migrations, and seed reference data:

docker compose up -d postgres
pnpm --dir packages/database db:generate
pnpm --dir packages/database db:migrate
pnpm --dir packages/database db:seed

For Neon, instead copy `packages/database/.env.example` to
`packages/database/.env` and set its pooled `DATABASE_URL` and direct
`DIRECT_URL` to the same Neon database. Then run the Prisma commands above.

## Documentation

See the `docs/` directory for plan and architecture documents.

# Internlink


<!-- /coderabbit-ai-generated:v1 -->