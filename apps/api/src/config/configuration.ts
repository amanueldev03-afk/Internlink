export default () => ({
  port: Number(process.env.PORT ?? 3001),
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
  },
});
