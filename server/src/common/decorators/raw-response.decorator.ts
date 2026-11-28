import { SetMetadata } from '@nestjs/common';

export const RAW_RESPONSE_KEY = 'rawResponse';

/** Send the handler's return value as-is, without the `{ data }` envelope. */
export const RawResponse = () => SetMetadata(RAW_RESPONSE_KEY, true);
