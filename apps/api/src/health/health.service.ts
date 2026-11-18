import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  async isDatabaseAvailable(): Promise<boolean> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      await Promise.race([
        this.prisma.$transaction(async (tx) => {
          // PostgreSQL cancels the work; socket_timeout also bounds driver I/O.
          await tx.$executeRaw`SET LOCAL statement_timeout = '1000ms'`;
          await tx.$queryRaw`SELECT 1`;
        }, { maxWait: 1000, timeout: 3000 }),
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => reject(new Error('Health probe timed out')), 5000);
        }),
      ]);
      return true;
    } catch {
      // Keep driver errors, hostnames, and credentials out of health responses.
      return false;
    } finally {
      clearTimeout(timer);
    }
  }
}
