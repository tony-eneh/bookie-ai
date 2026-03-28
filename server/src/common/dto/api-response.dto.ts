import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ApiResponseDto<T> {
  @ApiProperty()
  success: boolean;

  @ApiPropertyOptional()
  data?: T;

  @ApiPropertyOptional()
  message?: string;

  @ApiPropertyOptional()
  error?: string;

  constructor(partial: Partial<ApiResponseDto<T>>) {
    Object.assign(this, partial);
  }

  static ok<T>(data: T, message?: string): ApiResponseDto<T> {
    return new ApiResponseDto({ success: true, data, message });
  }

  static fail<T>(error: string): ApiResponseDto<T> {
    return new ApiResponseDto({ success: false, error });
  }
}
