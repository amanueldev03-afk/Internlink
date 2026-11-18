export default () => ({
  port: Number(process.env.PORT ?? 3001),
  jwt: {
    secret: process.env.JWT_SECRET ?? 'change-me',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '1d',
  },
  redis: {
    url: process.env.REDIS_URL ?? 'redis://:internlink@localhost:6379',
  },
  database: {
    url: process.env.DATABASE_URL ?? 'postgresql://internlink:internlink@localhost:5432/internlink',
  },
});
