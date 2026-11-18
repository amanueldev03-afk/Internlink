import { PrismaService } from '../database/prisma.service';
import { beforeEach, describe, expect, it, jest } from '@jest/globals';
import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;
  let queryRaw: ReturnType<typeof jest.fn<(...args: unknown[]) => Promise<unknown>>>;

  beforeEach(() => {
    queryRaw = jest.fn<(...args: unknown[]) => Promise<unknown>>();
    service = new HealthService({ $queryRaw: queryRaw } as unknown as PrismaService);
  });

  it('reports an accessible database after a lightweight query', async () => {
    queryRaw.mockResolvedValue([{ '?column?': 1 }]);

    await expect(service.isDatabaseAvailable()).resolves.toBe(true);
    expect(queryRaw).toHaveBeenCalledTimes(1);
  });

  it('reports an inaccessible database without exposing the driver error', async () => {
    queryRaw.mockRejectedValue(new Error('postgres://secret-host/private-error'));

    await expect(service.isDatabaseAvailable()).resolves.toBe(false);
  });
});
