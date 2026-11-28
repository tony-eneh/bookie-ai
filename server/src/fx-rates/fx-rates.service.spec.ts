import { FxRatesService } from './fx-rates.service.js';

describe('FxRatesService.ratesUrl', () => {
  it('puts the base currency in the path', () => {
    expect(
      FxRatesService.ratesUrl('https://api.exchangerate-api.com/v4/latest', 'KRW'),
    ).toBe('https://api.exchangerate-api.com/v4/latest/KRW');
    expect(FxRatesService.ratesUrl('https://x.test/latest/', 'NGN')).toBe(
      'https://x.test/latest/NGN',
    );
  });

  it('supports a {base} placeholder', () => {
    expect(FxRatesService.ratesUrl('https://x.test/rates?from={base}', 'USD')).toBe(
      'https://x.test/rates?from=USD',
    );
  });
});
