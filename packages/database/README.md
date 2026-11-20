<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:008bf389334bc1b68565aefef08358428d5ab103815953b205f1cfba50ed28bf -->

<!-- coderabbit-ai-generated-section:v1:adbb8ddfcaf07a4593619944b800d6b42f04cc0a647543954c1ac778dc16c5ec -->

# InternLink database

This package owns the PostgreSQL schema, Prisma Client generation, migrations,
and reference-data seed. Prisma is pinned by the workspace lockfile to v5; the
schema uses Prisma 5's `directUrl` setting for migration connections.

## Local Docker environment

From the repository root, copy the local URLs and start PostgreSQL:

```sh
rg '^(DATABASE_URL|DIRECT_URL)=' .env.example > packages/database/.env
docker compose up -d postgres
```

Both Prisma commands and the API load packages/database/.env. Generate the
client before API tests (the test, test:watch, and test:cov scripts do this
automatically; run db:generate explicitly before test:e2e).

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

## Full-schema migration deployment

The full-schema migration requires a maintenance window. Do not run it while
serving traffic. Prisma 5.22's PostgreSQL runner submits a migration script as
one simple-query batch; SQL statement boundaries do not guarantee lock release.
PostgreSQL executes this single batch in an implicit transaction, so User table
locks last until commit. Do not add explicit BEGIN/COMMIT: an aborted explicit
transaction prevents this runner from recording the original failure. Splitting source edits or Git commits does not change this.

1. Back up the database and rehearse restoration and this migration on a copy.
2. Enable maintenance at ingress and drain requests. Stop every API replica,
   worker, scheduled job, and other writer. For the local Compose deployment:
   `docker compose stop api worker`; also stop any host-run processes.
3. Run `pnpm --dir packages/database db:migrate:deploy` once from the root,
   then `pnpm --dir packages/database db:status` and `db:generate`.
4. On failure keep maintenance enabled. The full migration rolls back. Inspect
   conflicts on the backup/copy, preserve every affected record, and resolve
   them with the data owner. Mark the failed migration rolled back with
   `pnpm --dir packages/database exec prisma migrate resolve --rolled-back 202611180002_full_database`
   only after verifying rollback, then retry deploy. Never bypass unique indexes.
5. Restart API/workers, verify database health, then reopen ingress.

This edits the pending migration; do not rewrite migration history on databases
where it has already been applied. Such databases need a separately reviewed
forward migration and data recovery from backups if values were narrowed.

Compatibility policies: retain foundation TEXT fields and DOUBLE PRECISION GPA
without rounding or scale conversion. No grade scale was defined in the
foundation; percentage values (including 100) and extra precision remain valid.
Department codes remain shareable as in the foundation, with a lookup index;
department names retain their existing organization-scoped uniqueness.
Inactive users retain INVITED, SUSPENDED, or DISABLED; inactive ACTIVE becomes
DISABLED. Unknown statuses become DISABLED if inactive, SUSPENDED otherwise.
Company organization identifier conflicts abort rather than link another tenant.
For duplicate refresh/session hashes, retain the lexically smallest id, revoke it
(preserving the earliest existing revocation), and delete the other conflicting
rows. Unique hashes are unchanged; holders of ambiguous hashes must log in again.
Global role grants use a SQL partial unique index in addition to Prisma's
organization-scoped composite uniqueness.

API driver connection/socket/pool limits are 2/2/1 seconds. Health queries use
SET LOCAL statement_timeout=1000ms in a transaction (3-second transaction limit,
1-second acquisition limit), with a 5-second total response limit. Monitor timeouts
must exceed 5 seconds. The database cancels slow statements even if their response
is lost; the driver bounds socket waits. These driver limits apply to API queries.

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


<!-- /coderabbit-ai-generated:v1 -->