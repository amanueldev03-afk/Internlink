import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import type { Response } from 'express';
import { HealthService } from './health.service';

interface DatabaseHealthResponse {
  status: 'ok' | 'error';
  database: 'connected' | 'disconnected';
}

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get('database')
  async checkDatabase(
    @Res({ passthrough: true }) response: Response,
  ): Promise<DatabaseHealthResponse> {
    const connected = await this.healthService.isDatabaseAvailable();

    if (!connected) {
      response.status(HttpStatus.SERVICE_UNAVAILABLE);
      return { status: 'error', database: 'disconnected' };
    }

    return { status: 'ok', database: 'connected' };
  }
}
