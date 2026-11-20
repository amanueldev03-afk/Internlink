# InternLink API foundation

The API uses NestJS 12, TypeScript, the shared Prisma Client, and the existing
Neon environment configured in `packages/database/.env`. ConfigModule reads env files in this order:
`apps/api/.env.local`, `apps/api/.env`, then `packages/database/.env`. The first
file defining a variable wins; values already set in the process environment
take precedence over all env files. API-specific values belong in
`apps/api/.env`; database URLs stay in the database package env file. When
upgrading an existing setup, remove
`DATABASE_URL` and `DIRECT_URL` from `apps/api/.env` and `apps/api/.env.local`
after moving them to `packages/database/.env`, so stale API values cannot
override the shared database URLs. Keep both database URLs in the shared file.
Do not commit either `.env` file.

The API uses a two-second database connection-timeout fallback when the
database URL omits `connect_timeout` or sets it to `0`. Set
`DATABASE_CONNECT_TIMEOUT_SECONDS` to change this fallback. A positive
`connect_timeout` already present in the database URL is preserved.

From the repository root:

```sh
pnpm --dir packages/database db:generate
pnpm --dir apps/api start:dev
```

The database health endpoint is `GET http://localhost:3001/api/v1/health/database`.
It runs `SELECT 1` and returns only connected/disconnected status. Prisma
connection details and driver errors are not returned by the endpoint.

Run backend checks with:

```sh
pnpm --dir apps/api typecheck
pnpm --dir apps/api build
pnpm --dir apps/api test
pnpm --dir apps/api test:e2e
```

Jest runs in ESM mode to match the installed NestJS 12 packages and uses
`--runInBand` to keep memory use predictable on smaller development machines.
