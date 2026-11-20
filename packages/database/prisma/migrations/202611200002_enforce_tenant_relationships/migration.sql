-- Additive schema changes for the current Prisma schema. The full-database
-- migration remains byte-for-byte at its pre-deployment version.
BEGIN;

-- Backfill required relationship columns from their existing parent records.
ALTER TABLE "Application" ADD COLUMN "programId" TEXT;
UPDATE "Application" a
SET "programId" = p."programId"
FROM "InternshipPosition" p
WHERE p."id" = a."positionId";

ALTER TABLE "EvaluationResult" ADD COLUMN "submissionId" TEXT;
UPDATE "EvaluationResult" e
SET "submissionId" = r."submissionId"
FROM "Review" r
WHERE r."id" = e."reviewId";

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "Application" a
    JOIN "InternshipProgram" p ON p."id" = a."programId"
    WHERE a."organizationId" <> p."organizationId"
  ) THEN
    RAISE EXCEPTION 'Cannot add tenant-scoped Application relationship: organization does not match its internship program';
  END IF;
  IF EXISTS (
    SELECT 1 FROM "EvaluationResult" e
    JOIN "Review" r ON r."id" = e."reviewId"
    WHERE e."submissionId" <> r."submissionId"
  ) THEN
    RAISE EXCEPTION 'Cannot add EvaluationResult relationship: submission does not match its review';
  END IF;
  IF EXISTS (SELECT 1 FROM "Application" WHERE "programId" IS NULL)
     OR EXISTS (SELECT 1 FROM "EvaluationResult" WHERE "submissionId" IS NULL) THEN
    RAISE EXCEPTION 'Cannot backfill required program or submission relationship columns';
  END IF;
END $$;

ALTER TABLE "Application" ALTER COLUMN "programId" SET NOT NULL;
ALTER TABLE "EvaluationResult" ALTER COLUMN "submissionId" SET NOT NULL;

ALTER TABLE "Application" DROP CONSTRAINT "Application_positionId_fkey";
ALTER TABLE "Interview" DROP CONSTRAINT "Interview_applicationId_fkey";
ALTER TABLE "Placement" DROP CONSTRAINT "Placement_applicationId_fkey";
ALTER TABLE "InternshipTeam" DROP CONSTRAINT "InternshipTeam_placementId_fkey";
ALTER TABLE "Submission" DROP CONSTRAINT "Submission_placementId_fkey";
ALTER TABLE "EvaluationResult" DROP CONSTRAINT "EvaluationResult_reviewId_fkey";
ALTER TABLE "EvaluationResult" DROP CONSTRAINT "EvaluationResult_placementId_fkey";
ALTER TABLE "FinalResult" DROP CONSTRAINT "FinalResult_placementId_fkey";
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_supportRequestId_fkey";
ALTER TABLE "CVExtraction" DROP CONSTRAINT "CVExtraction_documentId_fkey";

ALTER TABLE "ImplementationMilestone" ALTER COLUMN "sortOrder" DROP DEFAULT;
ALTER TABLE "EvaluationCriterion" ALTER COLUMN "sortOrder" DROP DEFAULT;

CREATE UNIQUE INDEX "InternshipProgram_id_organizationId_key"
  ON "InternshipProgram"("id", "organizationId");
CREATE UNIQUE INDEX "InternshipPosition_id_programId_key"
  ON "InternshipPosition"("id", "programId");
CREATE UNIQUE INDEX "Application_id_positionId_studentProfileId_organizationId_key"
  ON "Application"("id", "positionId", "studentProfileId", "organizationId");
CREATE UNIQUE INDEX "Application_id_positionId_key"
  ON "Application"("id", "positionId");
CREATE UNIQUE INDEX "Placement_applicationId_positionId_studentProfileId_key"
  ON "Placement"("applicationId", "positionId", "studentProfileId");
