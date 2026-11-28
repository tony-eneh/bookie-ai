import { ConfigService } from '@nestjs/config';
import { checkShape, ShapeError } from './ai-shape.js';
import { AiService, isPlaceholderApiKey } from './ai.service.js';

describe('checkShape', () => {
  const spec = {
    amount: 'number',
    type: 'enum:INCOME|EXPENSE',
    merchantName: 'string|null',
    tags: 'string[]',
    note: 'string?',
  };

  it('accepts a valid object and coerces numeric strings and enum case', () => {
    expect(
      checkShape(
        { amount: '12.50', type: 'expense', merchantName: null, tags: [] },
        spec,
      ),
    ).toEqual({ amount: 12.5, type: 'EXPENSE', merchantName: null, tags: [] });
  });

  it('rejects missing or wrongly typed fields', () => {
    expect(() =>
      checkShape({ type: 'EXPENSE', merchantName: null, tags: [] }, spec),
    ).toThrow(ShapeError);
    expect(() =>
      checkShape(
        { amount: 'lots', type: 'EXPENSE', merchantName: null, tags: [] },
        spec,
      ),
    ).toThrow(ShapeError);
    expect(() =>
      checkShape(
        { amount: 1, type: 'REFUND', merchantName: null, tags: [] },
        spec,
      ),
    ).toThrow(ShapeError);
    expect(() => checkShape([], spec)).toThrow(ShapeError);
  });
});

describe('isPlaceholderApiKey', () => {
  it.each([
    undefined,
    '',
    '  ',
    'mock-mode-no-key-required',
    'none',
    'your-key',
  ])('treats %p as no key', (key) =>
    expect(isPlaceholderApiKey(key)).toBe(true),
  );

  it('accepts real-looking keys', () => {
    expect(isPlaceholderApiKey('sk-proj-abc123')).toBe(false);
  });
});

describe('AiService in mock mode', () => {
  const ai = new AiService({
    get: () => 'mock-mode-no-key-required',
  } as unknown as ConfigService);

  it('does not call the provider with a placeholder key', async () => {
    const fetchSpy = jest.spyOn(global, 'fetch');
    await ai.answerFinanceQuestion('How am I doing?', {});
    expect(fetchSpy).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });

  it('parses with the account currency and never invents an amount', async () => {
    const parsed = await ai.parseTransaction('Paid for lunch at Mama Put', {
      defaultCurrency: 'NGN',
    });
    expect(parsed.currency).toBe('NGN');
    expect(parsed.amount).toBe(0);
    expect(parsed.ambiguityFlags).toContain('AMOUNT_UNCLEAR');
  });

  it('reads the amount and an explicit currency', async () => {
    const parsed = await ai.parseTransaction(
      'Debit alert: KRW 12,000 spent at GS25',
      { defaultCurrency: 'NGN' },
    );
    expect(parsed.amount).toBe(12000);
    expect(parsed.currency).toBe('KRW');
  });
});

describe('AiService with a rejected key', () => {
  it('falls back to mock and stops calling the provider', async () => {
    const ai = new AiService({
      get: (k: string) => (k === 'OPENAI_API_KEY' ? 'sk-revoked' : undefined),
      getOrThrow: () => 'sk-revoked',
    } as unknown as ConfigService);
    const fetchSpy = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response('{}', { status: 401 }));
    jest.spyOn(console, 'error').mockImplementation(() => undefined);

    const first = await ai.answerFinanceQuestion('Hi', {});
    await ai.answerFinanceQuestion('Hi again', {});

    expect(first.answer).toBeTruthy();
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    expect(ai.isLive()).toBe(false);
    fetchSpy.mockRestore();
  });

  it('falls back to mock when the model returns the wrong shape', async () => {
    const ai = new AiService({
      get: (k: string) => (k === 'OPENAI_API_KEY' ? 'sk-real' : undefined),
      getOrThrow: () => 'sk-real',
    } as unknown as ConfigService);
    const body = { choices: [{ message: { content: '{"type":"EXPENSE"}' } }] };
    const fetchSpy = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue(new Response(JSON.stringify(body), { status: 200 }));

    const parsed = await ai.parseTransaction('NGN 4,500 at Shoprite', {
      defaultCurrency: 'NGN',
    });
    expect(parsed.amount).toBe(4500);
    fetchSpy.mockRestore();
  });
});
