import { Controller, Get } from '@nestjs/common';
import { Public } from './common/decorators/public.decorator';

@Controller()
export class AppController {
  @Public()
  @Get()
  getRoot() {
    return { status: 'ok', service: 'NDOKETE API', version: '1.0.0' };
  }

  @Public()
  @Get('health')
  getHealth() {
    return { status: 'healthy', timestamp: new Date().toISOString() };
  }
}
