import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

const DATABASE_PROBE_MAX_WAIT_MS = 1000;
const DATABASE_STATEMENT_TIMEOUT_MS = 2000;
const DATABASE_TRANSACTION_TIMEOUT_MS = 3000;

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  async isDatabaseAvailable(): Promise<boolean> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
<<<<<<< HEAD
      await this.prisma.$transaction(
        async (transaction) => {
          await transaction.$queryRaw`SELECT set_config(
            'statement_timeout',
            ${`${DATABASE_STATEMENT_TIMEOUT_MS}ms`},
            true
          )`;
          await transaction.$queryRaw`SELECT 1`;
        },
        {
          maxWait: DATABASE_PROBE_MAX_WAIT_MS,
          timeout: DATABASE_TRANSACTION_TIMEOUT_MS,
        },
      );
=======
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
>>>>>>> origin/feature/backend-foundation
      return true;
    } catch {
      // Keep driver errors, hostnames, and credentials out of health responses.
      return false;
    } finally {
      clearTimeout(timer);
    }
  }
}
