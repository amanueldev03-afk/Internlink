-- Follow-up for the already-applied full-database migration. Keep the
-- historical migration unchanged so its recorded checksum remains valid.

-- The renamed legacy field is nullable in Prisma and should not inherit the
-- old User.status default for newly created users.
ALTER TABLE "User" ALTER COLUMN "legacyStatus" DROP DEFAULT;

-- Department codes are searchable identifiers, but the inventory does not
-- establish that they must be unique. Preserve existing departments and allow
-- shared codes within an organization.
DROP INDEX "Department_organizationId_code_key";
CREATE INDEX "Department_organizationId_code_idx"
  ON "Department"("organizationId", "code");

-- No supported GPA scale or rounding policy has been defined. Keep PostgreSQL
-- floating-point precision and remove the numeric(5,2) restriction. Any
-- precision already rounded by the historical migration cannot be recovered
-- by this widening conversion.
ALTER TABLE "StudentProfile"
  ALTER COLUMN "gpa" TYPE DOUBLE PRECISION
  USING "gpa"::DOUBLE PRECISION;
