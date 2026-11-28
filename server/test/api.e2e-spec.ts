/**
 * End-to-end tests of the money flows against a real Postgres database
 * (DATABASE_URL, migrated). Skipped when E2E_DATABASE is not set, so
 * `npm run test:e2e` stays runnable without a database.
 */
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module.js';
import { ResponseTransformInterceptor } from '../src/common/interceptors/response-transform.interceptor.js';

const describeDb = process.env.E2E_DATABASE ? describe : describe.skip;

describeDb('API (e2e, database)', () => {
  let app: INestApplication<App>;
  let token: string;
  const email = `e2e-${Date.now()}@example.com`;
  const password = 'e2e-password-123';

  const api = () => request(app.getHttpServer());
  const auth = (r: request.Test) => r.set('Authorization', `Bearer ${token}`);

  beforeAll(async () => {
    process.env.OPENAI_API_KEY = ''; // deterministic mock AI
    process.env.REDIS_URL = '';
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
    app.useGlobalInterceptors(new ResponseTransformInterceptor(app.get(Reflector)));
    await app.init();
  });

  afterAll(async () => {
    if (token) {
      await auth(api().post('/api/users/me/delete')).send({ confirm: 'DELETE', password });
    }
    await app?.close();
  });

  it('registers with onboarding choices and a default account', async () => {
    const res = await api()
      .post('/api/auth/register')
      .send({
        email: email.toUpperCase(), // stored lowercased
        password,
        fullName: 'E2E User',
        primaryCurrency: 'NGN',
      })
      .expect(201);
    token = res.body.data.accessToken;
    expect(res.body.data.user).toMatchObject({ email, primaryCurrency: 'NGN' });
    expect(res.body.data.user.passwordHash).toBeUndefined();

    const accounts = await auth(api().get('/api/accounts')).expect(200);
    expect(accounts.body.data).toHaveLength(1);
    expect(accounts.body.data[0]).toMatchObject({ currency: 'NGN', isPrimary: true });
  });

  it('shows the server message for a wrong password', async () => {
    const res = await api()
      .post('/api/auth/login')
      .send({ email, password: 'nope-nope-nope' })
      .expect(401);
    expect(res.body.message).toBe('Invalid credentials');
  });

  it('keeps balances right through create, edit, delete and reconcile', async () => {
    const created = await auth(api().post('/api/accounts'))
      .send({ name: 'Wallet', type: 'WALLET', initialBalance: 10000 })
      .expect(201);
    const id = created.body.data.id;
    expect(created.body.data.currency).toBe('NGN'); // user's currency
    const balance = async () =>
      Number((await auth(api().get(`/api/accounts/${id}`))).body.data.currentBalance);

    const tx = await auth(api().post('/api/transactions'))
      .send({
        accountId: id,
        type: 'EXPENSE',
        amount: 2500,
        currency: 'NGN',
        description: 'Lunch',
        occurredAt: new Date().toISOString(),
        sourceType: 'MANUAL',
      })
      .expect(201);
    expect(await balance()).toBe(7500);

    await auth(api().patch(`/api/transactions/${tx.body.data.id}`))
      .send({ amount: 3000 })
      .expect(200);
    expect(await balance()).toBe(7000);

    // Renaming must not change anything else (regression: currency reset).
    await auth(api().patch(`/api/accounts/${id}`)).send({ name: 'Cash' }).expect(200);
    const renamed = await auth(api().get(`/api/accounts/${id}`));
    expect(renamed.body.data.currency).toBe('NGN');

    await auth(api().delete(`/api/transactions/${tx.body.data.id}`)).expect(200);
    expect(await balance()).toBe(10000);

    const rec = await auth(api().post(`/api/accounts/${id}/reconcile`))
      .send({ balance: 9000, source: 'MANUAL' })
      .expect(201);
    expect(rec.body.data).toMatchObject({ drift: -1000, adjustmentCreated: true });
    expect(await balance()).toBe(9000);
  });

  it('ingests an SMS once, however many times it arrives', async () => {
    const rawText = `Debit Alert: NGN 1,250.00 spent at TEST MART ${Date.now()}`;
    const results = await Promise.all(
      [1, 2, 3].map(() =>
        auth(api().post('/api/ingestion/sms/parse')).send({ rawText }),
      ),
    );
    const duplicates = results.map((r) => r.body.data.duplicate);
    expect(duplicates.filter((d) => d === false)).toHaveLength(1);
    expect(results[0].body.data.transaction.amount).toBe('1250');

    await auth(api().post('/api/ingestion/sms/parse'))
      .send({ rawText: 'Thanks for banking with us' })
      .expect(422);
  });

  it('imports a CSV statement once, without touching the balance', async () => {
    const accounts = await auth(api().get('/api/accounts'));
    const account = accounts.body.data[0];
    const csv = [
      'Date;Narration;Withdrawal;Deposit',
      '02/11/2026;POS SHOPRITE;4500;',
      '03/11/2026;Transfer from Emeka;;15000',
      '03/11/2026;Transfer from Emeka;;15000',
    ].join('\n');
    const first = await auth(api().post('/api/statement-imports/csv'))
      .send({ accountId: account.id, csv })
      .expect(201);
    expect(first.body.data.transactionsImported).toBe(3); // both transfers
    const again = await auth(api().post('/api/statement-imports/csv'))
      .send({ accountId: account.id, csv })
      .expect(201);
    expect(again.body.data).toMatchObject({ transactionsImported: 0, duplicatesSkipped: 3 });
    const after = await auth(api().get(`/api/accounts/${account.id}`));
    expect(Number(after.body.data.currentBalance)).toBe(Number(account.currentBalance));
  });

    it('answers the assistant from real figures', async () => {
    const res = await auth(api().post('/api/assistant/chat'))
      .send({ message: 'How much did I spend this month?' })
      .expect(201);
    expect(res.body.data.answer).toMatch(/spent/);
    expect(res.body.data.answer).not.toMatch(/32%/);
  });

  it('exports data without secrets', async () => {
    const res = await auth(api().get('/api/users/me/export')).expect(200);
    expect(res.body.data.profile.email).toBe(email);
    expect(JSON.stringify(res.body.data)).not.toMatch(/passwordHash"\s*:\s*"/);
  });
});
