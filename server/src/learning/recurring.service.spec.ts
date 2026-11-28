import { RecurringService } from './recurring.service.js';

const d = (iso: string) => new Date(iso);

describe('RecurringService.isRegular', () => {
  it('recognises monthly payments', () => {
    expect(
      RecurringService.isRegular([d('2026-09-01'), d('2026-10-02'), d('2026-11-01')]),
    ).toBe(true);
  });

  it('recognises weekly payments', () => {
    expect(
      RecurringService.isRegular([d('2026-11-01'), d('2026-11-08'), d('2026-11-15')]),
    ).toBe(true);
  });

  it('rejects irregular gaps and too few payments', () => {
    expect(
      RecurringService.isRegular([d('2026-09-01'), d('2026-09-20'), d('2026-11-01')]),
    ).toBe(false);
    expect(RecurringService.isRegular([d('2026-10-01'), d('2026-11-01')])).toBe(false);
  });
});

describe('RecurringService.key', () => {
  it('prefers merchant, then counterparty, then description', () => {
    expect(
      RecurringService.key({ merchantName: 'NETFLIX.COM', counterparty: null, description: 'x' }),
    ).toBe('netflix com');
    expect(
      RecurringService.key({ merchantName: null, counterparty: null, description: 'Rent' }),
    ).toBe('rent');
  });
});
