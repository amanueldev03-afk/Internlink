import { PrismaService } from '../database/prisma.service';
import { beforeEach, describe, expect, it, jest } from '@jest/globals';
import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;
  let queryRaw: ReturnType<typeof jest.fn<(...args: unknown[]) => Promise<unknown>>>;
  let transaction: ReturnType<typeof jest.fn>;

  beforeEach(() => {
    queryRaw = jest.fn<(...args: unknown[]) => Promise<unknown>>();
<<<<<<< HEAD
    transaction =
      jest.fn<
        (
          callback: (client: { $queryRaw: typeof queryRaw }) => Promise<unknown>,
          options: { maxWait: number; timeout: number },
        ) => Promise<unknown>
      >();
    transaction.mockImplementation(async (callback) => callback({ $queryRaw: queryRaw }));
    service = new HealthService({ $transaction: transaction } as unknown as PrismaService);
=======
    service = new HealthService({
      $transaction: async (run: (tx: unknown) => Promise<void>) => run({
        $executeRaw: jest.fn<() => Promise<number>>().mockResolvedValue(0),
        $queryRaw: queryRaw,
      }),
    } as unknown as PrismaService);
>>>>>>> origin/feature/backend-foundation
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
  it('bounds the total wait even when a driver operation does not settle', async () => {
    jest.useFakeTimers();
    try {
      queryRaw.mockImplementation(() => new Promise(() => undefined));
      const result = service.isDatabaseAvailable();
      await jest.advanceTimersByTimeAsync(5000);
      await expect(result).resolves.toBe(false);
      expect(jest.getTimerCount()).toBe(0);
    } finally {
      jest.useRealTimers();
    }
  });

});
