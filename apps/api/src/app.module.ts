import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { basename, dirname, resolve } from 'node:path';
import configuration from './config/configuration';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';

const apiRoot =
  typeof __dirname === 'string'
    ? resolve(__dirname, '..')
    : basename(process.cwd()) === 'api' && basename(dirname(process.cwd())) === 'apps'
      ? process.cwd()
      : resolve(process.cwd(), 'apps/api');

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        resolve(apiRoot, '.env.local'),
        resolve(apiRoot, '.env'),
        resolve(apiRoot, '../../packages/database/.env'),
      ],
      load: [configuration],
    }),
    DatabaseModule,
    HealthModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
