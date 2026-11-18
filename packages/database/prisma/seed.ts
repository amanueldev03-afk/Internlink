import { PermissionName, PrismaClient, RoleName } from '@prisma/client';

const prisma = new PrismaClient();

const roleSeeds: ReadonlyArray<{
  name: RoleName;
  description: string;
  permissions: PermissionName[];
}> = [
  {
    name: RoleName.SYSTEM_ADMIN,
    description: 'System administrator',
    permissions: Object.values(PermissionName),
  },
  {
    name: RoleName.DEPARTMENT_COORDINATOR,
    description: 'Department coordinator',
    permissions: [PermissionName.VIEW_STUDENTS, PermissionName.MANAGE_SETTINGS],
  },
  {
    name: RoleName.INTERNSHIP_OFFICER,
    description: 'Internship officer',
    permissions: [
      PermissionName.VIEW_STUDENTS,
      PermissionName.MANAGE_INTERNSHIPS,
      PermissionName.MANAGE_APPLICATIONS,
      PermissionName.MANAGE_COMMUNICATION,
    ],
  },
  {
    name: RoleName.DORMITORY_ADMINISTRATOR,
    description: 'Dormitory administrator',
    permissions: [PermissionName.VIEW_STUDENTS, PermissionName.MANAGE_DORMITORY],
  },
  {
    name: RoleName.STUDENT_UNION_COORDINATOR,
    description: 'Student union coordinator',
    permissions: [PermissionName.VIEW_STUDENTS, PermissionName.MANAGE_COMMUNICATION],
  },
  {
    name: RoleName.FINANCIAL_OFFICE,
    description: 'Financial office',
    permissions: [PermissionName.VIEW_STUDENTS, PermissionName.MANAGE_FINANCE],
  },
  {
    name: RoleName.UNIVERSITY_ADVISOR,
    description: 'University advisor',
    permissions: [
      PermissionName.VIEW_STUDENTS,
      PermissionName.MANAGE_SUBMISSIONS,
      PermissionName.MANAGE_EVALUATIONS,
      PermissionName.MANAGE_COMMUNICATION,
    ],
  },
  {
    name: RoleName.STUDENT,
    description: 'Student member',
    permissions: [
      PermissionName.MANAGE_APPLICATIONS,
      PermissionName.MANAGE_SUBMISSIONS,
      PermissionName.MANAGE_COMMUNICATION,
    ],
  },
  {
    name: RoleName.COMPANY_HR,
    description: 'Company human resources representative',
    permissions: [
      PermissionName.VIEW_STUDENTS,
      PermissionName.MANAGE_INTERNSHIPS,
      PermissionName.MANAGE_APPLICATIONS,
      PermissionName.MANAGE_COMMUNICATION,
    ],
  },
  {
    name: RoleName.COMPANY_ADVISOR,
    description: 'Company internship advisor',
    permissions: [
      PermissionName.VIEW_STUDENTS,
      PermissionName.MANAGE_SUBMISSIONS,
      PermissionName.MANAGE_EVALUATIONS,
      PermissionName.MANAGE_COMMUNICATION,
    ],
  },
];

const permissionDescriptions: Record<PermissionName, string> = {
  MANAGE_USERS: 'Create and administer user accounts',
  MANAGE_ROLES: 'Manage role and permission assignments',
  MANAGE_ORGANIZATIONS: 'Manage organizations and memberships',
  VIEW_STUDENTS: 'View student records permitted by organization scope',
  MANAGE_INTERNSHIPS: 'Manage internship programs and positions',
  MANAGE_APPLICATIONS: 'Manage applications permitted by organization scope',
  MANAGE_SUBMISSIONS: 'Manage internship work submissions',
  MANAGE_EVALUATIONS: 'Manage internship evaluations and results',
  MANAGE_FINANCE: 'Manage financial support and payment records',
  MANAGE_DORMITORY: 'Manage dormitory, room, and key records',
  MANAGE_COMMUNICATION: 'Manage conversations, meetings, and notifications',
  MANAGE_SETTINGS: 'Manage organization and system settings',
};

async function main() {
  await prisma.$transaction(async (tx) => {
    for (const name of Object.values(PermissionName)) {
      await tx.permission.upsert({
        where: { name },
        update: { description: permissionDescriptions[name] },
        create: { name, description: permissionDescriptions[name] },
      });
    }

    for (const roleSeed of roleSeeds) {
      const role = await tx.role.upsert({
        where: { name: roleSeed.name },
        update: { description: roleSeed.description },
        create: { name: roleSeed.name, description: roleSeed.description },
      });

      for (const permissionName of roleSeed.permissions) {
        const permission = await tx.permission.findUniqueOrThrow({
          where: { name: permissionName },
          select: { id: true },
        });

        await tx.rolePermission.upsert({
          where: {
            roleId_permissionId: { roleId: role.id, permissionId: permission.id },
          },
          update: {},
          create: { roleId: role.id, permissionId: permission.id },
        });
      }
    }
  });

  console.log(`Seeded ${roleSeeds.length} actor roles and ${Object.values(PermissionName).length} permissions.`);
}

main()
  .catch((error: unknown) => {
    console.error('Database seed failed.', error);
    throw error;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
