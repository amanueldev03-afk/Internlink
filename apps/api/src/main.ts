import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import compression from 'compression';
import pino from 'pino';
import pinoHttp from 'pino-http';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = pino({ level: process.env.LOG_LEVEL ?? 'info' });
  app.use(pinoHttp({ logger }));
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

  const config = new DocumentBuilder()
    .setTitle(process.env.SWAGGER_TITLE ?? 'InternLink API')
    .setDescription(process.env.SWAGGER_DESCRIPTION ?? 'InternLink backend API')
    .setVersion(process.env.SWAGGER_VERSION ?? '1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT ?? 3001);
  await app.listen(port);
  logger.info({ port }, 'API listening');
}
bootstrap();
