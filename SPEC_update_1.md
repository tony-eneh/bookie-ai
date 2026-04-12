Here’s an **updated version of your spec**, incorporating:

* ✅ **Accounts system (critical)**
* ✅ **Balance reconciliation strategy**
* ✅ **Email + statement ingestion flow**
* ✅ **Ground-truth correction via user checkpoints**
* ✅ **Scenario planning (financial simulation)**

Only the **changed/new sections** are included so you can merge cleanly into your existing spec.

---

# 🔁 SPEC UPDATE — ACCOUNTS, BALANCES, RECONCILIATION, SCENARIOS

---

# 1. Core Concept Update (IMPORTANT)

Add this to your **core product idea**:

> The app maintains a **real-time estimated financial state** based on detected transactions, and periodically reconciles against **user-provided or imported ground-truth balances** to ensure accuracy.

---

# 2. NEW: Accounts System (FOUNDATIONAL)

## Concept

Users must have **multiple financial accounts**, each with its own balance and transaction history.

Examples:

* Bank accounts (GTBank, Kookmin, Chase)
* Mobile wallets (Opay, KakaoPay)
* Cash wallet
* Business account
* Savings account

---

## Requirements

### Account entity must include:

* id
* user_id
* name (e.g., “Kookmin Bank”, “Cash Wallet”)
* type:

  * bank
  * wallet
  * cash
  * savings
  * business
* currency
* current_balance (derived or reconciled)
* last_reconciled_balance
* last_reconciled_at
* is_primary
* is_active
* created_at
* updated_at

---

## UX behavior

* User can create accounts manually during onboarding or later
* App suggests accounts based on SMS/email patterns
* Transactions MUST always belong to an account
* Default account used if unclear (user can reassign)

---

# 3. Transaction Model Update

Update `Transaction`:

Add:

* account_id (REQUIRED)
* balance_after_transaction (nullable)
* is_balance_source (boolean → true if SMS/email included balance)

---

# 4. NEW: Balance Strategy (CRITICAL DESIGN)

The app operates on **two layers of truth**:

## Layer 1 — Estimated Balance (continuous)

Calculated as:

```
initial_balance + sum(all transactions)
```

Used for:

* real-time UI
* projections
* insights

---

## Layer 2 — Ground Truth Balance (authoritative checkpoints)

Sources:

* SMS that includes balance
* Email statements
* User manual input
* Imported bank statements

Used for:

* correcting drift
* recalibration

---

## Problem Being Solved

* SMS may be missing
* Some banks don’t send balances
* Parsing is imperfect
* Users forget transactions

→ Therefore system must **reconcile periodically**

---

# 5. NEW: Balance Reconciliation System

## A. Automatic reconciliation (when possible)

If SMS/email contains balance:

* mark transaction as `is_balance_source = true`

* update:

  * account.last_reconciled_balance
  * account.last_reconciled_at

* compute drift:

```
drift = reported_balance - estimated_balance
```

If drift exceeds threshold:

* flag discrepancy
* trigger reconciliation flow

---

## B. Manual reconciliation (core UX feature)

App should periodically ask:

Examples:

* “What’s your current balance in Kookmin Bank?”
* “Let’s confirm your account balance to stay accurate.”

User can:

* input balance manually
* speak it via voice

---

## C. Reconciliation logic

When user provides balance:

```
drift = actual_balance - estimated_balance
```

System actions:

1. Store reconciliation snapshot
2. Adjust account baseline
3. Optionally create:

   * synthetic “adjustment transaction” OR
   * hidden correction offset

---

## D. UX for discrepancies

Show:

* “We are off by ₩25,000”
* “Some transactions may be missing”
* “Would you like to fix this?”

Options:

* ignore
* adjust automatically
* review transactions

---

# 6. NEW: Email + Statement Import Flow

## A. Email ingestion upgrade

Support:

* transaction alert emails
* periodic bank summaries
* downloadable statements

---

## B. Statement ingestion (POWER FEATURE)

User flow:

1. App says:

   > “To improve accuracy, you can import your bank statement.”

2. User:

   * downloads statement from bank app
   * bank emails PDF/CSV

3. App:

   * detects email
   * parses attachment
   * extracts full transaction history

---

## Supported formats

* CSV
* PDF (basic parsing for MVP)
* plain text email summaries

### Current MVP limitation

* statement import only supports transactions that are unambiguously `income` or `expense`
* imported `transfer` transactions must be rejected for now because the import payload does not yet capture transfer direction or linked source/destination account context

