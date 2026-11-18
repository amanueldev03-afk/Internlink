import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest();
    const before = Date.now();

    return next.handle().pipe(
      tap(() => {
        const after = Date.now();
        console.log(`${req.method} ${req.url} ${after - before}ms`);
      }),
    );
  }
}
