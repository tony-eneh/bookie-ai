import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { RAW_RESPONSE_KEY } from '../decorators/raw-response.decorator.js';
import { map } from 'rxjs/operators';

@Injectable()
export class ResponseTransformInterceptor<T>
  implements NestInterceptor<T, { data: T }>
{
  constructor(private readonly reflector?: Reflector) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<{ data: T }> {
    if (
      this.reflector?.getAllAndOverride<boolean>(RAW_RESPONSE_KEY, [
        context.getHandler(),
        context.getClass(),
      ])
    ) {
      return next.handle() as Observable<{ data: T }>;
    }
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
