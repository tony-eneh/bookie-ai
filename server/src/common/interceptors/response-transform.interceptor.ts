import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseTransformInterceptor<T>
  implements NestInterceptor<T, { data: T }>
{
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<{ data: T }> {
    return next.handle().pipe(
      map((data) => {
        if (
          data !== null &&
          typeof data === 'object' &&
          'data' in (data as Record<string, unknown>)
        ) {
          return data as { data: T };
        }

        return { data };
      }),
    );
  }
}
