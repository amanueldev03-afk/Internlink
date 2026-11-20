-- Follow-up for the already-applied full-database migration. Keep the
-- historical migration unchanged so its recorded checksum remains valid.
BEGIN;

-- The newer permission was added after the original enum migration.
ALTER TYPE "PermissionName" ADD VALUE IF NOT EXISTS 'MANAGE_ORGANIZATION_SETTINGS';

-- The renamed legacy field is nullable in Prisma and should not inherit the
-- old User.status default for newly created users.
ALTER TABLE "User" ALTER COLUMN "legacyStatus" DROP DEFAULT;
ALTER TABLE "User" ALTER COLUMN "legacyStatus" TYPE TEXT;
ALTER TABLE "User" ALTER COLUMN "email" TYPE TEXT,
  ALTER COLUMN "phone" TYPE TEXT,
  ALTER COLUMN "passwordHash" TYPE TEXT,
  ALTER COLUMN "firstName" TYPE TEXT,
  ALTER COLUMN "lastName" TYPE TEXT;
UPDATE "User"
SET "status" = 'DISABLED'
WHERE NOT "isActive" AND upper("legacyStatus") = 'ACTIVE';

ALTER TABLE "Role" ALTER COLUMN "description" TYPE TEXT;
ALTER TABLE "Permission" ALTER COLUMN "description" TYPE TEXT;
ALTER TABLE "Organization" ALTER COLUMN "name" TYPE TEXT,
  ALTER COLUMN "slug" TYPE TEXT,
  ALTER COLUMN "legacyType" TYPE TEXT;
ALTER TABLE "Department" ALTER COLUMN "name" TYPE TEXT,
  ALTER COLUMN "code" TYPE TEXT;
ALTER TABLE "StudentProfile" ALTER COLUMN "studentNumber" TYPE TEXT;
ALTER TABLE "CompanyProfile" ALTER COLUMN "companyName" TYPE TEXT,
  ALTER COLUMN "website" TYPE TEXT,
  ALTER COLUMN "industry" TYPE TEXT;
ALTER TABLE "RefreshToken" ALTER COLUMN "tokenHash" TYPE TEXT;
ALTER TABLE "LoginSession" ALTER COLUMN "tokenHash" TYPE TEXT,
  ALTER COLUMN "device" TYPE TEXT,
  ALTER COLUMN "ipAddress" TYPE TEXT;

-- Department codes are searchable identifiers, but the inventory does not
-- establish that they must be unique. Preserve existing departments and allow
-- shared codes within an organization.
DROP INDEX IF EXISTS "Department_organizationId_code_key";
CREATE INDEX IF NOT EXISTS "Department_organizationId_code_idx"
  ON "Department"("organizationId", "code");

-- Prisma schema cannot represent these partial unique indexes directly.
DELETE FROM "UserRole" duplicate
USING "UserRole" keeper
WHERE duplicate."organizationId" IS NULL
  AND keeper."organizationId" IS NULL
  AND duplicate."userId" = keeper."userId"
  AND duplicate."roleId" = keeper."roleId"
  AND duplicate."id" > keeper."id";

CREATE UNIQUE INDEX IF NOT EXISTS "UserRole_global_userId_roleId_key"
  ON "UserRole"("userId", "roleId")
  WHERE "organizationId" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "KeyCheckout_one_open_per_key_idx"
  ON "KeyCheckout"("keyId")
  WHERE "status" = 'CHECKED_OUT';

-- A pre-existing organization may have occupied the deterministic legacy
-- slug. In that case give the profile its own organization and a free slug.
DO $$
DECLARE
  profile RECORD;
  generated_id TEXT;
  generated_slug TEXT;
  candidate_slug TEXT;
  suffix INTEGER;
BEGIN
  FOR profile IN
    SELECT cp."id", cp."companyName", cp."organizationId", o."id" AS linked_id, o."slug" AS linked_slug
    FROM "CompanyProfile" cp
    JOIN "Organization" o ON o."id" = cp."organizationId"
  LOOP
    generated_id := 'legacy-company-' || substr(md5(profile."id"), 1, 24);
    generated_slug := generated_id;
    IF profile."linked_slug" = generated_slug AND profile."linked_id" <> generated_id THEN
      IF EXISTS (SELECT 1 FROM "Organization" WHERE "id" = generated_id) THEN
        RAISE EXCEPTION 'Cannot repair legacy company organization link for profile %: generated organization id is already in use', profile."id";
      END IF;

      candidate_slug := generated_slug || '-profile';
      suffix := 1;
      WHILE EXISTS (SELECT 1 FROM "Organization" WHERE "slug" = candidate_slug) LOOP
        candidate_slug := generated_slug || '-profile-' || suffix::TEXT;
        suffix := suffix + 1;
      END LOOP;

      INSERT INTO "Organization" ("id", "name", "slug", "type", "createdAt", "updatedAt")
      VALUES (generated_id, profile."companyName", candidate_slug, 'COMPANY', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      UPDATE "CompanyProfile" SET "organizationId" = generated_id WHERE "id" = profile."id";
    END IF;
  END LOOP;
END $$;

-- Revoke ambiguous duplicate hashes before enforcing their unique indexes.
WITH duplicates AS (
  SELECT "tokenHash", min("id") AS keeper, min("revokedAt") AS revoked
  FROM "RefreshToken" GROUP BY "tokenHash" HAVING count(*) > 1
)
UPDATE "RefreshToken" t SET "revokedAt" = coalesce(d.revoked, CURRENT_TIMESTAMP)
FROM duplicates d WHERE t."id" = d.keeper;
DELETE FROM "RefreshToken" t USING "RefreshToken" keeper
WHERE t."tokenHash" = keeper."tokenHash" AND t."id" > keeper."id";

WITH duplicates AS (
  SELECT "tokenHash", min("id") AS keeper, min("revokedAt") AS revoked
  FROM "LoginSession" GROUP BY "tokenHash" HAVING count(*) > 1
)
UPDATE "LoginSession" t SET "revokedAt" = coalesce(d.revoked, CURRENT_TIMESTAMP)
FROM duplicates d WHERE t."id" = d.keeper;
DELETE FROM "LoginSession" t USING "LoginSession" keeper
WHERE t."tokenHash" = keeper."tokenHash" AND t."id" > keeper."id";

CREATE UNIQUE INDEX IF NOT EXISTS "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");
CREATE UNIQUE INDEX IF NOT EXISTS "LoginSession_tokenHash_key" ON "LoginSession"("tokenHash");

COMMIT;

-- No supported GPA scale or rounding policy has been defined. Keep PostgreSQL
-- floating-point precision and remove the numeric(5,2) restriction. Any
-- precision already rounded by the historical migration cannot be recovered
-- by this widening conversion.
ALTER TABLE "StudentProfile"
  ALTER COLUMN "gpa" TYPE DOUBLE PRECISION
  USING "gpa"::DOUBLE PRECISION;