### TODO: full transfer import support

Add a follow-up contract for statement imports that includes enough metadata to model transfers correctly, such as:

* transfer direction relative to the imported account
* source account and destination account identifiers when known
* creation of linked offsetting transactions when the transfer spans two tracked accounts

---

## C. Statement reconciliation

When statement imported:

* match existing transactions
* detect missing ones
* insert missing transactions
* recompute balances

---

## D. Conflict handling

If mismatch:

* show diff UI:

  * “We found 5 missing transactions”
  * “We found 2 mismatches”

User can:

* accept all
* review individually

---

# 7. NEW: Drift Detection System

Continuously monitor:

```
expected_balance vs known_balance
```

Triggers:

* large unexplained gap
* frequent unknown transactions
* low confidence parsing streak

System actions:

* increase clarification prompts
* suggest statement import
* request manual balance check

---

# 8. NEW: Scenario Planning (Financial Simulation)

## Feature concept

User can simulate “what if” situations.

---

## Example queries

* “What if I increase my income by 20%?”
* “What if I reduce food spending by ₩200,000?”
* “Can I buy a car if I save ₦100k monthly?”
* “What happens if I stop subscriptions?”

---

## System behavior

Simulate:

* future cash flow
* goal timelines
* budget impact
* surplus/deficit

---

## Output

* projected completion date
* savings curve
* income requirement delta
* risk level

---

## Example response

* “If you increase income by ₦100k/month, you reach your goal 4 months earlier.”
* “Reducing dining by ₩150k/month puts you back on track.”

---

## Implementation

Create:

`POST /assistant/scenario`

Input:

* current state
* hypothetical changes

Output:

* projections
* explanation
* recommended action

---

# 9. NEW: Income Reality Check System

Tie income to goals.

## Concept

App should detect:

* mismatch between:

  * current income
  * required income for goals

---

## Example insights

* “You need ₦700k/month but currently earn ₦450k”
* “At current income, your goal is unrealistic”
* “You must increase income or extend timeline”

---

## System behavior

* auto-generate income targets
* compare monthly performance
* notify user when behind

---

# 10. UPDATED: Notifications (Additions)

Add new types:

* balance mismatch alert
* reconciliation reminder
* statement import suggestion
* missing transaction suspicion
* scenario suggestion

Examples:

* “Your balance seems off. Let’s fix it.”
* “Import your bank statement to improve accuracy”
* “You’re missing transactions from last week”
* “Want to see how to reach your goal faster?”

---

# 11. NEW: Account UI Requirements

## Accounts screen

Show:

* list of accounts
* current balance
* last updated time
* confidence indicator (important)

---

## Account detail

* transaction history
* balance trend chart
* reconciliation history
* drift indicator

---

## Confidence indicator (unique feature)

Each account should show:

* High confidence ✅
* Medium ⚠️
* Low ❌

Based on:

* recent reconciliation
* parsing accuracy
* missing data likelihood

---

# 12. UPDATED: Data Model Additions

## AccountReconciliation

* id
* account_id
* balance
* source:

  * sms
  * email
  * manual
  * statement
* drift_amount
* created_at

---

## StatementImport

* id
* user_id
* account_id
* source (email/manual upload)
* file_type
* parsed_successfully
* transactions_imported
* created_at

---

## ScenarioSimulation

* id
* user_id
* input_payload
* result_payload
* created_at

---

# 13. NEW: UX Philosophy Update

Add:

> The app should **never pretend to be perfectly accurate**.
> Instead, it should:
>
> * show confidence
> * ask for correction
> * continuously improve accuracy with user collaboration

---

# 14. MVP Priority Adjustment

Reorder priorities:

## Must include in MVP:

* accounts system
* transaction → account linkage
* basic reconciliation (manual)
* drift detection (simple)
* account balance display

## Can be simplified in MVP:

* statement import (basic CSV first)
* scenario planning (basic version)
* email ingestion (phase 2 if needed)

---

# 15. Critical Engineering Note

Add to Copilot instructions:

> Treat **accounts + balances + reconciliation** as a first-class system, not an add-on.
>
> The credibility of the app depends on:
>
> * how accurate balances feel
> * how transparently errors are handled
> * how easy it is to correct mistakes

---

# 16. One-Line Product Positioning (Updated)

> “A voice-first financial assistant that tracks your money automatically, corrects itself with you, and helps you reach life goals—not just balance numbers.”