CREATE UNIQUE INDEX "Placement_id_studentProfileId_key"
  ON "Placement"("id", "studentProfileId");
CREATE UNIQUE INDEX "Placement_application_org_key"
  ON "Placement"("applicationId", "positionId", "studentProfileId", "organizationId");
CREATE UNIQUE INDEX "Placement_id_organizationId_key"
  ON "Placement"("id", "organizationId");
CREATE UNIQUE INDEX "Placement_id_studentProfileId_organizationId_key"
  ON "Placement"("id", "studentProfileId", "organizationId");
CREATE UNIQUE INDEX "InternshipTeam_placementId_organizationId_key"
  ON "InternshipTeam"("placementId", "organizationId");
CREATE UNIQUE INDEX "Submission_id_placementId_key"
  ON "Submission"("id", "placementId");
CREATE UNIQUE INDEX "Review_id_submissionId_key"
  ON "Review"("id", "submissionId");
CREATE UNIQUE INDEX "EvaluationResult_reviewId_submissionId_key"
  ON "EvaluationResult"("reviewId", "submissionId");
CREATE UNIQUE INDEX "Document_id_organizationId_key"
  ON "Document"("id", "organizationId");
CREATE UNIQUE INDEX "FinalResult_placementId_studentProfileId_organizationId_key"
  ON "FinalResult"("placementId", "studentProfileId", "organizationId");
CREATE UNIQUE INDEX "FinancialSupportRequest_id_studentProfileId_organizationId_key"
  ON "FinancialSupportRequest"("id", "studentProfileId", "organizationId");

ALTER TABLE "Application"
  ADD CONSTRAINT "Application_programId_organizationId_fkey"
    FOREIGN KEY ("programId", "organizationId") REFERENCES "InternshipProgram"("id", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT "Application_positionId_programId_fkey"
    FOREIGN KEY ("positionId", "programId") REFERENCES "InternshipPosition"("id", "programId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_applicationPosition_fkey"
  FOREIGN KEY ("applicationId", "positionId") REFERENCES "Application"("id", "positionId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Placement" ADD CONSTRAINT "Placement_applicationPositionStudent_fkey"
  FOREIGN KEY ("applicationId", "positionId", "studentProfileId", "organizationId") REFERENCES "Application"("id", "positionId", "studentProfileId", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "InternshipTeam" ADD CONSTRAINT "InternshipTeam_placementOrganization_fkey"
  FOREIGN KEY ("placementId", "organizationId") REFERENCES "Placement"("id", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Submission" ADD CONSTRAINT "Submission_placementOrganization_fkey"
  FOREIGN KEY ("placementId", "organizationId") REFERENCES "Placement"("id", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "EvaluationResult"
  ADD CONSTRAINT "EvaluationResult_reviewId_submissionId_fkey"
    FOREIGN KEY ("reviewId", "submissionId") REFERENCES "Review"("id", "submissionId") ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT "EvaluationResult_submissionId_placementId_fkey"
    FOREIGN KEY ("submissionId", "placementId") REFERENCES "Submission"("id", "placementId") ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT "EvaluationResult_placementStudent_fkey"
    FOREIGN KEY ("placementId", "studentProfileId") REFERENCES "Placement"("id", "studentProfileId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "FinalResult" ADD CONSTRAINT "FinalResult_placementStudentOrg_fkey"
  FOREIGN KEY ("placementId", "studentProfileId", "organizationId") REFERENCES "Placement"("id", "studentProfileId", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_supportRequestContext_fkey"
  FOREIGN KEY ("supportRequestId", "studentProfileId", "organizationId") REFERENCES "FinancialSupportRequest"("id", "studentProfileId", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "CVExtraction" ADD CONSTRAINT "CVExtraction_documentOrganization_fkey"
  FOREIGN KEY ("documentId", "organizationId") REFERENCES "Document"("id", "organizationId") ON DELETE RESTRICT ON UPDATE CASCADE;

COMMIT;
