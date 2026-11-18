import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor(config: ConfigService) {
    const url = new URL(config.getOrThrow<string>('database.url'));
    // Prisma 5 native PostgreSQL driver deadlines (seconds).
    url.searchParams.set('connect_timeout', '2');
    url.searchParams.set('socket_timeout', '2');
    url.searchParams.set('pool_timeout', '1');
    super({
      datasources: {
        db: {
          url: url.toString(),
        },
      },
    });
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.$connect();
    } catch {
      // Keep the API alive so its database health route can report 503 and
      // orchestration can restart or alert without leaking connection details.
      this.logger.warn('Database connection is unavailable during startup.');
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
