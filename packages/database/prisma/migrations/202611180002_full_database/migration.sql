-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INVITED', 'SUSPENDED', 'DISABLED');

-- Add the organization-scoped settings permission while keeping global settings
-- restricted to the existing system-admin permission.
ALTER TYPE "PermissionName" ADD VALUE 'MANAGE_ORGANIZATION_SETTINGS';

-- CreateEnum
CREATE TYPE "OrganizationType" AS ENUM ('UNIVERSITY', 'COMPANY', 'STUDENT_UNION', 'FINANCIAL_OFFICE', 'DORMITORY', 'OTHER');

-- CreateEnum
CREATE TYPE "InvitationStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'REVOKED');

-- CreateEnum
CREATE TYPE "InternshipStatus" AS ENUM ('DRAFT', 'OPEN', 'PAUSED', 'CLOSED');

-- CreateEnum
CREATE TYPE "ApplicationStatus" AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'INTERVIEW', 'OFFERED', 'ACCEPTED', 'REJECTED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "EligibilityStatus" AS ENUM ('PENDING', 'ELIGIBLE', 'INELIGIBLE', 'REVIEW_REQUIRED');

-- CreateEnum
CREATE TYPE "InterviewStatus" AS ENUM ('SCHEDULED', 'COMPLETED', 'CANCELLED', 'NO_SHOW');

-- CreateEnum
CREATE TYPE "PlacementStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'TERMINATED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "TaskStatus" AS ENUM ('TODO', 'IN_PROGRESS', 'BLOCKED', 'IN_REVIEW', 'DONE', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SubmissionStatus" AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'RETURNED', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "ReviewStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED');

