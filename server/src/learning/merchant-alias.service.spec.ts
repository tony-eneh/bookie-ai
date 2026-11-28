import { MerchantAliasService } from './merchant-alias.service.js';
import type { PrismaService } from '../prisma/prisma.service.js';

describe('MerchantAliasService', () => {
  describe('normalize', () => {
    it.each([
      ['SHOPRITE  LEKKI #123', 'shoprite lekki'],
      ['SPAR VI on 27-11-2026', 'spar vi'],
      ['Uber *TRIP ref 8812', 'uber trip'],
      ['ab', null],
      [null, null],
    ])('%p -> %p', (input, expected) => {
      expect(MerchantAliasService.normalize(input)).toBe(expected);
    });
  });

  it('prefers an exact merchant match, then a name inside the text', async () => {
    const aliases = [
      { matchPattern: 'spar', categoryId: 'groceries', transactionType: null },
      { matchPattern: 'netflix', categoryId: 'subs', transactionType: 'EXPENSE' },
    ];
    const prisma = {
      merchantAlias: { findMany: jest.fn().mockResolvedValue(aliases) },
    } as unknown as PrismaService;
    const service = new MerchantAliasService(prisma);

    await expect(service.lookup('u', 'SPAR', 'x')).resolves.toMatchObject({
      categoryId: 'groceries',
    });
    await expect(
      service.lookup('u', null, 'USD 10 charged at NETFLIX.COM'),
    ).resolves.toMatchObject({ categoryId: 'subs' });
    await expect(service.lookup('u', null, 'sparkling water')).resolves.toBeNull();
  });
});
