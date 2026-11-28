import { balanceDelta } from './balance.js';

describe('balanceDelta', () => {
  it('adds income, subtracts spending', () => {
    expect(balanceDelta('INCOME', 10)).toBe(10);
    expect(balanceDelta('EXPENSE', 10)).toBe(-10);
  });

  it('subtracts outgoing transfers and adds incoming ones', () => {
    expect(balanceDelta('TRANSFER', 10)).toBe(-10);
    expect(balanceDelta('TRANSFER', 10, true)).toBe(10);
  });
});
