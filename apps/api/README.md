# InternLink API foundation

The API uses NestJS 12, TypeScript, the shared Prisma Client, and the existing
Neon environment configured in `packages/database/.env`. ConfigModule reads the
API's `.env` and `.env.local` first, then uses the database package env file for
unset values. API-specific values belong in `apps/api/.env`; database URLs stay
in the database package env file. Do not commit either `.env` file.

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
