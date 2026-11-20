import { Injectable } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
      include: { roles: { include: { role: true } } },
    });
  }

  findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { roles: { include: { role: true } } },
    });
  }

  toSafeUser(user: User & { roles?: { role: { name: string } }[] }) {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      status: user.status,
      roles: user.roles?.map(({ role }) => role.name) ?? [],
      createdAt: user.createdAt,
    };
  }

  async createStudent(data: {
    email: string;
    passwordHash: string;
    firstName: string;
    lastName: string;
    phone?: string;
  }) {
    return this.prisma.$transaction(async (tx) => {
      const studentRole = await tx.role.upsert({
        where: { name: 'STUDENT' },
        create: { name: 'STUDENT' },
        update: {},
      });
      return tx.user.create({
        data: {
          ...data,
          roles: { create: { roleId: studentRole.id } },
        },
        include: { roles: { include: { role: true } } },
      });
    });
  }

  async createStudentSafely(data: Parameters<UsersService['createStudent']>[0]) {
    try {
      return await this.createStudent(data);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return null;
      }
      throw error;
    }
  }
}
