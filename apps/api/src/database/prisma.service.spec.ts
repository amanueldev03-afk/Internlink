import { ConfigService } from '@nestjs/config';
import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { PrismaService } from './prisma.service';

describe('PrismaService', () => {
  let service: PrismaService;

  beforeEach(() => {
    const config = {
      getOrThrow: jest.fn().mockReturnValue('postgresql://test:test@localhost:5432/test'),
    } as unknown as ConfigService;
    service = new PrismaService(config);
  });

  afterEach(async () => {
    await service.$disconnect();
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
    jest.spyOn(service, '$connect').mockRejectedValue(new Error('private connection detail'));
    const logger = jest
      .spyOn((service as unknown as { logger: { warn: (message: string) => void } }).logger, 'warn')
      .mockImplementation(() => undefined);

    await expect(service.onModuleInit()).resolves.toBeUndefined();

    expect(logger).toHaveBeenCalledWith('Database connection is unavailable during startup.');
  });
});
