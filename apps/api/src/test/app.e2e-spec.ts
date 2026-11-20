import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AddressInfo } from 'node:net';
import { afterAll, beforeAll, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { PrismaService } from '../database/prisma.service';
import { AppModule } from '../app.module';

describe('Database health endpoint', () => {
  let app: INestApplication;
<<<<<<< HEAD
  const queryRaw = jest.fn<(...args: unknown[]) => Promise<unknown>>();
  const prismaMock = {
    $transaction: jest.fn<
      (
        callback: (client: { $queryRaw: typeof queryRaw }) => Promise<unknown>,
        options: { maxWait: number; timeout: number },
      ) => Promise<unknown>
    >(),
=======
  const prismaMock = {
    $queryRaw: jest.fn<(...args: unknown[]) => Promise<unknown>>(),
    $executeRaw: jest.fn<() => Promise<number>>().mockResolvedValue(0),
    $transaction: async (run: (tx: unknown) => Promise<void>) => run(prismaMock),
>>>>>>> origin/feature/backend-foundation
  };

  beforeAll(async () => {
    prismaMock.$transaction.mockImplementation(async (callback) =>
      callback({ $queryRaw: queryRaw }),
    );
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue(prismaMock)
      .compile();

    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.listen(0, '127.0.0.1');
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    queryRaw.mockReset();
  });

  it('returns 200 and safe connected status when the query succeeds', async () => {
    queryRaw.mockResolvedValue([{ '?column?': 1 }]);
    const address = app.getHttpServer().address() as AddressInfo;

    const response = await fetch(`http://127.0.0.1:${address.port}/api/v1/health/database`);

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({ status: 'ok', database: 'connected' });
  });

  it('returns 503 and safe disconnected status when the query fails', async () => {
    queryRaw.mockRejectedValue(new Error('secret connection details'));
    const address = app.getHttpServer().address() as AddressInfo;

    const response = await fetch(`http://127.0.0.1:${address.port}/api/v1/health/database`);
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body).toEqual({ status: 'error', database: 'disconnected' });
    expect(JSON.stringify(body)).not.toContain('secret connection details');
  });
});
