Here’s a **clean spec update for multi-currency support**, integrated with everything you already defined (accounts, reconciliation, goals, etc.).

This is a **first-class system**, not a bolt-on.

---

# 🌍 SPEC UPDATE — MULTI-CURRENCY & FOREX SYSTEM

---

# 1. Core Concept Update

Add to product philosophy:

> The app supports **multi-currency financial life** and provides a **unified financial view** by intelligently converting across currencies while preserving native account accuracy.

---

# 2. Core Design Principles (IMPORTANT)

1. **Accounts are always native currency**

   * Never store an account in mixed currency
   * Example:

     * Kookmin → KRW
     * GTBank → NGN

2. **Transactions are always in their original currency**

   * No mutation of original values

3. **Conversions are views, not replacements**

   * All conversions are derived, never overwrite raw data

4. **User always has a primary currency**

   * Used for:

     * dashboards
     * insights
     * goals
     * summaries

---

# 3. User Preferences Update

Add to `User`:

* primary_currency (e.g., KRW, NGN, USD)
* secondary_currencies (array)
* fx_preference:

  * real_time
  * daily_average
  * manual_override

---

# 4. Forex System (NEW CORE MODULE)

## FX Rate Source

System must fetch exchange rates:

* base → target currency pairs
* e.g.:

  * KRW → NGN
  * NGN → KRW
  * USD → KRW
  * USD → NGN

---

## Requirements

* store rates with timestamp
* cache rates locally
* update periodically (e.g. every 6 hours)
* fallback to last known rate if offline

---

## FXRate entity

* id
* base_currency
* target_currency
* rate
* source (API name)
* fetched_at

---

## Conversion function

```id="dps3g4"
converted_amount = original_amount * fx_rate
```

---

# 5. Accounts System Update

Each account:

* has fixed `currency`
* maintains balance ONLY in that currency

---

## Derived fields (important)

Add:

* converted_balance (based on primary currency)
* fx_rate_used
* last_fx_update

---

## Example

| Account | Currency | Balance   | Converted (KRW) |
| ------- | -------- | --------- | --------------- |
| GTBank  | NGN      | 500,000   | ₩450,000        |
| Kookmin | KRW      | 1,200,000 | ₩1,200,000      |

---

# 6. Dashboard Update (Major UX)

## Add unified financial view

Show:

### A. Native view

* each account in its own currency

### B. Unified view (PRIMARY CURRENCY)

* total net worth
* total income
* total expenses

---

## Example

**Primary currency: KRW**

* Total Net Worth: ₩1,650,000
* Includes:

  * ₩1,200,000 (KRW account)
  * ₩450,000 (converted from NGN)

---

## Toggle

Allow user to:

* switch primary currency
* view per-currency breakdown

---

# 7. Transactions Update

Each transaction must include:

* original_amount
* original_currency

Add derived:

* converted_amount
* fx_rate_used

---

## Important rule

Never lose:

* original currency
* original value

---

# 8. Goals System Update (VERY IMPORTANT)

Goals must support multi-currency.

---

## Goal model update

Add:

* target_currency (usually primary)
* contributions from multiple currencies allowed

---

## Example

Goal:

* Buy car → ₩10,000,000

User contributes:

* ₦200,000 (NGN)
* ₩500,000 (KRW)

System:

* converts NGN → KRW
* aggregates toward goal

---

## UX behavior

Show:

* total progress in goal currency
* breakdown by source currency

---

## Insight example

* “₦200,000 contributed equals ₩180,000 toward your goal”

---

# 9. Budgets System Update

Budgets are:

* defined in ONE currency (usually primary)

---

## Behavior

If transaction currency ≠ budget currency:

* convert before applying to budget

---

## Example

Budget:

* Food → ₩300,000

Transaction:

* ₦10,000 food

System:

* converts ₦10,000 → ₩9,000
* applies to budget

---

# 10. Balance & Reconciliation Update (CRITICAL)

Reconciliation must respect currency.

---

## Rule

Reconciliation ALWAYS happens in account currency.

---

## Example

GTBank (NGN):

* User enters:

  * “My balance is ₦520,000”

System:

* reconciles ONLY in NGN
* NOT in KRW

---

## Drift logic unchanged

But applied per currency.

---

# 11. NEW: Currency Exposure Insight

App should analyze:

* how much money is in each currency

---

## Example insight

* “70% of your funds are in KRW, 30% in NGN”
* “You are exposed to NGN depreciation risk”

---

# 12. NEW: FX Impact Insight

Track effect of exchange rate changes.

---

## Example

* “Your NGN savings lost ₩25,000 in value due to exchange rate changes”
* “KRW strengthened against NGN this week”

---

# 13. NEW: Currency Conversion Simulator

User can ask:

* “If I convert my NGN to KRW now, how much will I get?”
* “Should I hold NGN or convert?”

---

## Endpoint

`POST /assistant/fx-simulation`

Input:

* amount
* source currency
* target currency

Output:

* converted amount
* rate used
* simple explanation

---

# 14. Scenario Planning Update

Extend simulations to include FX.

---

## Example

* “If NGN drops by 10%, what happens to my goal?”
* “If I earn in USD, how does that help?”

---

## System should simulate:

* income currency changes
* exchange rate shifts
* cross-currency savings

---

# 15. NEW: Multi-Currency Income Tracking

Allow:

* income streams in different currencies

---

## Example

* Salary → KRW
* Freelance → USD
* Side hustle → NGN

---

## Insights

* “Your USD income contributes 40% of your total earnings”
* “Your NGN income is losing value vs KRW”

---

# 16. Notifications Update

Add:

* FX rate movement alerts
* currency imbalance alerts

Examples:

* “NGN weakened by 5% today”
* “Your KRW spending is rising faster than income”
* “You might benefit from converting NGN to KRW”

---

# 17. NEW: FX Settings UI

In settings:

* select primary currency
* choose FX update frequency
* enable/disable FX alerts
* manual override rate (advanced users)

---

# 18. Data Model Additions

## User

* primary_currency
* fx_preference

---

## FXRate

* id
* base_currency
* target_currency
* rate
* fetched_at

---

## Transaction (add)

* original_currency
* converted_amount
* fx_rate_used

---

## Account (add)

* currency
* converted_balance

---

# 19. Backend APIs (Additions)

## FX

* GET /fx/rates
* GET /fx/convert
* POST /assistant/fx-simulation

---

# 20. UX Philosophy Update

Add:

> The app should remove the mental burden of currency conversion by:
>
> * automatically converting
> * showing unified totals
> * preserving original values
> * explaining currency impact simply

---

# 21. Critical Engineering Notes

Add to Copilot:

> Multi-currency is NOT optional.
>
> Every financial calculation must:
>
> * respect currency boundaries
> * convert only when needed
> * never mix currencies implicitly
>
> Bugs here will destroy user trust.

---

# 22. MVP Scope for Multi-Currency

## MUST HAVE

* account-level currency
* transaction currency
* primary currency conversion
* dashboard unified view
* basic FX rate fetching
* goal aggregation across currencies

## CAN BE SIMPLIFIED

* FX insights (basic only)
* no historical FX tracking initially
* no predictive FX modeling in MVP

---

# 23. Updated One-Line Positioning

> “A voice-first financial assistant that tracks your money across accounts and currencies, corrects itself with you, and helps you reach real-life goals.”

