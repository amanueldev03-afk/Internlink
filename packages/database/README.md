# InternLink database

This package owns the PostgreSQL schema, Prisma Client generation, migrations,
and reference-data seed. Prisma is pinned by the workspace lockfile to v5; the
schema uses Prisma 5's `directUrl` setting for migration connections.

## Neon environment

Copy `.env.example` to `.env` in this package. Set `DATABASE_URL` to the Neon
pooled connection string (hostname includes `-pooler`) and `DIRECT_URL` to the
unpooled connection string. Do not commit `.env` or put database credentials in
source control. Both URLs must target the same Neon database and use TLS.

## Commands

Run from the repository root:

```sh
pnpm --dir packages/database db:generate
pnpm --dir packages/database db:status
pnpm --dir packages/database db:migrate
pnpm --dir packages/database db:migrate:deploy
pnpm --dir packages/database db:seed
pnpm --dir packages/database typecheck
```

Use `db:migrate` to create/apply a development migration. Use
`db:migrate:deploy` to apply committed migrations to a deployed database. Seed
is idempotent and creates the ten actor roles and permission reference rows;
it does not create users or organization data.

## Tenant and sensitive-data notes

Tenant-owned records include an `organizationId` and organization-oriented
indexes. Related records also retain foreign keys and deletion policies. Reads
and writes must still scope by the authenticated organization in the service
layer; the database schema alone does not implement PostgreSQL row-level
security. Passwords and access tokens are represented by hash fields; document
contents and AI inputs/outputs use storage references or JSON evidence rather
than database file blobs. Avoid storing payment credentials in these records.
