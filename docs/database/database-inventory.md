# InternLink database inventory

This document records the 86 Prisma models implemented in
`packages/database/prisma/schema.prisma`. The original 13 identity and
organization models remain the foundation; the other 73 inventory candidates
are now represented as Prisma models.

## Identity and access (13)

1. User
2. Role
3. Permission
4. UserRole
5. RolePermission
6. Organization
7. OrganizationMember
8. Department
9. StudentProfile
10. CompanyProfile
11. CompanyVerification
12. RefreshToken
13. LoginSession

## Institution structure (8)

14. University
15. Faculty
16. AcademicProgram
17. AcademicYear
18. Semester
19. DepartmentAdvisor
20. OrganizationInvitation
21. OrganizationSetting

## Internship opportunities and applications (13)

22. InternshipProgram
23. InternshipPosition
24. InternshipSkill
25. Skill
26. StudentSkill
27. Application
28. ApplicationDocument
29. ApplicationStatusHistory
30. EligibilityRule
31. EligibilityCheck
32. Invitation
33. Interview
34. InterviewFeedback

## Placement, teams, and supervision (11)

35. Placement
36. InternshipAgreement
37. InternshipTeam
38. TeamMember
39. AdvisorAssignment
40. TeamTask
41. TaskComment
42. TaskAttachment
43. Meeting
44. MeetingParticipant
45. AttendanceRecord

## Work submissions and evaluations (10)

46. DocumentationPlan
47. DocumentationEntry
48. ImplementationMilestone
49. Submission
50. SubmissionVersion
51. Review
52. ReviewComment
53. EvaluationRubric
54. EvaluationCriterion
55. EvaluationResult

## Documents and verification (10)

56. Document
57. DocumentVersion
58. DocumentAccessGrant
59. DocumentVerification
60. OfficialDocument
61. GeneratedDocument
62. PresentationSchedule
63. PresentationPanelMember
64. PresentationResult
65. FinalResult

## Student services and finance (9)

66. Dormitory
67. Room
68. RoomAllocation
69. DormitoryKey
70. KeyCheckout
71. MealCard
72. MealTransaction
73. FinancialSupportRequest
74. Payment

## Communication, reporting, and AI (7)

75. Notification
76. NotificationPreference
77. Conversation
78. ConversationParticipant
79. Message
80. ReportDefinition
81. AuditLog

## AI and operational records (5)

82. CVExtraction
83. SkillAssessment
84. InternshipRecommendation
85. AIJob
86. SystemSetting

## Relationship validation checklist

- Confirm whether company verification belongs to a company profile or to a separate organization record.
- Decide how organization membership, portal roles, and department-level permissions interact.
- Define immutable status history for applications, placements, submissions, and documents.
- Specify retention and deletion rules for CVs, generated documents, messages, audit records, and AI outputs.
- Review unique constraints for student academic identity, active placement, team membership, and payment references.
- Keep AI as an internal service and job producer; it is not a user, role, or actor in this inventory.

## Implementation notes

- The schema contains exactly the 86 model names in this inventory and exactly
  ten actor roles. AI job types are internal work categories, not actor roles.
- Organization-owned data carries `organizationId` directly or is reached
  through an organization-scoped parent. Prisma relations have primary/foreign
  keys, selected composite uniqueness constraints, and indexes for common
  organization-scoped lookups.
- Organization scoping must be applied by data-access code on every request;
  this schema does not enable PostgreSQL row-level security. Composite tenant
  foreign keys across every relationship are not implemented.
- Status fields use enums where their lifecycle is defined. Money, grades,
  scores, and financial support values use PostgreSQL decimal columns.
- Credentials, refresh tokens, and session tokens have hash fields. Files are
  represented by object-storage references and versions, not binary blobs.
- Soft deletion is used on users and organizations. Historical activity uses
  explicit history, audit, transaction, and version models; restrictive foreign
  keys protect many historical references, while join/child records cascade
  only where removal is appropriate.
- The Prisma schema evolved from the committed 13-model foundation. The follow-up
  migration adds the other 73 models and includes explicit conversions for the
  original free-form user status, organization type, and company-profile tenant
  association. Original status/type strings are retained in legacy columns; an
  unrecognized user status maps to `SUSPENDED`, and an unrecognized organization
  type maps to `OTHER`. The original migration remains unchanged.
