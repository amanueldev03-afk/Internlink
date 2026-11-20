import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

const DATABASE_PROBE_MAX_WAIT_MS = 1000;
const DATABASE_STATEMENT_TIMEOUT_MS = 2000;
const DATABASE_TRANSACTION_TIMEOUT_MS = 3000;
const DATABASE_PROBE_DEADLINE_MS = 5000;

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  async isDatabaseAvailable(): Promise<boolean> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      await Promise.race([
        this.prisma.$transaction(
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
        ),
        new Promise<never>((_, reject) => {
          timer = setTimeout(
            () => reject(new Error('Database health probe timed out.')),
            DATABASE_PROBE_DEADLINE_MS,
          );
        }),
      ]);
      return true;
    } catch {
      // Keep driver errors, hostnames, and credentials out of health responses.
      return false;
    } finally {
      if (timer) clearTimeout(timer);
    }
  }
}
