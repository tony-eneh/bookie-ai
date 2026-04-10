import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const apiPrefix = 'api';

  const corsOrigins = (configService.get<string>('CORS_ORIGINS') ??
    'http://localhost:3000,http://localhost:5173,http://localhost:8080')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const corsCredentials =
    (configService.get<string>('CORS_CREDENTIALS') ?? 'false').toLowerCase() ===
    'true';

  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (error: Error | null, allow?: boolean) => void,
    ) => {
      if (!origin || corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin not allowed by CORS'), false);
    },
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    credentials: corsCredentials,
  });

  app.setGlobalPrefix('api');

  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
    }),
  );

  app.useGlobalInterceptors(new ResponseTransformInterceptor());

  const swaggerConfig = new DocumentBuilder()
    .setTitle('BookieAI API')
    .setDescription('Voice-first AI-powered personal finance API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup(`${apiPrefix}/docs`, app, document);

  const port = configService.get<number>('PORT', 3000);

  await app.listen(port);
}
bootstrap();
