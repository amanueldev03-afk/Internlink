import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import compression from 'compression';
import pino from 'pino';
import pinoHttp from 'pino-http';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const port = config.get<number>('port', 3001);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    Logger.error('Invalid PORT: expected an integer from 1 to 65535.');
    await app.close();
    process.exitCode = 1;
    return;
  }
  const logger = pino({ level: config.get<string>('logLevel', 'info') });
  app.use(pinoHttp({ logger }));
  app.setGlobalPrefix('api/v1');
  app.enableCors();
  app.use(helmet());
  app.use(compression());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const swagger = new DocumentBuilder()
    .setTitle(config.get<string>('swagger.title', 'InternLink API'))
    .setDescription(config.get<string>('swagger.description', 'InternLink backend API'))
    .setVersion(config.get<string>('swagger.version', '1.0'))
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swagger);
  SwaggerModule.setup('docs', app, document);

  await app.listen(port);
  logger.info({ port }, 'API listening');
}

bootstrap().catch(() => {
  Logger.error('API startup failed.');
  process.exitCode = 1;
});
