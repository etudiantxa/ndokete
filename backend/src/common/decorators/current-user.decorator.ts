import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    if (data === 'artisanId' && (user?.role === 'ADMIN' || user?.role?.toUpperCase() === 'ADMIN')) {
      const headerArtisanId = request.headers['x-artisan-id'] || request.headers['X-Artisan-Id'] || request.query?.artisanId;
      if (headerArtisanId && headerArtisanId !== 'undefined' && headerArtisanId !== 'null') {
        return headerArtisanId;
      }
    }
    return data ? user?.[data] : user;
  },
);
