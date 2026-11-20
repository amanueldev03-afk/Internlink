import { ConfigService } from '@nestjs/config';
import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { normalizeDatabaseUrl, PrismaService } from './prisma.service';

describe('PrismaService', () => {
  let service: PrismaService;

  beforeEach(() => {
    const config = {
      getOrThrow: jest.fn().mockReturnValue('postgresql://test:test@localhost:5432/test'),
      get: jest.fn((key: string) => (key === 'database.socketTimeoutSeconds' ? 5 : 2)),
    } as unknown as ConfigService;
    service = new PrismaService(config);
  });

  afterEach(async () => {
    await service.$disconnect();
  });

  it('applies the fallback only when a connection timeout is absent or zero', () => {
    const urlWithoutTimeout = normalizeDatabaseUrl('postgresql://test:test@localhost:5432/test', 4);
    const urlWithZeroTimeout = normalizeDatabaseUrl(
      'postgres://test:test@localhost:5432/test?connect_timeout=0',
      4,
    );
    const urlWithConfiguredTimeout = normalizeDatabaseUrl(
      'postgresql://test:test@localhost:5432/test?connect_timeout=15',
      4,
    );

    expect(new URL(urlWithoutTimeout).searchParams.get('connect_timeout')).toBe('4');
    expect(new URL(urlWithZeroTimeout).searchParams.get('connect_timeout')).toBe('4');
    expect(new URL(urlWithConfiguredTimeout).searchParams.get('connect_timeout')).toBe('15');
  });

  it('sets a finite socket timeout and preserves an explicit positive value', () => {
    const defaultTimeout = normalizeDatabaseUrl('postgresql://test:test@localhost:5432/test', 4, 6);
    const explicitTimeout = normalizeDatabaseUrl(
      'postgresql://test:test@localhost:5432/test?socket_timeout=12',
      4,
      6,
    );

    expect(new URL(defaultTimeout).searchParams.get('socket_timeout')).toBe('6');
    expect(new URL(explicitTimeout).searchParams.get('socket_timeout')).toBe('12');
  });

  it('does not expose malformed credential-bearing database URLs in errors', () => {
    expect(() => normalizeDatabaseUrl('postgresql://user:private-secret@%', 2)).toThrow(
      'The configured database URL is invalid.',
    );
  });

  it('connects on module initialization', async () => {
    const connect = jest.spyOn(service, '$connect').mockResolvedValue();

    await service.onModuleInit();

    expect(connect).toHaveBeenCalledTimes(1);
  });

  it('disconnects on module destruction', async () => {
    const disconnect = jest.spyOn(service, '$disconnect').mockResolvedValue();

    await service.onModuleDestroy();

    expect(disconnect).toHaveBeenCalledTimes(1);
  });

  it('keeps startup alive when the database is unavailable', async () => {
    jest
      .spyOn(service, '$connect')
      .mockRejectedValue(Object.assign(new Error('private connection detail'), { code: 'P1001' }));
    const logger = jest
      .spyOn((service as unknown as { logger: { warn: (message: string) => void } }).logger, 'warn')
      .mockImplementation(() => undefined);

    await expect(service.onModuleInit()).resolves.toBeUndefined();

    expect(logger).toHaveBeenCalledWith(
      'Database connection is unavailable during startup (P1001).',
    );
    expect(logger).not.toHaveBeenCalledWith(expect.stringContaining('private connection detail'));
  });
});
