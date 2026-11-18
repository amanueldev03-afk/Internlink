import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

const DATABASE_CONNECT_TIMEOUT_SECONDS = 2;

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor(config: ConfigService) {
    const databaseUrl = new URL(config.getOrThrow<string>('database.url'));
    const connectTimeout = Number(databaseUrl.searchParams.get('connect_timeout') ?? 5);
    if (
      !Number.isFinite(connectTimeout) ||
      connectTimeout <= 0 ||
      connectTimeout > DATABASE_CONNECT_TIMEOUT_SECONDS
    ) {
      databaseUrl.searchParams.set('connect_timeout', String(DATABASE_CONNECT_TIMEOUT_SECONDS));
    }

    super({
      datasources: {
        db: {
          url: databaseUrl.toString(),
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
