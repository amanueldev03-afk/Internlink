# InternLink database

This package owns the PostgreSQL schema, Prisma Client generation, migrations,
and reference-data seed. Prisma is pinned by the workspace lockfile to v5; the
schema uses Prisma 5's `directUrl` setting for migration connections.

## Neon environment

Copy `.env.example` to `.env` in this package. Set `DATABASE_URL` to the Neon
pooled connection string (hostname includes `-pooler`) and `DIRECT_URL` to the
unpooled connection string. Do not commit `.env` or put database credentials in
source control. Both URLs must target the same Neon database and use TLS.

## Local Docker environment

From the repository root, copy the root example to this package's environment
file. It contains the local PostgreSQL URLs used by `compose.yaml`:

```sh
cp .env.example packages/database/.env
docker compose up -d postgres
```

Use this for local development; keep the Neon setup above as a separate
environment option. Do not copy local placeholder credentials into a deployed
environment.

## Commands

Run from the repository root:

```sh
pnpm --dir packages/database db:generate
pnpm --dir packages/database db:migrate
pnpm --dir packages/database db:seed
pnpm --dir packages/database db:status
pnpm --dir packages/database typecheck
```

Use `db:migrate` to create/apply a development migration. The direct connection
role must have `CREATEDB` for Prisma Migrate's shadow database, unless a
separate shadow database is configured with `shadowDatabaseUrl`. Use
`db:migrate:deploy` instead to apply committed migrations without a shadow
database. Run either migration command before `db:seed`, then use `db:status`
to check the resulting migration state.

Seed is idempotent and creates the ten actor roles and permission reference
rows; it does not create users or organization data. The built-in role
permission matrix is authoritative: `db:seed` removes grants from built-in
roles when those grants are not included in that matrix.

## Tenant and sensitive-data notes

Some tenant-owned records carry `organizationId` directly; others inherit scope
through a parent relation. For example, `InternshipPosition` has no direct
`organizationId`, so position queries must scope through
`program.organizationId`. Related records retain foreign keys and deletion
policies. Reads and writes must still scope by the authenticated organization
in the service layer; the database schema alone does not implement PostgreSQL
row-level security. Passwords and access tokens are represented by hash fields; document
contents and AI inputs/outputs use storage references or JSON evidence rather
than database file blobs. Avoid storing payment credentials in these records.
