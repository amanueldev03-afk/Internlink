# Proposed 86-table database inventory

This is a planning inventory, not an instruction to generate all tables now. The initial Prisma schema contains only the 13 foundational models listed in `schema.prisma`. Before adding the remaining models, validate ownership, lifecycle, cardinality, retention, and access rules against the workflows in `docs/workflows/`.

The 86 proposed tables are grouped by domain below. `User`, `Role`, `Permission`, `UserRole`, `RolePermission`, `Organization`, `OrganizationMember`, `Department`, `StudentProfile`, `CompanyProfile`, `CompanyVerification`, `RefreshToken`, and `LoginSession` are the initial foundation; the other 73 are future candidates.

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
