import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    if (data === 'artisanId' && user?.role === 'ADMIN') {
      const headerArtisanId = request.headers['x-artisan-id'] || request.query?.artisanId;
      if (headerArtisanId) return headerArtisanId;
    }
    return data ? user?.[data] : user;
  },
);
