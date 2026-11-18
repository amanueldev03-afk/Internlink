import { INestApplication, Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import compression from 'compression';
import pino from 'pino';
import pinoHttp from 'pino-http';

async function bootstrap() {
  let app: INestApplication | undefined;
  let stage = 'application_creation';

  try {
    app = await NestFactory.create(AppModule, { abortOnError: false });
    stage = 'configuration';
    const config = app.get(ConfigService);
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

    stage = 'swagger_setup';
    const swagger = new DocumentBuilder()
      .setTitle(config.get<string>('swagger.title', 'InternLink API'))
      .setDescription(config.get<string>('swagger.description', 'InternLink backend API'))
      .setVersion(config.get<string>('swagger.version', '1.0'))
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, swagger);
    SwaggerModule.setup('docs', app, document);

    stage = 'listener_bind';
    const port = config.get<number>('port', 3001);
    await app.listen(port);
    logger.info({ port }, 'API listening');
  } catch (error: unknown) {
    const code =
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      typeof error.code === 'string' &&
      /^[A-Z0-9_]+$/.test(error.code)
        ? error.code
        : undefined;
    Logger.error(`API startup failed (${[stage, code].filter(Boolean).join(', ')}).`);
    process.exitCode = 1;

    if (app) {
      const forceExit = setTimeout(() => {
        Logger.error('API startup cleanup timed out; forcing process exit.');
        process.exit(1);
      }, 5000);
      forceExit.unref();

      try {
        await app.close();
      } catch {
        Logger.error('API startup cleanup failed.');
      }
    }
  }
}

void bootstrap();
