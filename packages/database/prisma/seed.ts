import { PrismaClient, RoleName } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const roleSeeds: { name: RoleName; description: string }[] = [
    { name: 'SYSTEM_ADMIN', description: 'System administrator' },
    { name: 'DEPARTMENT_COORDINATOR', description: 'Department coordinator' },
    { name: 'INTERNSHIP_OFFICER', description: 'Internship officer' },
    { name: 'DORMITORY_ADMINISTRATOR', description: 'Dormitory administrator' },
    { name: 'STUDENT_UNION_COORDINATOR', description: 'Student union coordinator' },
    { name: 'FINANCIAL_OFFICE', description: 'Financial office' },
    { name: 'UNIVERSITY_ADVISOR', description: 'University advisor' },
    { name: 'STUDENT', description: 'Student member' },
    { name: 'COMPANY_HR', description: 'Company HR' },
    { name: 'COMPANY_ADVISOR', description: 'Company advisor' },
  ];

  for (const role of roleSeeds) {
    await prisma.role.upsert({
      where: { name: role.name },
      update: { description: role.description },
      create: { name: role.name, description: role.description },
    });
  }

  console.log('Seeded 10 foundational roles.');
}

main()
  .catch((error) => {
    console.error(error);
    throw error;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
