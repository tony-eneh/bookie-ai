import { plainToInstance } from 'class-transformer';
import { UpdateAccountDto } from './update-account.dto.js';

describe('UpdateAccountDto', () => {
  it('does not invent fields the client did not send', () => {
    // Regression: a default currency on CreateAccountDto turned every
    // account edit into a currency change to USD.
    const dto = plainToInstance(UpdateAccountDto, { name: 'Renamed' });
    expect(dto.currency).toBeUndefined();
    expect(dto.isPrimary).toBeUndefined();
  });
});
