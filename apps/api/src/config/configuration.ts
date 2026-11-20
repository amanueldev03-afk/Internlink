export default () => ({
  port: Number(process.env.PORT ?? 3001),
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '1d',
  },
  redis: {
    url: process.env.REDIS_URL ?? 'redis://:internlink@localhost:6379',
  },
  database: {
    url: process.env.DATABASE_URL ?? 'postgresql://internlink:internlink@localhost:5432/internlink',
  },
});

export function validateEnvironment(config: Record<string, unknown>) {
  const secret = config.JWT_SECRET;
  if (typeof secret !== 'string' || secret.length < 32) {
    throw new Error('JWT_SECRET must be set to at least 32 characters');
  }
  return config;
}
