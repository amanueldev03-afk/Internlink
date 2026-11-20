export function parsePort(rawPort: string | undefined): number {
  if (rawPort === undefined) return 3001;
  if (!/^\d+$/.test(rawPort)) {
    throw Object.assign(new Error('PORT must be an integer between 1 and 65535.'), {
      code: 'INVALID_PORT',
    });
  }

  const port = Number(rawPort);
  if (!Number.isSafeInteger(port) || port < 1 || port > 65535) {
    throw Object.assign(new Error('PORT must be an integer between 1 and 65535.'), {
      code: 'INVALID_PORT',
    });
  }
  return port;
}

export default () => ({
  port: parsePort(process.env.PORT),
  logLevel: process.env.LOG_LEVEL ?? 'info',
  swagger: {
    title: process.env.SWAGGER_TITLE ?? 'InternLink API',
    description: process.env.SWAGGER_DESCRIPTION ?? 'InternLink backend API',
    version: process.env.SWAGGER_VERSION ?? '1.0',
  },
  jwt: {
    secret: process.env.JWT_SECRET ?? 'change-me',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '1d',
  },
  redis: {
    url: process.env.REDIS_URL ?? 'redis://:internlink@localhost:6379',
  },
  database: {
    url: process.env.DATABASE_URL,
    connectTimeoutSeconds: Number(process.env.DATABASE_CONNECT_TIMEOUT_SECONDS ?? 2),
    socketTimeoutSeconds: Number(process.env.DATABASE_SOCKET_TIMEOUT_SECONDS ?? 5),
  },
});
