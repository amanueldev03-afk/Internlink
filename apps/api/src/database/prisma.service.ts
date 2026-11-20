import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';

const DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS = 2;
const DEFAULT_DATABASE_SOCKET_TIMEOUT_SECONDS = 5;
const DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS = 1;

export function normalizeDatabaseUrl(
  databaseUrl: string,
  fallbackConnectTimeoutSeconds: number,
  fallbackSocketTimeoutSeconds = DEFAULT_DATABASE_SOCKET_TIMEOUT_SECONDS,
  fallbackPoolTimeoutSeconds = DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS,
): string {
  if (!Number.isSafeInteger(fallbackConnectTimeoutSeconds) || fallbackConnectTimeoutSeconds < 1) {
    throw new Error('DATABASE_CONNECT_TIMEOUT_SECONDS must be a positive integer.');
  }
  if (!Number.isSafeInteger(fallbackSocketTimeoutSeconds) || fallbackSocketTimeoutSeconds < 1) {
    throw new Error('DATABASE_SOCKET_TIMEOUT_SECONDS must be a positive integer.');
  }
  if (!Number.isSafeInteger(fallbackPoolTimeoutSeconds) || fallbackPoolTimeoutSeconds < 1) {
    throw new Error('DATABASE_POOL_TIMEOUT_SECONDS must be a positive integer.');
  }

  let url: URL;
  try {
    url = new URL(databaseUrl);
  } catch {
    throw new Error('The configured database URL is invalid.');
  }
  if (
    !['postgres:', 'postgresql:'].includes(url.protocol) ||
    !url.hostname ||
    !/^[A-Za-z0-9._:[\]-]+$/.test(url.hostname)
  ) {
    throw new Error('The configured database URL is invalid.');
  }

  for (const [parameter, fallbackSeconds] of [
    ['connect_timeout', fallbackConnectTimeoutSeconds],
    ['socket_timeout', fallbackSocketTimeoutSeconds],
    ['pool_timeout', fallbackPoolTimeoutSeconds],
  ] as const) {
    const value = url.searchParams.get(parameter);
    if (value === null || value === '0') {
      url.searchParams.set(parameter, String(fallbackSeconds));
    } else if (!/^[1-9]\d*$/.test(value)) {
      throw new Error(`The database URL has an invalid ${parameter} value.`);
    }
  }

  return url.toString();
}

function getSafeDatabaseErrorDiagnostic(error: unknown): string | undefined {
  if (typeof error !== 'object' || error === null) {
    return undefined;
  }

  const code = 'code' in error && typeof error.code === 'string' ? error.code : undefined;
  if (code && /^[A-Za-z0-9_]{1,32}$/.test(code)) {
    return code;
  }

  const name = 'name' in error && typeof error.name === 'string' ? error.name : undefined;
  return name && /^[A-Za-z][A-Za-z0-9_]{0,63}$/.test(name) ? name : undefined;
}

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor(config: ConfigService) {
    super({
      datasources: {
        db: {
          url: normalizeDatabaseUrl(
            config.getOrThrow<string>('database.url'),
            config.get<number>(
              'database.connectTimeoutSeconds',
              DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS,
            ),
            config.get<number>(
              'database.socketTimeoutSeconds',
              DEFAULT_DATABASE_SOCKET_TIMEOUT_SECONDS,
            ),
            DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS,
          ),
        },
      },
    });
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.$connect();
    } catch (error: unknown) {
      // Keep the API alive so its database health route can report 503 and
      // orchestration can restart or alert without leaking connection details.
      const diagnostic = getSafeDatabaseErrorDiagnostic(error);
      this.logger.warn(
        `Database connection is unavailable during startup${diagnostic ? ` (${diagnostic})` : ''}.`,
      );
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