-- CreateEnum
CREATE TYPE "DocumentStatus" AS ENUM ('UPLOADED', 'PENDING_VERIFICATION', 'VERIFIED', 'REJECTED', 'EXPIRED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "AllocationStatus" AS ENUM ('RESERVED', 'ACTIVE', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "KeyCheckoutStatus" AS ENUM ('CHECKED_OUT', 'RETURNED', 'LOST');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'REFUNDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SupportStatus" AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PAID', 'CANCELLED');

-- CreateEnum
CREATE TYPE "NotificationChannel" AS ENUM ('IN_APP', 'EMAIL', 'SMS');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('PENDING', 'SENT', 'READ', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('TEXT', 'FILE', 'SYSTEM');

-- CreateEnum
CREATE TYPE "MeetingStatus" AS ENUM ('SCHEDULED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PresentationStatus" AS ENUM ('SCHEDULED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "AIJobStatus" AS ENUM ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "AIJobType" AS ENUM ('CV_EXTRACTION', 'SKILL_ANALYSIS', 'MATCHING', 'RECOMMENDATION', 'SKILL_GAP', 'SUMMARIZATION');

-- AlterEnum
ALTER TYPE "VerificationStatus" ADD VALUE 'EXPIRED';

-- DropForeignKey
ALTER TABLE "UserRole" DROP CONSTRAINT "UserRole_roleId_fkey";

-- DropForeignKey
ALTER TABLE "OrganizationMember" DROP CONSTRAINT "OrganizationMember_userId_fkey";

-- DropForeignKey
ALTER TABLE "Department" DROP CONSTRAINT "Department_organizationId_fkey";

-- DropForeignKey
ALTER TABLE "StudentProfile" DROP CONSTRAINT "StudentProfile_userId_fkey";

-- DropForeignKey
ALTER TABLE "CompanyProfile" DROP CONSTRAINT "CompanyProfile_userId_fkey";

-- DropForeignKey
ALTER TABLE "CompanyVerification" DROP CONSTRAINT "CompanyVerification_companyProfileId_fkey";

-- DropIndex
DROP INDEX "UserRole_userId_roleId_key";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "emailVerifiedAt" TIMESTAMP(3),
ADD COLUMN     "lastLoginAt" TIMESTAMP(3),
ALTER COLUMN "email" SET DATA TYPE VARCHAR(320),
ALTER COLUMN "phone" SET DATA TYPE VARCHAR(32),
ALTER COLUMN "passwordHash" SET DATA TYPE VARCHAR(255),
ALTER COLUMN "firstName" SET DATA TYPE VARCHAR(100),
ALTER COLUMN "lastName" SET DATA TYPE VARCHAR(100);

-- Preserve and map any historical free-form statuses; unknown values are disabled.
ALTER TABLE "User" RENAME COLUMN "status" TO "legacyStatus";
ALTER TABLE "User" ALTER COLUMN "legacyStatus" TYPE TEXT,
ALTER COLUMN "legacyStatus" DROP NOT NULL;
ALTER TABLE "User" ADD COLUMN "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE';
UPDATE "User" SET "status" = CASE
  WHEN upper("legacyStatus") = 'ACTIVE' AND NOT "isActive"
    THEN 'DISABLED'::"UserStatus"
  WHEN upper("legacyStatus") IN ('ACTIVE', 'INVITED', 'SUSPENDED', 'DISABLED')
    THEN upper("legacyStatus")::"UserStatus"
  WHEN NOT "isActive" THEN 'DISABLED'::"UserStatus"
  ELSE 'SUSPENDED'::"UserStatus"
END;

-- AlterTable
ALTER TABLE "Role" ALTER COLUMN "description" SET DATA TYPE VARCHAR(500);

-- AlterTable
ALTER TABLE "Permission" ALTER COLUMN "description" SET DATA TYPE VARCHAR(500);

-- AlterTable
ALTER TABLE "UserRole" ADD COLUMN     "organizationId" TEXT;

-- AlterTable
ALTER TABLE "Organization" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ALTER COLUMN "name" SET DATA TYPE VARCHAR(200),
ALTER COLUMN "slug" SET DATA TYPE VARCHAR(120);

-- Preserve the old string type and map it to the constrained organization enum.
ALTER TABLE "Organization" RENAME COLUMN "type" TO "legacyType";
ALTER TABLE "Organization" ALTER COLUMN "legacyType" TYPE TEXT,
ALTER COLUMN "legacyType" DROP NOT NULL;
ALTER TABLE "Organization" ADD COLUMN "type" "OrganizationType" NOT NULL DEFAULT 'OTHER';
UPDATE "Organization" SET "type" = CASE upper("legacyType")
  WHEN 'UNIVERSITY' THEN 'UNIVERSITY'::"OrganizationType"
  WHEN 'COMPANY' THEN 'COMPANY'::"OrganizationType"
  WHEN 'STUDENT_UNION' THEN 'STUDENT_UNION'::"OrganizationType"
  WHEN 'FINANCIAL_OFFICE' THEN 'FINANCIAL_OFFICE'::"OrganizationType"
  WHEN 'DORMITORY' THEN 'DORMITORY'::"OrganizationType"
  ELSE 'OTHER'::"OrganizationType"
END;
ALTER TABLE "Organization" ALTER COLUMN "type" DROP DEFAULT;

-- AlterTable
ALTER TABLE "OrganizationMember" ADD COLUMN     "leftAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Department" ALTER COLUMN "name" SET DATA TYPE VARCHAR(160),
ALTER COLUMN "code" SET DATA TYPE VARCHAR(40);

-- AlterTable
ALTER TABLE "StudentProfile" ADD COLUMN     "departmentId" TEXT,
ADD COLUMN     "programId" TEXT,
ADD COLUMN     "universityId" TEXT,
ALTER COLUMN "studentNumber" SET DATA TYPE VARCHAR(80),
ALTER COLUMN "gpa" SET DATA TYPE DECIMAL(5,2);

-- AlterTable
ALTER TABLE "CompanyProfile" ADD COLUMN     "organizationId" TEXT,
ALTER COLUMN "companyName" SET DATA TYPE VARCHAR(200),
ALTER COLUMN "website" SET DATA TYPE VARCHAR(500),
ALTER COLUMN "industry" SET DATA TYPE VARCHAR(120);

-- Attach each legacy profile to the organization inserted for that profile.
-- Slug collisions are resolved with a suffix; an ID collision is a hard error.
DO $$
DECLARE
  company RECORD;
  generated_id TEXT;
  base_slug TEXT;
  candidate_slug TEXT;
  suffix INTEGER;
BEGIN
  FOR company IN
    SELECT "id", "companyName" FROM "CompanyProfile" ORDER BY "id"
  LOOP
    generated_id := 'legacy-company-' || substr(md5(company."id"), 1, 24);
    IF EXISTS (SELECT 1 FROM "Organization" WHERE "id" = generated_id) THEN
      RAISE EXCEPTION 'Generated legacy organization ID already exists for company profile %', company."id";
    END IF;

    base_slug := generated_id;
    candidate_slug := base_slug;
    suffix := 0;
    WHILE EXISTS (SELECT 1 FROM "Organization" WHERE "slug" = candidate_slug) LOOP
      suffix := suffix + 1;
      candidate_slug := base_slug || '-' || suffix::TEXT;
    END LOOP;

    INSERT INTO "Organization" ("id", "name", "slug", "type", "createdAt", "updatedAt")
    VALUES (
      generated_id,
      company."companyName",
      candidate_slug,
      'COMPANY'::"OrganizationType",
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    );

    UPDATE "CompanyProfile"
    SET "organizationId" = generated_id
    WHERE "id" = company."id";
  END LOOP;
END $$;

-- Company-profile owners must belong to their newly associated organization.
INSERT INTO "OrganizationMember" ("id", "organizationId", "userId", "joinedAt")
SELECT
  'legacy-company-member-' || substr(md5(cp."id"), 1, 24),
  cp."organizationId",
  cp."userId",
  CURRENT_TIMESTAMP
FROM "CompanyProfile" cp
ON CONFLICT ("organizationId", "userId") DO NOTHING;

ALTER TABLE "CompanyProfile" ALTER COLUMN "organizationId" SET NOT NULL;

-- AlterTable
ALTER TABLE "CompanyVerification" ADD COLUMN     "evidenceDocumentId" TEXT;

-- AlterTable
ALTER TABLE "RefreshToken" ALTER COLUMN "tokenHash" SET DATA TYPE VARCHAR(255);

-- AlterTable
ALTER TABLE "LoginSession" ADD COLUMN     "revokedAt" TIMESTAMP(3),
ALTER COLUMN "tokenHash" SET DATA TYPE VARCHAR(255),
ALTER COLUMN "device" SET DATA TYPE VARCHAR(255),
ALTER COLUMN "ipAddress" SET DATA TYPE VARCHAR(64);

-- CreateTable
CREATE TABLE "University" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "country" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "University_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Faculty" (
    "id" TEXT NOT NULL,
    "universityId" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "code" VARCHAR(40),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Faculty_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AcademicProgram" (
    "id" TEXT NOT NULL,
    "universityId" TEXT NOT NULL,
    "facultyId" TEXT,
    "departmentId" TEXT,
    "name" VARCHAR(160) NOT NULL,
    "code" VARCHAR(40),
    "degreeLevel" VARCHAR(40),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AcademicProgram_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AcademicYear" (
    "id" TEXT NOT NULL,
    "universityId" TEXT NOT NULL,
    "name" VARCHAR(40) NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AcademicYear_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Semester" (
    "id" TEXT NOT NULL,
    "academicYearId" TEXT NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Semester_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DepartmentAdvisor" (
    "id" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "advisorId" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endsAt" TIMESTAMP(3),

    CONSTRAINT "DepartmentAdvisor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganizationInvitation" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "email" VARCHAR(320) NOT NULL,
    "role" "RoleName" NOT NULL,
    "tokenHash" VARCHAR(255) NOT NULL,
    "status" "InvitationStatus" NOT NULL DEFAULT 'PENDING',
    "invitedById" TEXT NOT NULL,
    "invitedUserId" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "acceptedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OrganizationInvitation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganizationSetting" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "key" VARCHAR(120) NOT NULL,
    "value" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganizationSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipProgram" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "createdById" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "status" "InternshipStatus" NOT NULL DEFAULT 'DRAFT',
    "startsAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "applicationDeadline" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "InternshipProgram_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipPosition" (
    "id" TEXT NOT NULL,
    "programId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "openings" INTEGER NOT NULL DEFAULT 1,
    "status" "InternshipStatus" NOT NULL DEFAULT 'DRAFT',
    "location" VARCHAR(200),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InternshipPosition_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipSkill" (
    "id" TEXT NOT NULL,
    "positionId" TEXT NOT NULL,
    "skillId" TEXT NOT NULL,
    "required" BOOLEAN NOT NULL DEFAULT true,
    "proficiencyLevel" INTEGER,

    CONSTRAINT "InternshipSkill_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Skill" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "category" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Skill_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentSkill" (
    "id" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "skillId" TEXT NOT NULL,
    "proficiencyLevel" INTEGER NOT NULL,
    "evidenceDocumentId" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudentSkill_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Application" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "programId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "positionId" TEXT NOT NULL,
    "submittedById" TEXT,
    "status" "ApplicationStatus" NOT NULL DEFAULT 'DRAFT',
    "coverLetter" TEXT,
    "submittedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Application_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApplicationDocument" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "documentType" VARCHAR(80) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ApplicationDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApplicationStatusHistory" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "fromStatus" "ApplicationStatus",
    "toStatus" "ApplicationStatus" NOT NULL,
    "changedById" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ApplicationStatusHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EligibilityRule" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "programId" TEXT,
    "positionId" TEXT,
    "name" VARCHAR(160) NOT NULL,
    "ruleDefinition" JSONB NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EligibilityRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EligibilityCheck" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "ruleId" TEXT NOT NULL,
    "status" "EligibilityStatus" NOT NULL DEFAULT 'PENDING',
    "result" JSONB,
    "checkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EligibilityCheck_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Invitation" (
    "id" TEXT NOT NULL,
    "programId" TEXT NOT NULL,
    "applicationId" TEXT,
    "senderId" TEXT NOT NULL,
    "recipientId" TEXT NOT NULL,
    "status" "InvitationStatus" NOT NULL DEFAULT 'PENDING',
    "message" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "respondedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Invitation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Interview" (
    "id" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "positionId" TEXT NOT NULL,
    "interviewerId" TEXT NOT NULL,
    "inviteeId" TEXT NOT NULL,
    "status" "InterviewStatus" NOT NULL DEFAULT 'SCHEDULED',
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "location" VARCHAR(500),
    "meetingUrl" VARCHAR(1000),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Interview_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InterviewFeedback" (
    "id" TEXT NOT NULL,
    "interviewId" TEXT NOT NULL,
    "rating" INTEGER,
    "notes" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InterviewFeedback_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Placement" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "applicationId" TEXT NOT NULL,
    "positionId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "status" "PlacementStatus" NOT NULL DEFAULT 'ACTIVE',
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Placement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipAgreement" (
    "id" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "documentId" TEXT,
    "signedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InternshipAgreement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipTeam" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InternshipTeam_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeamMember" (
    "id" TEXT NOT NULL,
    "teamId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),

    CONSTRAINT "TeamMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdvisorAssignment" (
    "id" TEXT NOT NULL,
    "teamId" TEXT NOT NULL,
    "advisorId" TEXT NOT NULL,
    "assignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),

    CONSTRAINT "AdvisorAssignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeamTask" (
    "id" TEXT NOT NULL,
    "teamId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "status" "TaskStatus" NOT NULL DEFAULT 'TODO',
    "assigneeId" TEXT,
    "creatorId" TEXT NOT NULL,
    "dueAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TeamTask_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TaskComment" (
    "id" TEXT NOT NULL,
    "taskId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TaskComment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TaskAttachment" (
    "id" TEXT NOT NULL,
    "taskId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TaskAttachment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Meeting" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT,
    "teamId" TEXT,
    "creatorId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "location" VARCHAR(500),
    "meetingUrl" VARCHAR(1000),
    "status" "MeetingStatus" NOT NULL DEFAULT 'SCHEDULED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Meeting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeetingParticipant" (
    "id" TEXT NOT NULL,
    "meetingId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "invitedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondedAt" TIMESTAMP(3),

    CONSTRAINT "MeetingParticipant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceRecord" (
    "id" TEXT NOT NULL,
    "meetingId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "present" BOOLEAN NOT NULL DEFAULT false,
    "checkedInAt" TIMESTAMP(3),
    "note" TEXT,

    CONSTRAINT "AttendanceRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentationPlan" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DocumentationPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentationEntry" (
    "id" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "body" TEXT,
    "documentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DocumentationEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ImplementationMilestone" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "dueAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "sortOrder" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ImplementationMilestone_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Submission" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "status" "SubmissionStatus" NOT NULL DEFAULT 'DRAFT',
    "submittedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Submission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubmissionVersion" (
    "id" TEXT NOT NULL,
    "submissionId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "documentId" TEXT NOT NULL,
    "checksum" VARCHAR(128),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SubmissionVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "submissionId" TEXT NOT NULL,
    "rubricId" TEXT,
    "status" "ReviewStatus" NOT NULL DEFAULT 'PENDING',
    "score" DECIMAL(7,2),
    "summary" TEXT,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReviewComment" (
    "id" TEXT NOT NULL,
    "reviewId" TEXT NOT NULL,
    "authorId" TEXT,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ReviewComment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EvaluationRubric" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "name" VARCHAR(180) NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EvaluationRubric_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EvaluationCriterion" (
    "id" TEXT NOT NULL,
    "rubricId" TEXT NOT NULL,
    "name" VARCHAR(180) NOT NULL,
    "description" TEXT,
    "maxScore" DECIMAL(7,2) NOT NULL,
    "weight" DECIMAL(7,4) NOT NULL DEFAULT 1,
    "sortOrder" INTEGER NOT NULL,

    CONSTRAINT "EvaluationCriterion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EvaluationResult" (
    "id" TEXT NOT NULL,
    "reviewId" TEXT NOT NULL,
    "submissionId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "criterionId" TEXT,
    "score" DECIMAL(7,2) NOT NULL,
    "feedback" TEXT,
    "publishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EvaluationResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Document" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "ownerUserId" TEXT NOT NULL,
    "storageKey" VARCHAR(500) NOT NULL,
    "originalName" VARCHAR(255) NOT NULL,
    "mimeType" VARCHAR(160) NOT NULL,
    "sizeBytes" BIGINT NOT NULL,
    "checksum" VARCHAR(128),
    "status" "DocumentStatus" NOT NULL DEFAULT 'UPLOADED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentVersion" (
    "id" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "storageKey" VARCHAR(500) NOT NULL,
    "checksum" VARCHAR(128),
    "sizeBytes" BIGINT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DocumentVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentAccessGrant" (
    "id" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "grantedToId" TEXT NOT NULL,
    "grantedById" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "DocumentAccessGrant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentVerification" (
    "id" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "verifierId" TEXT,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "notes" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DocumentVerification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OfficialDocument" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "issuedById" TEXT NOT NULL,
    "documentNumber" VARCHAR(100) NOT NULL,
    "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "OfficialDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GeneratedDocument" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "templateKey" VARCHAR(120) NOT NULL,
    "requestedById" TEXT NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GeneratedDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PresentationSchedule" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "scheduledById" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "location" VARCHAR(500),
    "status" "PresentationStatus" NOT NULL DEFAULT 'SCHEDULED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PresentationSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PresentationPanelMember" (
    "id" TEXT NOT NULL,
    "scheduleId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "PresentationPanelMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PresentationResult" (
    "id" TEXT NOT NULL,
    "scheduleId" TEXT NOT NULL,
    "score" DECIMAL(7,2),
    "feedback" TEXT,
    "finalizedAt" TIMESTAMP(3),

    CONSTRAINT "PresentationResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FinalResult" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "placementId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "outcome" VARCHAR(80) NOT NULL,
    "finalScore" DECIMAL(7,2),
    "publishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FinalResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Dormitory" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "address" TEXT,
    "managerId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Dormitory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Room" (
    "id" TEXT NOT NULL,
    "dormitoryId" TEXT NOT NULL,
    "roomNumber" VARCHAR(40) NOT NULL,
    "capacity" INTEGER NOT NULL DEFAULT 1,
    "floor" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Room_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RoomAllocation" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "status" "AllocationStatus" NOT NULL DEFAULT 'RESERVED',
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "checkedInAt" TIMESTAMP(3),
    "checkedOutAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RoomAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DormitoryKey" (
    "id" TEXT NOT NULL,
    "dormitoryId" TEXT NOT NULL,
    "keyCode" VARCHAR(80) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "DormitoryKey_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KeyCheckout" (
    "id" TEXT NOT NULL,
    "keyId" TEXT NOT NULL,
    "allocationId" TEXT NOT NULL,
    "checkedOutById" TEXT NOT NULL,
    "status" "KeyCheckoutStatus" NOT NULL DEFAULT 'CHECKED_OUT',
    "checkedOutAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "returnedAt" TIMESTAMP(3),

    CONSTRAINT "KeyCheckout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealCard" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "cardNumberHash" VARCHAR(255) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "MealCard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealTransaction" (
    "id" TEXT NOT NULL,
    "mealCardId" TEXT NOT NULL,
    "merchant" VARCHAR(160) NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "referenceHash" VARCHAR(255),

    CONSTRAINT "MealTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FinancialSupportRequest" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "status" "SupportStatus" NOT NULL DEFAULT 'SUBMITTED',
    "requestedAmount" DECIMAL(12,2) NOT NULL,
    "approvedAmount" DECIMAL(12,2),
    "currency" CHAR(3) NOT NULL DEFAULT 'USD',
    "reason" TEXT NOT NULL,
    "reviewerId" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FinancialSupportRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "supportRequestId" TEXT,
    "amount" DECIMAL(12,2) NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'USD',
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "providerReferenceHash" VARCHAR(255),
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "channel" "NotificationChannel" NOT NULL DEFAULT 'IN_APP',
    "status" "NotificationStatus" NOT NULL DEFAULT 'PENDING',
    "title" VARCHAR(200) NOT NULL,
    "body" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "scheduledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sentAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NotificationPreference" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "emailEnabled" BOOLEAN NOT NULL DEFAULT true,
    "smsEnabled" BOOLEAN NOT NULL DEFAULT false,
    "inAppEnabled" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NotificationPreference_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Conversation" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "createdById" TEXT NOT NULL,
    "subject" VARCHAR(200),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "closedAt" TIMESTAMP(3),

    CONSTRAINT "Conversation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConversationParticipant" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),
    "lastReadAt" TIMESTAMP(3),

    CONSTRAINT "ConversationParticipant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Message" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "type" "MessageType" NOT NULL DEFAULT 'TEXT',
    "body" TEXT,
    "documentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "editedAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReportDefinition" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "createdById" TEXT NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "specification" JSONB NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReportDefinition_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT,
    "actorUserId" TEXT,
    "action" VARCHAR(120) NOT NULL,
    "entityType" VARCHAR(120) NOT NULL,
    "entityId" VARCHAR(120),
    "requestId" VARCHAR(120),
    "metadata" JSONB,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CVExtraction" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "requestedById" TEXT NOT NULL,
    "status" "AIJobStatus" NOT NULL DEFAULT 'QUEUED',
    "extractedData" JSONB,
    "modelVersion" VARCHAR(100),
    "errorCode" VARCHAR(80),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "CVExtraction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SkillAssessment" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "skillId" TEXT,
    "reviewedById" TEXT,
    "score" DECIMAL(7,2),
    "confidence" DECIMAL(5,4),
    "evidence" JSONB,
    "modelVersion" VARCHAR(100),
    "assessedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SkillAssessment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InternshipRecommendation" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "studentProfileId" TEXT NOT NULL,
    "positionId" TEXT NOT NULL,
    "score" DECIMAL(7,4) NOT NULL,
    "explanation" TEXT,
    "modelVersion" VARCHAR(100) NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InternshipRecommendation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AIJob" (
    "id" TEXT NOT NULL,
    "organizationId" TEXT,
    "requestedById" TEXT,
    "type" "AIJobType" NOT NULL,
    "status" "AIJobStatus" NOT NULL DEFAULT 'QUEUED',
    "inputReference" VARCHAR(500),
    "resultReference" VARCHAR(500),
    "errorCode" VARCHAR(80),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "AIJob_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SystemSetting" (
    "id" TEXT NOT NULL,
    "key" VARCHAR(160) NOT NULL,
    "value" JSONB NOT NULL,
    "description" VARCHAR(500),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SystemSetting_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "University_organizationId_key" ON "University"("organizationId");

-- CreateIndex
CREATE INDEX "University_name_idx" ON "University"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Faculty_universityId_name_key" ON "Faculty"("universityId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Faculty_universityId_code_key" ON "Faculty"("universityId", "code");

-- CreateIndex
CREATE INDEX "AcademicProgram_facultyId_departmentId_idx" ON "AcademicProgram"("facultyId", "departmentId");

-- CreateIndex
CREATE UNIQUE INDEX "AcademicProgram_universityId_name_key" ON "AcademicProgram"("universityId", "name");

-- CreateIndex
CREATE INDEX "AcademicYear_universityId_startsAt_endsAt_idx" ON "AcademicYear"("universityId", "startsAt", "endsAt");

-- CreateIndex
CREATE UNIQUE INDEX "AcademicYear_universityId_name_key" ON "AcademicYear"("universityId", "name");

-- CreateIndex
CREATE INDEX "Semester_startsAt_endsAt_idx" ON "Semester"("startsAt", "endsAt");

-- CreateIndex
CREATE UNIQUE INDEX "Semester_academicYearId_name_key" ON "Semester"("academicYearId", "name");

-- CreateIndex
CREATE INDEX "DepartmentAdvisor_advisorId_endsAt_idx" ON "DepartmentAdvisor"("advisorId", "endsAt");

-- CreateIndex
CREATE UNIQUE INDEX "DepartmentAdvisor_departmentId_advisorId_startsAt_key" ON "DepartmentAdvisor"("departmentId", "advisorId", "startsAt");

-- CreateIndex
CREATE UNIQUE INDEX "OrganizationInvitation_tokenHash_key" ON "OrganizationInvitation"("tokenHash");

-- CreateIndex
CREATE INDEX "OrganizationInvitation_organizationId_status_expiresAt_idx" ON "OrganizationInvitation"("organizationId", "status", "expiresAt");

-- CreateIndex
CREATE INDEX "OrganizationInvitation_email_status_idx" ON "OrganizationInvitation"("email", "status");

-- CreateIndex
CREATE UNIQUE INDEX "OrganizationSetting_organizationId_key_key" ON "OrganizationSetting"("organizationId", "key");

-- CreateIndex
CREATE INDEX "InternshipProgram_organizationId_status_applicationDeadline_idx" ON "InternshipProgram"("organizationId", "status", "applicationDeadline");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipProgram_id_organizationId_key" ON "InternshipProgram"("id", "organizationId");

-- CreateIndex
CREATE INDEX "InternshipPosition_programId_status_idx" ON "InternshipPosition"("programId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipPosition_id_programId_key" ON "InternshipPosition"("id", "programId");

-- CreateIndex
CREATE INDEX "InternshipSkill_skillId_idx" ON "InternshipSkill"("skillId");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipSkill_positionId_skillId_key" ON "InternshipSkill"("positionId", "skillId");

-- CreateIndex
CREATE UNIQUE INDEX "Skill_name_key" ON "Skill"("name");

-- CreateIndex
CREATE INDEX "Skill_category_name_idx" ON "Skill"("category", "name");

-- CreateIndex
CREATE INDEX "StudentSkill_skillId_proficiencyLevel_idx" ON "StudentSkill"("skillId", "proficiencyLevel");

-- CreateIndex
CREATE UNIQUE INDEX "StudentSkill_studentProfileId_skillId_key" ON "StudentSkill"("studentProfileId", "skillId");

-- CreateIndex
CREATE INDEX "Application_organizationId_status_submittedAt_idx" ON "Application"("organizationId", "status", "submittedAt");

-- CreateIndex
CREATE INDEX "Application_positionId_status_idx" ON "Application"("positionId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Application_studentProfileId_positionId_key" ON "Application"("studentProfileId", "positionId");

-- CreateIndex
CREATE UNIQUE INDEX "Application_id_positionId_studentProfileId_organizationId_key" ON "Application"("id", "positionId", "studentProfileId", "organizationId");

-- CreateIndex
CREATE INDEX "ApplicationDocument_documentId_idx" ON "ApplicationDocument"("documentId");

-- CreateIndex
CREATE UNIQUE INDEX "ApplicationDocument_applicationId_documentId_key" ON "ApplicationDocument"("applicationId", "documentId");

-- CreateIndex
CREATE INDEX "ApplicationStatusHistory_applicationId_createdAt_idx" ON "ApplicationStatusHistory"("applicationId", "createdAt");

-- CreateIndex
CREATE INDEX "EligibilityRule_programId_isActive_idx" ON "EligibilityRule"("programId", "isActive");

-- CreateIndex
CREATE INDEX "EligibilityRule_positionId_isActive_idx" ON "EligibilityRule"("positionId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "EligibilityRule_organizationId_name_key" ON "EligibilityRule"("organizationId", "name");

-- CreateIndex
CREATE INDEX "EligibilityCheck_status_checkedAt_idx" ON "EligibilityCheck"("status", "checkedAt");

-- CreateIndex
CREATE UNIQUE INDEX "EligibilityCheck_applicationId_ruleId_key" ON "EligibilityCheck"("applicationId", "ruleId");

-- CreateIndex
CREATE UNIQUE INDEX "Invitation_applicationId_key" ON "Invitation"("applicationId");

-- CreateIndex
CREATE INDEX "Invitation_recipientId_status_expiresAt_idx" ON "Invitation"("recipientId", "status", "expiresAt");

-- CreateIndex
CREATE INDEX "Invitation_programId_status_idx" ON "Invitation"("programId", "status");

-- CreateIndex
CREATE INDEX "Interview_interviewerId_startsAt_idx" ON "Interview"("interviewerId", "startsAt");

-- CreateIndex
CREATE INDEX "Interview_inviteeId_startsAt_idx" ON "Interview"("inviteeId", "startsAt");

-- CreateIndex
CREATE INDEX "Interview_applicationId_status_idx" ON "Interview"("applicationId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "InterviewFeedback_interviewId_key" ON "InterviewFeedback"("interviewId");

-- CreateIndex
CREATE UNIQUE INDEX "Placement_applicationId_key" ON "Placement"("applicationId");

-- CreateIndex
CREATE UNIQUE INDEX "Placement_applicationId_positionId_studentProfileId_key"
ON "Placement"("applicationId", "positionId", "studentProfileId");

-- CreateIndex
CREATE UNIQUE INDEX "Placement_applicationId_positionId_studentProfileId_organizationId_key"
ON "Placement"("applicationId", "positionId", "studentProfileId", "organizationId");

-- CreateIndex
CREATE UNIQUE INDEX "Placement_id_studentProfileId_key" ON "Placement"("id", "studentProfileId");

-- CreateIndex
CREATE INDEX "Placement_organizationId_status_startsAt_idx" ON "Placement"("organizationId", "status", "startsAt");

-- CreateIndex
CREATE INDEX "Placement_studentProfileId_status_idx" ON "Placement"("studentProfileId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipAgreement_placementId_key" ON "InternshipAgreement"("placementId");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipAgreement_documentId_key" ON "InternshipAgreement"("documentId");

-- CreateIndex
CREATE UNIQUE INDEX "InternshipTeam_placementId_key" ON "InternshipTeam"("placementId");

-- CreateIndex
CREATE INDEX "InternshipTeam_organizationId_idx" ON "InternshipTeam"("organizationId");

-- CreateIndex
CREATE INDEX "TeamMember_studentProfileId_leftAt_idx" ON "TeamMember"("studentProfileId", "leftAt");

-- CreateIndex
CREATE UNIQUE INDEX "TeamMember_teamId_studentProfileId_key" ON "TeamMember"("teamId", "studentProfileId");

-- CreateIndex
CREATE INDEX "AdvisorAssignment_advisorId_endedAt_idx" ON "AdvisorAssignment"("advisorId", "endedAt");

-- CreateIndex
CREATE UNIQUE INDEX "AdvisorAssignment_teamId_advisorId_assignedAt_key" ON "AdvisorAssignment"("teamId", "advisorId", "assignedAt");

-- CreateIndex
CREATE INDEX "TeamTask_teamId_status_dueAt_idx" ON "TeamTask"("teamId", "status", "dueAt");

-- CreateIndex
CREATE INDEX "TeamTask_assigneeId_status_idx" ON "TeamTask"("assigneeId", "status");

-- CreateIndex
CREATE INDEX "TaskComment_taskId_createdAt_idx" ON "TaskComment"("taskId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "TaskAttachment_taskId_documentId_key" ON "TaskAttachment"("taskId", "documentId");

-- CreateIndex
CREATE INDEX "Meeting_organizationId_startsAt_status_idx" ON "Meeting"("organizationId", "startsAt", "status");

-- CreateIndex
CREATE INDEX "MeetingParticipant_userId_respondedAt_idx" ON "MeetingParticipant"("userId", "respondedAt");

-- CreateIndex
CREATE UNIQUE INDEX "MeetingParticipant_meetingId_userId_key" ON "MeetingParticipant"("meetingId", "userId");

-- CreateIndex
CREATE INDEX "AttendanceRecord_studentProfileId_idx" ON "AttendanceRecord"("studentProfileId");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceRecord_meetingId_studentProfileId_key" ON "AttendanceRecord"("meetingId", "studentProfileId");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentationPlan_placementId_key" ON "DocumentationPlan"("placementId");

-- CreateIndex
CREATE INDEX "DocumentationPlan_organizationId_idx" ON "DocumentationPlan"("organizationId");

-- CreateIndex
CREATE INDEX "DocumentationEntry_planId_createdAt_idx" ON "DocumentationEntry"("planId", "createdAt");

-- CreateIndex
CREATE INDEX "ImplementationMilestone_organizationId_dueAt_idx" ON "ImplementationMilestone"("organizationId", "dueAt");

-- CreateIndex
CREATE UNIQUE INDEX "ImplementationMilestone_placementId_sortOrder_key" ON "ImplementationMilestone"("placementId", "sortOrder");

-- CreateIndex
CREATE INDEX "Submission_organizationId_status_submittedAt_idx" ON "Submission"("organizationId", "status", "submittedAt");

-- CreateIndex
CREATE INDEX "Submission_placementId_status_idx" ON "Submission"("placementId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Submission_id_placementId_key" ON "Submission"("id", "placementId");

-- CreateIndex
CREATE UNIQUE INDEX "SubmissionVersion_submissionId_version_key" ON "SubmissionVersion"("submissionId", "version");

-- CreateIndex
CREATE UNIQUE INDEX "SubmissionVersion_submissionId_documentId_key" ON "SubmissionVersion"("submissionId", "documentId");

-- CreateIndex
CREATE INDEX "Review_submissionId_status_idx" ON "Review"("submissionId", "status");

-- CreateIndex
CREATE INDEX "Review_rubricId_idx" ON "Review"("rubricId");

-- CreateIndex
CREATE UNIQUE INDEX "Review_id_submissionId_key" ON "Review"("id", "submissionId");

-- CreateIndex
CREATE INDEX "ReviewComment_reviewId_createdAt_idx" ON "ReviewComment"("reviewId", "createdAt");

-- CreateIndex
CREATE INDEX "EvaluationRubric_organizationId_isActive_idx" ON "EvaluationRubric"("organizationId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "EvaluationRubric_organizationId_name_version_key" ON "EvaluationRubric"("organizationId", "name", "version");

-- CreateIndex
CREATE UNIQUE INDEX "EvaluationCriterion_rubricId_name_key" ON "EvaluationCriterion"("rubricId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "EvaluationCriterion_rubricId_sortOrder_key" ON "EvaluationCriterion"("rubricId", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "EvaluationResult_reviewId_key" ON "EvaluationResult"("reviewId");

-- CreateIndex
CREATE UNIQUE INDEX "EvaluationResult_reviewId_submissionId_key" ON "EvaluationResult"("reviewId", "submissionId");

-- CreateIndex
CREATE INDEX "EvaluationResult_placementId_publishedAt_idx" ON "EvaluationResult"("placementId", "publishedAt");

-- CreateIndex
CREATE INDEX "EvaluationResult_studentProfileId_publishedAt_idx" ON "EvaluationResult"("studentProfileId", "publishedAt");

-- CreateIndex
CREATE UNIQUE INDEX "Document_storageKey_key" ON "Document"("storageKey");

-- CreateIndex
CREATE UNIQUE INDEX "Document_id_organizationId_key" ON "Document"("id", "organizationId");

-- CreateIndex
CREATE INDEX "Document_organizationId_status_createdAt_idx" ON "Document"("organizationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "Document_ownerUserId_createdAt_idx" ON "Document"("ownerUserId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentVersion_storageKey_key" ON "DocumentVersion"("storageKey");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentVersion_documentId_version_key" ON "DocumentVersion"("documentId", "version");

-- CreateIndex
CREATE INDEX "DocumentAccessGrant_grantedToId_expiresAt_revokedAt_idx" ON "DocumentAccessGrant"("grantedToId", "expiresAt", "revokedAt");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentAccessGrant_documentId_grantedToId_key" ON "DocumentAccessGrant"("documentId", "grantedToId");

-- CreateIndex
CREATE INDEX "DocumentVerification_documentId_createdAt_idx" ON "DocumentVerification"("documentId", "createdAt");

-- CreateIndex
CREATE INDEX "DocumentVerification_status_createdAt_idx" ON "DocumentVerification"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "OfficialDocument_documentId_key" ON "OfficialDocument"("documentId");

-- CreateIndex
CREATE UNIQUE INDEX "OfficialDocument_documentNumber_key" ON "OfficialDocument"("documentNumber");

-- CreateIndex
CREATE INDEX "OfficialDocument_organizationId_issuedAt_idx" ON "OfficialDocument"("organizationId", "issuedAt");

-- CreateIndex
CREATE UNIQUE INDEX "GeneratedDocument_documentId_key" ON "GeneratedDocument"("documentId");

-- CreateIndex
CREATE INDEX "GeneratedDocument_organizationId_generatedAt_idx" ON "GeneratedDocument"("organizationId", "generatedAt");

-- CreateIndex
CREATE INDEX "PresentationSchedule_organizationId_startsAt_status_idx" ON "PresentationSchedule"("organizationId", "startsAt", "status");

-- CreateIndex
CREATE INDEX "PresentationSchedule_placementId_startsAt_idx" ON "PresentationSchedule"("placementId", "startsAt");

-- CreateIndex
CREATE UNIQUE INDEX "PresentationPanelMember_scheduleId_userId_key" ON "PresentationPanelMember"("scheduleId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "PresentationResult_scheduleId_key" ON "PresentationResult"("scheduleId");

-- CreateIndex
CREATE UNIQUE INDEX "FinalResult_placementId_key" ON "FinalResult"("placementId");

-- CreateIndex
CREATE UNIQUE INDEX "FinalResult_placementId_studentProfileId_key" ON "FinalResult"("placementId", "studentProfileId");

-- CreateIndex
CREATE INDEX "FinalResult_organizationId_publishedAt_idx" ON "FinalResult"("organizationId", "publishedAt");

-- CreateIndex
CREATE INDEX "FinalResult_studentProfileId_publishedAt_idx" ON "FinalResult"("studentProfileId", "publishedAt");

-- CreateIndex
CREATE UNIQUE INDEX "Dormitory_organizationId_name_key" ON "Dormitory"("organizationId", "name");

-- CreateIndex
CREATE INDEX "Room_dormitoryId_floor_idx" ON "Room"("dormitoryId", "floor");

-- CreateIndex
CREATE UNIQUE INDEX "Room_dormitoryId_roomNumber_key" ON "Room"("dormitoryId", "roomNumber");

-- CreateIndex
CREATE INDEX "RoomAllocation_roomId_status_startsAt_endsAt_idx" ON "RoomAllocation"("roomId", "status", "startsAt", "endsAt");

-- CreateIndex
CREATE INDEX "RoomAllocation_studentProfileId_status_idx" ON "RoomAllocation"("studentProfileId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "DormitoryKey_dormitoryId_keyCode_key" ON "DormitoryKey"("dormitoryId", "keyCode");

-- CreateIndex
CREATE INDEX "KeyCheckout_keyId_status_idx" ON "KeyCheckout"("keyId", "status");

-- CreateIndex
CREATE INDEX "KeyCheckout_allocationId_status_idx" ON "KeyCheckout"("allocationId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "MealCard_studentProfileId_key" ON "MealCard"("studentProfileId");

-- CreateIndex
CREATE UNIQUE INDEX "MealCard_cardNumberHash_key" ON "MealCard"("cardNumberHash");

-- CreateIndex
CREATE INDEX "MealCard_organizationId_isActive_idx" ON "MealCard"("organizationId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "MealTransaction_referenceHash_key" ON "MealTransaction"("referenceHash");

-- CreateIndex
CREATE INDEX "MealTransaction_mealCardId_occurredAt_idx" ON "MealTransaction"("mealCardId", "occurredAt");

-- CreateIndex
CREATE INDEX "FinancialSupportRequest_organizationId_status_createdAt_idx" ON "FinancialSupportRequest"("organizationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "FinancialSupportRequest_studentProfileId_status_idx" ON "FinancialSupportRequest"("studentProfileId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "FinancialSupportRequest_id_studentProfileId_organizationId_key"
ON "FinancialSupportRequest"("id", "studentProfileId", "organizationId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_providerReferenceHash_key" ON "Payment"("providerReferenceHash");

-- CreateIndex
CREATE INDEX "Payment_organizationId_status_createdAt_idx" ON "Payment"("organizationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "Payment_studentProfileId_status_idx" ON "Payment"("studentProfileId", "status");

-- CreateIndex
CREATE INDEX "Notification_organizationId_status_scheduledAt_idx" ON "Notification"("organizationId", "status", "scheduledAt");

-- CreateIndex
CREATE INDEX "Notification_userId_readAt_createdAt_idx" ON "Notification"("userId", "readAt", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationPreference_userId_key" ON "NotificationPreference"("userId");

-- CreateIndex
CREATE INDEX "Conversation_organizationId_updatedAt_idx" ON "Conversation"("organizationId", "updatedAt");

-- CreateIndex
CREATE INDEX "ConversationParticipant_userId_leftAt_idx" ON "ConversationParticipant"("userId", "leftAt");

-- CreateIndex
CREATE UNIQUE INDEX "ConversationParticipant_conversationId_userId_key" ON "ConversationParticipant"("conversationId", "userId");

-- CreateIndex
CREATE INDEX "Message_conversationId_createdAt_idx" ON "Message"("conversationId", "createdAt");

-- CreateIndex
CREATE INDEX "Message_senderId_createdAt_idx" ON "Message"("senderId", "createdAt");

-- CreateIndex
CREATE INDEX "ReportDefinition_organizationId_isActive_idx" ON "ReportDefinition"("organizationId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "ReportDefinition_organizationId_name_key" ON "ReportDefinition"("organizationId", "name");

-- CreateIndex
CREATE INDEX "AuditLog_organizationId_occurredAt_idx" ON "AuditLog"("organizationId", "occurredAt");

-- CreateIndex
CREATE INDEX "AuditLog_actorUserId_occurredAt_idx" ON "AuditLog"("actorUserId", "occurredAt");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_occurredAt_idx" ON "AuditLog"("entityType", "entityId", "occurredAt");

-- CreateIndex
CREATE INDEX "AuditLog_requestId_idx" ON "AuditLog"("requestId");

-- CreateIndex
CREATE INDEX "CVExtraction_organizationId_status_createdAt_idx" ON "CVExtraction"("organizationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "CVExtraction_studentProfileId_createdAt_idx" ON "CVExtraction"("studentProfileId", "createdAt");

-- CreateIndex
CREATE INDEX "SkillAssessment_organizationId_assessedAt_idx" ON "SkillAssessment"("organizationId", "assessedAt");

-- CreateIndex
CREATE INDEX "SkillAssessment_studentProfileId_skillId_assessedAt_idx" ON "SkillAssessment"("studentProfileId", "skillId", "assessedAt");

-- CreateIndex
CREATE INDEX "InternshipRecommendation_organizationId_studentProfileId_sc_idx" ON "InternshipRecommendation"("organizationId", "studentProfileId", "score" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "InternshipRecommendation_studentProfileId_positionId_modelV_key" ON "InternshipRecommendation"("studentProfileId", "positionId", "modelVersion");

-- CreateIndex
CREATE INDEX "AIJob_organizationId_status_createdAt_idx" ON "AIJob"("organizationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "AIJob_type_status_createdAt_idx" ON "AIJob"("type", "status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "SystemSetting_key_key" ON "SystemSetting"("key");

-- CreateIndex
CREATE INDEX "User_status_deletedAt_idx" ON "User"("status", "deletedAt");

-- CreateIndex
CREATE INDEX "UserRole_organizationId_roleId_idx" ON "UserRole"("organizationId", "roleId");

-- CreateIndex
CREATE INDEX "UserRole_userId_roleId_idx" ON "UserRole"("userId", "roleId");

-- CreateIndex
CREATE UNIQUE INDEX "UserRole_userId_roleId_organizationId_key" ON "UserRole"("userId", "roleId", "organizationId");

-- CreateIndex
CREATE UNIQUE INDEX "UserRole_global_userId_roleId_key"
ON "UserRole"("userId", "roleId")
WHERE "organizationId" IS NULL;

-- CreateIndex
CREATE INDEX "RolePermission_permissionId_idx" ON "RolePermission"("permissionId");

-- CreateIndex
CREATE INDEX "Organization_type_deletedAt_idx" ON "Organization"("type", "deletedAt");

-- CreateIndex
CREATE INDEX "OrganizationMember_userId_leftAt_idx" ON "OrganizationMember"("userId", "leftAt");

-- CreateIndex
CREATE INDEX "Department_organizationId_idx" ON "Department"("organizationId");

-- Keep the earliest row's code and clear duplicate codes before enforcing the
-- per-organization unique constraint.
WITH duplicate_department_codes AS (
  SELECT
    "id",
    row_number() OVER (
      PARTITION BY "organizationId", "code"
      ORDER BY "createdAt", "id"
    ) AS duplicate_number
  FROM "Department"
  WHERE "code" IS NOT NULL
)
UPDATE "Department" AS department
SET "code" = NULL
FROM duplicate_department_codes AS duplicate
WHERE department."id" = duplicate."id"
  AND duplicate.duplicate_number > 1;

-- CreateIndex
CREATE UNIQUE INDEX "Department_organizationId_code_key" ON "Department"("organizationId", "code");

-- CreateIndex
CREATE INDEX "StudentProfile_departmentId_programId_idx" ON "StudentProfile"("departmentId", "programId");

-- CreateIndex
CREATE UNIQUE INDEX "StudentProfile_universityId_studentNumber_key" ON "StudentProfile"("universityId", "studentNumber");

-- CreateIndex
CREATE INDEX "CompanyProfile_industry_idx" ON "CompanyProfile"("industry");

-- CreateIndex
CREATE UNIQUE INDEX "CompanyProfile_organizationId_key" ON "CompanyProfile"("organizationId");

-- CreateIndex
CREATE INDEX "CompanyVerification_status_createdAt_idx" ON "CompanyVerification"("status", "createdAt");

-- Ambiguous legacy bearer tokens must not remain usable under an arbitrary
-- user/session row after tokenHash uniqueness is enforced.
WITH duplicate_hashes AS (
  SELECT "tokenHash"
  FROM "RefreshToken"
  GROUP BY "tokenHash"
  HAVING COUNT(*) > 1
)
UPDATE "RefreshToken" AS token
SET "revokedAt" = COALESCE(token."revokedAt", CURRENT_TIMESTAMP)
FROM duplicate_hashes
WHERE token."tokenHash" = duplicate_hashes."tokenHash";

DELETE FROM "RefreshToken" AS duplicate
USING "RefreshToken" AS retained
WHERE duplicate."tokenHash" = retained."tokenHash"
  AND duplicate."id" > retained."id";

WITH duplicate_hashes AS (
  SELECT "tokenHash"
  FROM "LoginSession"
  GROUP BY "tokenHash"
  HAVING COUNT(*) > 1
)
UPDATE "LoginSession" AS session
SET "revokedAt" = COALESCE(session."revokedAt", CURRENT_TIMESTAMP)
FROM duplicate_hashes
WHERE session."tokenHash" = duplicate_hashes."tokenHash";

DELETE FROM "LoginSession" AS duplicate
USING "LoginSession" AS retained
WHERE duplicate."tokenHash" = retained."tokenHash"
  AND duplicate."id" > retained."id";

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_expiresAt_idx" ON "RefreshToken"("userId", "expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "LoginSession_tokenHash_key" ON "LoginSession"("tokenHash");

-- CreateIndex
CREATE INDEX "LoginSession_userId_expiresAt_idx" ON "LoginSession"("userId", "expiresAt");

-- AddForeignKey
ALTER TABLE "UserRole" ADD CONSTRAINT "UserRole_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserRole" ADD CONSTRAINT "UserRole_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationMember" ADD CONSTRAINT "OrganizationMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Department" ADD CONSTRAINT "Department_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentProfile" ADD CONSTRAINT "StudentProfile_programId_fkey" FOREIGN KEY ("programId") REFERENCES "AcademicProgram"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompanyProfile" ADD CONSTRAINT "CompanyProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompanyProfile" ADD CONSTRAINT "CompanyProfile_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompanyVerification" ADD CONSTRAINT "CompanyVerification_companyProfileId_fkey" FOREIGN KEY ("companyProfileId") REFERENCES "CompanyProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "University" ADD CONSTRAINT "University_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Faculty" ADD CONSTRAINT "Faculty_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AcademicProgram" ADD CONSTRAINT "AcademicProgram_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AcademicProgram" ADD CONSTRAINT "AcademicProgram_facultyId_fkey" FOREIGN KEY ("facultyId") REFERENCES "Faculty"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AcademicProgram" ADD CONSTRAINT "AcademicProgram_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AcademicYear" ADD CONSTRAINT "AcademicYear_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Semester" ADD CONSTRAINT "Semester_academicYearId_fkey" FOREIGN KEY ("academicYearId") REFERENCES "AcademicYear"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DepartmentAdvisor" ADD CONSTRAINT "DepartmentAdvisor_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "Department"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DepartmentAdvisor" ADD CONSTRAINT "DepartmentAdvisor_advisorId_fkey" FOREIGN KEY ("advisorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationInvitation" ADD CONSTRAINT "OrganizationInvitation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationInvitation" ADD CONSTRAINT "OrganizationInvitation_invitedById_fkey" FOREIGN KEY ("invitedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationInvitation" ADD CONSTRAINT "OrganizationInvitation_invitedUserId_fkey" FOREIGN KEY ("invitedUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationSetting" ADD CONSTRAINT "OrganizationSetting_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipProgram" ADD CONSTRAINT "InternshipProgram_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipProgram" ADD CONSTRAINT "InternshipProgram_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipPosition" ADD CONSTRAINT "InternshipPosition_programId_fkey" FOREIGN KEY ("programId") REFERENCES "InternshipProgram"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipSkill" ADD CONSTRAINT "InternshipSkill_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES "InternshipPosition"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipSkill" ADD CONSTRAINT "InternshipSkill_skillId_fkey" FOREIGN KEY ("skillId") REFERENCES "Skill"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentSkill" ADD CONSTRAINT "StudentSkill_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentSkill" ADD CONSTRAINT "StudentSkill_skillId_fkey" FOREIGN KEY ("skillId") REFERENCES "Skill"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Application" ADD CONSTRAINT "Application_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Application" ADD CONSTRAINT "Application_programId_organizationId_fkey"
FOREIGN KEY ("programId", "organizationId") REFERENCES "InternshipProgram"("id", "organizationId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Application" ADD CONSTRAINT "Application_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Application" ADD CONSTRAINT "Application_positionId_programId_fkey"
FOREIGN KEY ("positionId", "programId") REFERENCES "InternshipPosition"("id", "programId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Application" ADD CONSTRAINT "Application_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApplicationDocument" ADD CONSTRAINT "ApplicationDocument_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "Application"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApplicationDocument" ADD CONSTRAINT "ApplicationDocument_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApplicationStatusHistory" ADD CONSTRAINT "ApplicationStatusHistory_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "Application"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EligibilityRule" ADD CONSTRAINT "EligibilityRule_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EligibilityRule" ADD CONSTRAINT "EligibilityRule_programId_fkey" FOREIGN KEY ("programId") REFERENCES "InternshipProgram"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EligibilityRule" ADD CONSTRAINT "EligibilityRule_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES "InternshipPosition"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EligibilityCheck" ADD CONSTRAINT "EligibilityCheck_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "Application"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EligibilityCheck" ADD CONSTRAINT "EligibilityCheck_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "EligibilityRule"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_programId_fkey" FOREIGN KEY ("programId") REFERENCES "InternshipProgram"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "Application"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "Application"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES "InternshipPosition"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_interviewerId_fkey" FOREIGN KEY ("interviewerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_inviteeId_fkey" FOREIGN KEY ("inviteeId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InterviewFeedback" ADD CONSTRAINT "InterviewFeedback_interviewId_fkey" FOREIGN KEY ("interviewId") REFERENCES "Interview"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Placement" ADD CONSTRAINT "Placement_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Placement" ADD CONSTRAINT "Placement_applicationPositionStudent_fkey"
FOREIGN KEY ("applicationId", "positionId", "studentProfileId", "organizationId")
REFERENCES "Application"("id", "positionId", "studentProfileId", "organizationId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Placement" ADD CONSTRAINT "Placement_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES "InternshipPosition"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Placement" ADD CONSTRAINT "Placement_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipAgreement" ADD CONSTRAINT "InternshipAgreement_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipAgreement" ADD CONSTRAINT "InternshipAgreement_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipTeam" ADD CONSTRAINT "InternshipTeam_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipTeam" ADD CONSTRAINT "InternshipTeam_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamMember" ADD CONSTRAINT "TeamMember_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "InternshipTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamMember" ADD CONSTRAINT "TeamMember_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdvisorAssignment" ADD CONSTRAINT "AdvisorAssignment_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "InternshipTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdvisorAssignment" ADD CONSTRAINT "AdvisorAssignment_advisorId_fkey" FOREIGN KEY ("advisorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamTask" ADD CONSTRAINT "TeamTask_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "InternshipTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamTask" ADD CONSTRAINT "TeamTask_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamTask" ADD CONSTRAINT "TeamTask_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskComment" ADD CONSTRAINT "TaskComment_taskId_fkey" FOREIGN KEY ("taskId") REFERENCES "TeamTask"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskComment" ADD CONSTRAINT "TaskComment_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskAttachment" ADD CONSTRAINT "TaskAttachment_taskId_fkey" FOREIGN KEY ("taskId") REFERENCES "TeamTask"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskAttachment" ADD CONSTRAINT "TaskAttachment_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Meeting" ADD CONSTRAINT "Meeting_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Meeting" ADD CONSTRAINT "Meeting_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Meeting" ADD CONSTRAINT "Meeting_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "InternshipTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Meeting" ADD CONSTRAINT "Meeting_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingParticipant" ADD CONSTRAINT "MeetingParticipant_meetingId_fkey" FOREIGN KEY ("meetingId") REFERENCES "Meeting"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeetingParticipant" ADD CONSTRAINT "MeetingParticipant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceRecord" ADD CONSTRAINT "AttendanceRecord_meetingId_fkey" FOREIGN KEY ("meetingId") REFERENCES "Meeting"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceRecord" ADD CONSTRAINT "AttendanceRecord_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentationPlan" ADD CONSTRAINT "DocumentationPlan_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentationPlan" ADD CONSTRAINT "DocumentationPlan_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentationEntry" ADD CONSTRAINT "DocumentationEntry_planId_fkey" FOREIGN KEY ("planId") REFERENCES "DocumentationPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentationEntry" ADD CONSTRAINT "DocumentationEntry_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ImplementationMilestone" ADD CONSTRAINT "ImplementationMilestone_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ImplementationMilestone" ADD CONSTRAINT "ImplementationMilestone_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Submission" ADD CONSTRAINT "Submission_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Submission" ADD CONSTRAINT "Submission_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubmissionVersion" ADD CONSTRAINT "SubmissionVersion_submissionId_fkey" FOREIGN KEY ("submissionId") REFERENCES "Submission"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubmissionVersion" ADD CONSTRAINT "SubmissionVersion_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_submissionId_fkey" FOREIGN KEY ("submissionId") REFERENCES "Submission"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_rubricId_fkey" FOREIGN KEY ("rubricId") REFERENCES "EvaluationRubric"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReviewComment" ADD CONSTRAINT "ReviewComment_reviewId_fkey" FOREIGN KEY ("reviewId") REFERENCES "Review"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationRubric" ADD CONSTRAINT "EvaluationRubric_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationCriterion" ADD CONSTRAINT "EvaluationCriterion_rubricId_fkey" FOREIGN KEY ("rubricId") REFERENCES "EvaluationRubric"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationResult" ADD CONSTRAINT "EvaluationResult_reviewId_submissionId_fkey"
FOREIGN KEY ("reviewId", "submissionId") REFERENCES "Review"("id", "submissionId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationResult" ADD CONSTRAINT "EvaluationResult_submissionId_placementId_fkey"
FOREIGN KEY ("submissionId", "placementId") REFERENCES "Submission"("id", "placementId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationResult" ADD CONSTRAINT "EvaluationResult_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationResult" ADD CONSTRAINT "EvaluationResult_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvaluationResult" ADD CONSTRAINT "EvaluationResult_criterionId_fkey" FOREIGN KEY ("criterionId") REFERENCES "EvaluationCriterion"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Document" ADD CONSTRAINT "Document_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Document" ADD CONSTRAINT "Document_ownerUserId_fkey" FOREIGN KEY ("ownerUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentVersion" ADD CONSTRAINT "DocumentVersion_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAccessGrant" ADD CONSTRAINT "DocumentAccessGrant_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAccessGrant" ADD CONSTRAINT "DocumentAccessGrant_grantedToId_fkey" FOREIGN KEY ("grantedToId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAccessGrant" ADD CONSTRAINT "DocumentAccessGrant_grantedById_fkey" FOREIGN KEY ("grantedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentVerification" ADD CONSTRAINT "DocumentVerification_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentVerification" ADD CONSTRAINT "DocumentVerification_verifierId_fkey" FOREIGN KEY ("verifierId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OfficialDocument" ADD CONSTRAINT "OfficialDocument_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OfficialDocument" ADD CONSTRAINT "OfficialDocument_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OfficialDocument" ADD CONSTRAINT "OfficialDocument_issuedById_fkey" FOREIGN KEY ("issuedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GeneratedDocument" ADD CONSTRAINT "GeneratedDocument_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GeneratedDocument" ADD CONSTRAINT "GeneratedDocument_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationSchedule" ADD CONSTRAINT "PresentationSchedule_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationSchedule" ADD CONSTRAINT "PresentationSchedule_placementId_fkey" FOREIGN KEY ("placementId") REFERENCES "Placement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationSchedule" ADD CONSTRAINT "PresentationSchedule_scheduledById_fkey" FOREIGN KEY ("scheduledById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationPanelMember" ADD CONSTRAINT "PresentationPanelMember_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "PresentationSchedule"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationPanelMember" ADD CONSTRAINT "PresentationPanelMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PresentationResult" ADD CONSTRAINT "PresentationResult_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "PresentationSchedule"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinalResult" ADD CONSTRAINT "FinalResult_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinalResult" ADD CONSTRAINT "FinalResult_placementStudent_fkey"
FOREIGN KEY ("placementId", "studentProfileId") REFERENCES "Placement"("id", "studentProfileId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinalResult" ADD CONSTRAINT "FinalResult_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dormitory" ADD CONSTRAINT "Dormitory_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dormitory" ADD CONSTRAINT "Dormitory_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Room" ADD CONSTRAINT "Room_dormitoryId_fkey" FOREIGN KEY ("dormitoryId") REFERENCES "Dormitory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RoomAllocation" ADD CONSTRAINT "RoomAllocation_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "Room"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RoomAllocation" ADD CONSTRAINT "RoomAllocation_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DormitoryKey" ADD CONSTRAINT "DormitoryKey_dormitoryId_fkey" FOREIGN KEY ("dormitoryId") REFERENCES "Dormitory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KeyCheckout" ADD CONSTRAINT "KeyCheckout_keyId_fkey" FOREIGN KEY ("keyId") REFERENCES "DormitoryKey"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KeyCheckout" ADD CONSTRAINT "KeyCheckout_allocationId_fkey" FOREIGN KEY ("allocationId") REFERENCES "RoomAllocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KeyCheckout" ADD CONSTRAINT "KeyCheckout_checkedOutById_fkey" FOREIGN KEY ("checkedOutById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealCard" ADD CONSTRAINT "MealCard_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealCard" ADD CONSTRAINT "MealCard_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealTransaction" ADD CONSTRAINT "MealTransaction_mealCardId_fkey" FOREIGN KEY ("mealCardId") REFERENCES "MealCard"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinancialSupportRequest" ADD CONSTRAINT "FinancialSupportRequest_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinancialSupportRequest" ADD CONSTRAINT "FinancialSupportRequest_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinancialSupportRequest" ADD CONSTRAINT "FinancialSupportRequest_reviewerId_fkey" FOREIGN KEY ("reviewerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_supportRequestContext_fkey"
FOREIGN KEY ("supportRequestId", "studentProfileId", "organizationId")
REFERENCES "FinancialSupportRequest"("id", "studentProfileId", "organizationId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NotificationPreference" ADD CONSTRAINT "NotificationPreference_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Conversation" ADD CONSTRAINT "Conversation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Conversation" ADD CONSTRAINT "Conversation_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConversationParticipant" ADD CONSTRAINT "ConversationParticipant_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConversationParticipant" ADD CONSTRAINT "ConversationParticipant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReportDefinition" ADD CONSTRAINT "ReportDefinition_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReportDefinition" ADD CONSTRAINT "ReportDefinition_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CVExtraction" ADD CONSTRAINT "CVExtraction_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CVExtraction" ADD CONSTRAINT "CVExtraction_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CVExtraction" ADD CONSTRAINT "CVExtraction_documentOrganization_fkey"
FOREIGN KEY ("documentId", "organizationId")
REFERENCES "Document"("id", "organizationId")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CVExtraction" ADD CONSTRAINT "CVExtraction_requestedById_fkey" FOREIGN KEY ("requestedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SkillAssessment" ADD CONSTRAINT "SkillAssessment_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SkillAssessment" ADD CONSTRAINT "SkillAssessment_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SkillAssessment" ADD CONSTRAINT "SkillAssessment_skillId_fkey" FOREIGN KEY ("skillId") REFERENCES "Skill"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SkillAssessment" ADD CONSTRAINT "SkillAssessment_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipRecommendation" ADD CONSTRAINT "InternshipRecommendation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipRecommendation" ADD CONSTRAINT "InternshipRecommendation_studentProfileId_fkey" FOREIGN KEY ("studentProfileId") REFERENCES "StudentProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InternshipRecommendation" ADD CONSTRAINT "InternshipRecommendation_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES "InternshipPosition"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AIJob" ADD CONSTRAINT "AIJob_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AIJob" ADD CONSTRAINT "AIJob_requestedById_fkey" FOREIGN KEY ("requestedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Foreign keys for optional relationships that already had scalar columns in
-- the inventory schema.
ALTER TABLE "CompanyVerification" ADD CONSTRAINT "CompanyVerification_evidenceDocumentId_fkey" FOREIGN KEY ("evidenceDocumentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "StudentSkill" ADD CONSTRAINT "StudentSkill_evidenceDocumentId_fkey" FOREIGN KEY ("evidenceDocumentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "ApplicationStatusHistory" ADD CONSTRAINT "ApplicationStatusHistory_changedById_fkey" FOREIGN KEY ("changedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "ReviewComment" ADD CONSTRAINT "ReviewComment_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "GeneratedDocument" ADD CONSTRAINT "GeneratedDocument_requestedById_fkey" FOREIGN KEY ("requestedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Message" ADD CONSTRAINT "Message_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE SET NULL ON UPDATE CASCADE;
