import { parseAmount, parseDate, parseStatementCsv, splitCsvLine } from './csv.js';

describe('statement CSV parsing', () => {
  it('reads a signed Amount column with a preamble', () => {
    const csv = [
      'Account: 0123456789',
      'Statement period: Nov 2026',
      'Date,Description,Amount,Balance',
      '2026-11-03,"SHOPRITE, LEKKI",-4500.00,95500.00',
      '2026-11-05,Salary November,"350,000.00",445500.00',
      ',Closing balance,,445500.00',
    ].join('\n');
    const { rows, skippedLines } = parseStatementCsv(csv);
    expect(rows).toEqual([
      expect.objectContaining({ type: 'EXPENSE', amount: 4500, description: 'SHOPRITE, LEKKI' }),
      expect.objectContaining({ type: 'INCOME', amount: 350000, description: 'Salary November' }),
    ]);
    expect(skippedLines).toBe(1);
  });

  it('reads Debit/Credit columns, semicolons and DD/MM dates', () => {
    const csv = [
      'Trans. Date;Narration;Withdrawal;Deposit',
      '28/11/2026;POS KFC IKEJA;1200;',
      '29/11/2026;Transfer from Emeka;;15000',
    ].join('\n');
    const { rows } = parseStatementCsv(csv);
    expect(rows[0]).toMatchObject({ type: 'EXPENSE', amount: 1200 });
    expect(rows[0].occurredAt.slice(0, 10)).toBe('2026-11-28');
    expect(rows[1]).toMatchObject({ type: 'INCOME', amount: 15000 });
  });

  it('explains a file without recognisable headers', () => {
    expect(() => parseStatementCsv('a,b,c\n1,2,3')).toThrow(/column headers/);
  });

  it('handles amount and date variants', () => {
    expect(parseAmount('(500.00)')).toBe(-500);
    expect(parseAmount('1,234.50 DR')).toBe(-1234.5);
    expect(parseAmount('₦2,000')).toBe(2000);
    expect(parseAmount('')).toBeNull();
    expect(parseDate('05 Nov 2026')?.slice(0, 10)).toBe('2026-11-05');
    expect(parseDate('11/25/2026')?.slice(0, 10)).toBe('2026-11-25');
    expect(parseDate('nope')).toBeNull();
    expect(splitCsvLine('a,"b ""q"" c",d', ',')).toEqual(['a', 'b "q" c', 'd']);
  });
});
