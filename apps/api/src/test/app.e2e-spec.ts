import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AddressInfo } from 'node:net';
import { afterAll, beforeAll, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { DatabaseModule } from '../database/database.module';
import { PrismaService } from '../database/prisma.service';
import { HealthModule } from '../health/health.module';

describe('Database health endpoint', () => {
  let app: INestApplication;
  const prismaMock = { $queryRaw: jest.fn<(...args: unknown[]) => Promise<unknown>>() };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [DatabaseModule, HealthModule],
    })
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
    prismaMock.$queryRaw.mockReset();
  });

  it('returns 200 and safe connected status when the query succeeds', async () => {
    prismaMock.$queryRaw.mockResolvedValue([{ '?column?': 1 }]);
    const address = app.getHttpServer().address() as AddressInfo;

    const response = await fetch(`http://127.0.0.1:${address.port}/api/v1/health/database`);

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({ status: 'ok', database: 'connected' });
  });

  it('returns 503 and safe disconnected status when the query fails', async () => {
    prismaMock.$queryRaw.mockRejectedValue(new Error('secret connection details'));
    const address = app.getHttpServer().address() as AddressInfo;

    const response = await fetch(`http://127.0.0.1:${address.port}/api/v1/health/database`);
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body).toEqual({ status: 'error', database: 'disconnected' });
    expect(JSON.stringify(body)).not.toContain('secret connection details');
  });
});
