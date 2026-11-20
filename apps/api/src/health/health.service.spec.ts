import { PrismaService } from '../database/prisma.service';
import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;
  let queryRaw: ReturnType<typeof jest.fn<(...args: unknown[]) => Promise<unknown>>>;
  let transaction: ReturnType<typeof jest.fn>;

  beforeEach(() => {
    queryRaw = jest.fn<(...args: unknown[]) => Promise<unknown>>();
    transaction =
      jest.fn<
        (
          callback: (client: { $queryRaw: typeof queryRaw }) => Promise<unknown>,
          options: { maxWait: number; timeout: number },
        ) => Promise<unknown>
      >();
    transaction.mockImplementation(async (callback) => callback({ $queryRaw: queryRaw }));
    service = new HealthService({ $transaction: transaction } as unknown as PrismaService);
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('reports an accessible database after a lightweight query', async () => {
    queryRaw.mockResolvedValue([{ '?column?': 1 }]);

    await expect(service.isDatabaseAvailable()).resolves.toBe(true);
    expect(transaction).toHaveBeenCalledWith(expect.any(Function), {
      maxWait: 1000,
      timeout: 3000,
    });
  });

  it('reports an inaccessible database without exposing the driver error', async () => {
    queryRaw.mockRejectedValue(new Error('postgres://secret-host/private-error'));

    await expect(service.isDatabaseAvailable()).resolves.toBe(false);
  });

  it('returns unavailable when a database probe does not settle before its deadline', async () => {
    jest.useFakeTimers();
    transaction.mockImplementation(() => new Promise(() => undefined));

    const probe = service.isDatabaseAvailable();
    await jest.advanceTimersByTimeAsync(5000);

    await expect(probe).resolves.toBe(false);
  });
});
