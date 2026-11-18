import { Queue, Worker } from 'bullmq';
import { Redis } from 'ioredis';
import pino from 'pino';

const logger = pino({ level: process.env.LOG_LEVEL ?? 'info' });

const connection = new Redis(process.env.REDIS_URL ?? 'redis://:internlink@localhost:6379');

const myQueue = new Queue('internlink-default', { connection });

new Worker(
  'internlink-default',
  async (job) => {
    logger.info({ jobId: job.id, jobName: job.name }, 'Processing job');
    return { ok: true };
  },
  { connection },
);

logger.info('Worker started');

process.on('SIGTERM', async () => {
  await myQueue.close();
  await connection.quit();
  process.exit(0);
});

process.on('SIGINT', async () => {
  await myQueue.close();
  await connection.quit();
  process.exit(0);
});
