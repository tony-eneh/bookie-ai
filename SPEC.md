# Build Spec: Voice-First AI Budgeting and Financial Tracking Mobile App

## Project overview

Build a production-ready mobile app called **BookieAI** (working name) for people who are too lazy or too busy to manually track income, expenses, and financial goals.

The app should feel like a **conversational financial assistant**, not a spreadsheet tool.

Core concept:

* The app automatically detects likely financial transactions from **SMS** and optionally **email**
* It records them with minimal user effort
* When the app is unsure, it asks the user for clarification using **voice and chat**
* The user can speak naturally, and the app converts that into structured bookkeeping records
* The app helps users budget, track spending, monitor income targets, and plan for bigger life goals like buying a car, house, paying debt, or saving for travel

The experience should be:

* proactive
* low-friction
* voice-first
* AI-assisted
* clean and modern
* mobile-first
* especially optimized for Android first

---

# Important technical choice

Use **Flutter** for this project.

Reasoning behind this choice:

* Strong cross-platform support
* Better fit for custom background behavior and native integrations
* Good performance for mobile apps
* Easier to support Android-first features like SMS parsing while still keeping a path to iOS
* Good developer ergonomics for UI, state management, and local persistence

Target:

* **Phase 1:** Android first
* **Phase 2:** iOS support with graceful feature limitations where platform restrictions apply

---

# High-level product goals

The app should help users do these things with almost no manual effort:

1. Automatically detect income and expense events
2. Categorize transactions
3. Ask for clarification when unclear
4. Let users respond by voice or text
5. Track budgets and category spending
6. Track personal financial goals
7. Track income targets related to life goals
8. Give insights, summaries, and warnings
9. Make finance feel like a conversation, not accounting

---

# Non-goals for MVP

Do not build these in the first version:

* direct bank account integration
* card issuing
* loan products
* investment trading
* bill pay
* tax filing
* multi-user family finance
* advanced accounting double-entry system
* web app
* desktop app

Keep MVP focused on:

* transaction capture
* categorization
* budgeting
* goals
* AI assistant
* summaries
* notifications

---

# Primary users

## User type 1: Lazy tracker

Someone who hates typing expenses manually and wants the app to do the hard work.

## User type 2: Goal-driven planner

Someone who has medium-to-big goals like:

* buy a car in 2 years
* save for rent
* pay off debt
* hit monthly income goals
* reduce overspending

## User type 3: Conversational user

Someone who prefers speaking to the app instead of managing tables.

---

# Core product idea

The app should continuously help the user answer:

* What money came in?
* What money went out?
* What was that transaction for?
* Am I overspending?
* Am I on track for my goals?
* Am I earning enough each month for the life I want?
* If not, what needs to change?

---

# MVP features

## 1. Onboarding

Build onboarding flow with:

* welcome screens
* explanation of core value proposition
* permission education screens
* account creation / sign in
* user profile setup
* preferred currency
* country
* language
* monthly income style:

  * fixed salary
  * irregular income
  * business income
  * mixed income
* financial personality preference:

  * gentle
  * direct
  * coach-like

### Permissions to request carefully

Android:

* notifications
* microphone
* speech recognition if needed
* SMS read permission for transaction detection
* optional contacts not needed for MVP
* optional calendar not needed for MVP

Email integration:

* do not ask for email inbox access by default during first launch
* make it optional later from settings
* use explicit OAuth-based connection flow

Important:
Design the permission flow with explanation first, then OS permission request.

---

## 2. Authentication

Implement authentication with:

* email + password
* Google Sign-In
* Apple Sign-In placeholder for later
* secure token/session handling

Backend auth should support:

* JWT access token
* refresh token
* secure logout
* password reset
* email verification optional

---

## 3. Transaction ingestion

### A. SMS transaction ingestion

Android MVP only.

The app should:

* listen for new incoming SMS if possible under platform constraints, or
* periodically scan user-approved SMS inbox messages and extract likely bank transaction messages
* parse messages using rules + AI-assisted fallback
* identify:

  * amount
  * currency
  * debit or credit
  * date/time
  * source institution if possible
  * merchant or sender if possible
  * raw description text
  * confidence score

Examples:

* “Acct XXXX debited NGN 4,500 at SHOPRITE...”
* “You received ₩30,000...”
* “Transfer of 50,000 NGN from John...”

### B. Email transaction ingestion

Optional in MVP but structure code for it.

Support email providers later, but architecture now should allow:

* Gmail integration first
* scan only user-approved transaction-related emails
* parse financial alerts and receipts

### C. Manual voice logging

User can say:

* “I spent 12,000 won on lunch”
* “I got paid 350,000 naira today”
* “That debit was for fuel”
* “Transfer from Emeka was repayment”

The app should convert voice to structured transaction entries.

### D. Manual text logging

Provide fallback simple text input.

---

## 4. AI clarification flow

This is one of the most important features.

When the system detects a transaction but is unsure, it should create a pending clarification item.

Examples:

* unclear merchant
* unclear category
* unclear whether personal or business
* unclear whether transfer, savings, loan repayment, income, expense, or internal movement

The app should then ask the user naturally.

Examples:

* “I noticed a debit of ₦8,500. Was that transport, food, bills, or something else?”
* “You received ₩150,000. Was that salary, business income, repayment, or a gift?”
* “This transfer looks unclear. Can you explain what it was for?”

User can respond by:

* voice
* text
* choosing quick suggestion chips

The response should update the transaction and also improve future classification.

---

## 5. Transaction categorization

Create a flexible category system.

Default categories:

### Expense categories

* Food & Dining
* Groceries
* Transport
* Fuel
* Rent
* Utilities
* Internet
* Mobile/Data
* Healthcare
* Education
* Shopping
* Entertainment
* Subscriptions
* Savings
* Debt Repayment
* Gifts/Donations
* Family Support
* Business Expense
* Travel
* Miscellaneous

### Income categories

* Salary
* Freelance
* Business Income
* Gift Received
* Refund
* Loan Received
* Repayment Received
* Investment Income
* Miscellaneous Income

### Transfer categories

* Internal Transfer
* Savings Transfer
* Wallet Funding
* Bank Transfer

The categorization engine should use:

1. deterministic rules first
2. user history
3. merchant mapping
4. AI fallback classification
5. user correction learning

Every transaction should have:

* category
* optional subcategory
* confidence score
* source of classification:

  * auto_rule
  * ai
  * user
  * learned_pattern

---

## 6. Dashboard

Build a clean dashboard with:

* current month income
* current month expenses
* net cash flow
* budget progress
* top categories
* pending clarifications
* goal progress
* quick voice action button
* recent transactions
* smart insights card

Also include:

* “This month you spent 18% more on eating out”
* “You are behind your savings target”
* “You are on track for your car goal”
* “Your income this month is below target by ₦120,000”

---

## 7. Budgets

Allow users to create budgets in a friendly way.

Examples:

* “Set my food budget to 150,000 naira monthly”
* “I want to spend at most 200 dollars on takeout”
* “Keep transport under 60,000 won this month”

Budget types:

* monthly category budget
* weekly spending cap
* overall monthly spending target

Budget progress UI:

* amount used
* amount remaining
* percentage used
* projected overspend warning

Alerts:

* 50% used
* 80% used
* overspent
* projected overspend before month-end

---

## 8. Goals and life planning

This is a signature feature.

Users should be able to set high-level goals like:

* buy a car by December 2027
* save for rent in 6 months
* build emergency fund of ₦2,000,000
* hit monthly business income of ₦800,000
* save ₩10,000,000 for relocation
* pay off debt by next year

Each goal should support:

* goal title
* target amount
* target date
* priority
* linked contribution source:

  * savings only
  * net surplus
  * custom category
* recurring monthly contribution target
* current progress
* confidence status

The app should calculate:

* required monthly savings
* required monthly income if user also has living costs
* gap to target
* projected completion date based on current behavior

It should be able to say things like:

* “At your current pace, you will miss your car goal by 5 months.”
* “To hit this target, you need to increase monthly surplus by ₦85,000.”
* “You need average monthly income of ₦600,000 to stay on track.”

This feature should feel like life planning, not just bookkeeping.

---

## 9. Conversational finance assistant

Build a chat/voice assistant screen.

The user should be able to ask:

* “How much did I spend on food this month?”
* “What was that 12,000 won transaction yesterday?”
* “Can I afford a car by next year?”
* “How much do I need to earn monthly to buy land in two years?”
* “What category is draining me the most?”
* “Summarize my week”
* “What should I cut if I want to save more?”
* “Show me all transfers from John”

Assistant modes:

* chat
* voice
* hybrid

The assistant should:

* answer from user data
* suggest actions
* request clarification when needed
* update structured records with user confirmation

---

## 10. Notifications and proactive nudges

Make the app slightly intrusive but useful, not annoying.

Notification types:

* new transaction detected
* clarification needed
* budget threshold warning
* unusual spending alert
* income target warning
* weekly summary ready
* monthly summary ready
* goal risk alert
* inactivity reminder

Examples:

* “You just spent ₦14,200. Was that groceries or dining?”
* “You’re close to overspending on transport.”
* “You are behind your income target for this month.”
* “Want a 30-second summary of your finances this week?”

Allow notification intensity setting:

* minimal
* standard
* proactive
* coach mode

---

## 11. Weekly and monthly summaries

Generate clean summaries.

### Weekly summary

* total income
* total expense
* net cash flow
* biggest expense category
* progress toward goals
* pending clarifications
* comparison with previous week

### Monthly summary

* month income vs expense
* category breakdown
* trend vs previous month
* best and worst habits
* savings rate
* goal progress
* major insights
* suggested plan for next month

Support both:

* text summary
* audio playback via TTS

---

## 12. Search and filtering

Transactions screen should support:

* date filter
* amount filter
* category filter
* income/expense/transfer filter
* confidence filter
* source filter:

  * SMS
  * email
  * voice
  * manual
* search by merchant/description/notes

---

## 13. Corrections and learning

When a user edits a transaction or corrects a category, store that behavior.

Examples:

* user always maps “POS Purchase XYZ” to Groceries
* user classifies “Transfer from Mom” as Gift Received
* user maps “Bolt” to Transport

Create a lightweight learning layer so the app becomes more accurate over time.

---

# Nice-to-have features after MVP

* receipt image scanning
* WhatsApp/email receipt import
* household/shared budgets
* multiple wallets/accounts
* business vs personal mode
* subscription detection
* recurring payment detection
* debt tracker
* cash transaction quick capture
* savings recommendations
* bank API integrations
* smart financial health score

---

# Platform constraints and product behavior

Design with real-world constraints in mind.

## Android

Support:

* SMS-based ingestion
* voice input
* notifications
* background tasks where allowed

## iOS

Do not assume iOS can access SMS inbox the same way.
For iOS:

* support manual voice logging
* email-based ingestion if user connects email
* notification-driven reminders
* same AI assistant and budgeting flows where possible

Architect the codebase so platform-specific capabilities are abstracted cleanly.

---

# UX principles

The UI should be:

* elegant
* minimal
* premium
* calm
* conversational
* simple for non-finance users

Design inspiration:

* modern fintech app
* soft cards
* clean charts
* subtle gradients
* excellent empty states
* strong use of icons
* polished voice interaction affordances

The app should not feel like accounting software.

---

# Core screens

Implement these screens.

## 1. Splash / launch

* logo
* loading
* auth state check

## 2. Onboarding

* intro slides
* permissions
* account setup
* goals intro

## 3. Sign in / sign up

## 4. Home dashboard

## 5. Transactions list

## 6. Transaction detail

* raw message
* parsed fields
* category
* source
* notes
* confidence
* edit actions

## 7. Pending clarifications inbox

## 8. Voice assistant / chat assistant

## 9. Budgets screen

## 10. Goals screen

* goal list
* goal detail
* projections

## 11. Insights screen

* trends
* top spending categories
* monthly comparisons

## 12. Notifications center

## 13. Settings

* permissions
* email connection
* notification intensity
* preferred voice
* currency
* export data
* privacy controls

## 14. Profile

---

# Tech stack

## Mobile app

* Flutter
* Dart
* Riverpod for state management
* GoRouter for navigation
* Dio for HTTP client
* Freezed + json_serializable for models
* Hive or Isar for local caching/persistence
* flutter_secure_storage for tokens/secrets
* speech_to_text for voice input
* flutter_tts for voice playback
* local notifications package
* charts package like fl_chart
* permission_handler
* platform channel/native integration for Android SMS access

## Backend

Use **NestJS** for backend.

Reason:

* strong structure
* scalable
* good fit for auth, APIs, background jobs
* TypeScript consistency
* easy to extend with AI services

### Backend stack

* NestJS
* PostgreSQL
* Prisma ORM
* Redis for queues/caching
* BullMQ for async jobs
* JWT auth
* OpenAPI / Swagger
* class-validator
* background workers for parsing/summaries/AI tasks

## AI layer

Use provider abstraction so model can be swapped.

Suggested initial approach:

* OpenAI-compatible provider wrapper
* prompt-based extraction
* prompt-based categorization
* prompt-based conversational Q&A over structured financial data
* deterministic rules before LLM whenever possible

## Infrastructure

* Dockerized services
* docker-compose for local dev
* CI via GitHub Actions
* deploy backend to Railway / Render / Fly.io / AWS
* object storage optional later
* Sentry for error tracking

---

# Architecture

Use a modular architecture.

## Mobile architecture

Feature-first structure:

* auth
* onboarding
* dashboard
* transactions
* clarifications
* budgets
* goals
* insights
* assistant
* settings
* notifications

Each feature should have:

* presentation
* application/state
* domain
* data

## Backend architecture

Modules:

* auth
* users
* transactions
* ingestion
* sms-parser
* email-parser
* clarifications
* budgets
* goals
* insights
* ai
* notifications
* learning
* summaries
* analytics
* admin

---

# Suggested repository structure

## Root

* `/apps/mobile`
* `/apps/api`
* `/packages/shared-types`
* `/packages/config`
* `/infra`
* `/docs`

If monorepo is too much friction for Copilot, use:

* single repo with `/mobile` and `/server`

Preferred:

* monorepo using Turborepo or pnpm workspace if comfortable
* otherwise simple multi-folder repo

Because Flutter is involved, simplest path may be:

* `/mobile` for Flutter
* `/server` for NestJS
* `/docs`

---

# Data model

Design clean schema.

## User

* id
* email
* password_hash nullable for social auth
* full_name
* country
* currency
* language
* onboarding_completed
* notification_mode
* financial_personality
* created_at
* updated_at

## ConnectedAccount

* id
* user_id
* provider_type (gmail, etc.)
* provider_email
* access_token encrypted if stored
* refresh_token encrypted if stored
* scopes
* status
* created_at
* updated_at

## Transaction

* id
* user_id
* type (income, expense, transfer)
* amount
* currency
* occurred_at
* description
* merchant_name nullable
* counterparty nullable
* category_id nullable
* subcategory nullable
* source_type (sms, email, voice, manual, ai_import)
* source_ref nullable
* raw_content nullable
* parse_confidence
* category_confidence
* needs_clarification boolean
* clarification_status
* note nullable
* is_recurring_guess boolean
* created_at
* updated_at

## Category

* id
* user_id nullable for system/global
* name
* type (income, expense, transfer)
* icon
* color optional
* is_default

## Clarification

* id
* user_id
* transaction_id
* question_text
* status (pending, answered, dismissed)
* answer_text nullable
* answer_source (voice, text, tap)
* created_at
* resolved_at nullable

## Budget

* id
* user_id
* name
* category_id nullable
* period_type (weekly, monthly)
* amount
* currency
* start_date
* end_date nullable
* active

## Goal

* id
* user_id
* title
* description nullable
* target_amount
* current_amount
* currency
* target_date
* priority
* linked_budget_strategy nullable
* monthly_required_amount
* required_monthly_income nullable
* status (on_track, at_risk, off_track, achieved)
* created_at
* updated_at

## GoalContribution

* id
* goal_id
* transaction_id nullable
* amount
* contribution_date
* source_type

## Insight

* id
* user_id
* insight_type
* title
* body
* severity
* period_start
* period_end
* metadata json
* created_at

## Notification

* id
* user_id
* type
* title
* body
* read_at nullable
* action_payload json
* created_at

## MerchantAlias / ClassificationRule

* id
* user_id
* match_pattern
* merchant_name nullable
* category_id
* transaction_type nullable
* confidence_boost
* created_at

## IncomeTarget

Optional separate entity or derive from goals.

* id
* user_id
* title
* target_monthly_income
* effective_from
* effective_to nullable
* reason

---

# Backend APIs

Build REST APIs first.

## Auth

* POST /auth/register
* POST /auth/login
* POST /auth/google
* POST /auth/refresh
* POST /auth/logout
* POST /auth/forgot-password
* POST /auth/reset-password
* GET /auth/me

## User

* GET /users/me
* PATCH /users/me
* PATCH /users/preferences

## Transactions

* GET /transactions
* POST /transactions
* GET /transactions/:id
* PATCH /transactions/:id
* DELETE /transactions/:id

## Transaction import / ingestion

* POST /ingestion/sms/parse
* POST /ingestion/email/parse
* POST /ingestion/voice-log
* POST /ingestion/manual-entry

## Clarifications

* GET /clarifications
* POST /clarifications/:id/respond
* POST /clarifications/:id/dismiss

## Categories

* GET /categories
* POST /categories
* PATCH /categories/:id
* DELETE /categories/:id

## Budgets

* GET /budgets
* POST /budgets
* GET /budgets/:id
* PATCH /budgets/:id
* DELETE /budgets/:id

## Goals

* GET /goals
* POST /goals
* GET /goals/:id
* PATCH /goals/:id
* DELETE /goals/:id
* GET /goals/:id/projection

## Insights

* GET /insights/weekly
* GET /insights/monthly
* GET /insights/dashboard

## Assistant

* POST /assistant/chat
* POST /assistant/voice-query
* POST /assistant/clarify-transaction
* POST /assistant/goal-planning

## Notifications

* GET /notifications
* PATCH /notifications/:id/read

## Connected accounts

* POST /integrations/gmail/connect
* POST /integrations/gmail/callback
* DELETE /integrations/:id

---

# AI behavior requirements

Use AI where helpful, but keep the system deterministic where possible.

## AI use cases

1. parse ambiguous transaction messages
2. classify transactions when rules are weak
3. generate clarification questions
4. answer user finance questions
5. generate summaries and insights
6. estimate goal feasibility and income gaps
7. transform voice/text freeform statements into structured actions

## Important rule

Never let the LLM directly mutate data without a validation layer.

Use pipeline:

1. user input / raw transaction
2. AI interpretation
3. schema validation
4. confidence scoring
5. optional user confirmation
6. persist

## Required structured outputs

Use JSON schema responses for:

* transaction extraction
* category classification
* goal planning output
* clarification question generation

---

# Example AI prompts to support internally

Not necessarily exposed to users.

## Transaction extraction

Extract:

* amount
* currency
* type
* merchant/counterparty
* datetime if known
* category guess
* explanation
* confidence
* ambiguity flags

## Clarification generation

Given incomplete transaction data, generate a short human question with 3–5 likely answer options.

## Goal planner

Input:

* target amount
* target date
* current savings
* estimated monthly expenses
* current average income

Output:

* required monthly savings
* required monthly income
* risk status
* short coaching advice

---

# Background jobs

Implement async jobs for:

* SMS parse processing
* email parse processing
* summary generation
* insights generation
* recurring pattern detection
* user learning rule updates
* notification dispatch
* monthly projection refresh

---

# Mobile offline behavior

Support useful offline mode:

* cached dashboard
* locally saved transactions
* queued manual entries
* queued clarification responses
* background sync when back online

---

# Security and privacy requirements

This app handles sensitive financial data. Treat it seriously.

Requirements:

* encrypt secrets/tokens
* do not store unnecessary raw inbox content longer than needed
* minimize retained raw SMS/email content
* secure API auth
* server-side validation
* rate limiting
* audit important changes
* allow user to disconnect email
* allow user to export/delete data
* transparent privacy explanations

Build a privacy settings page with:

* SMS access toggle/explanation
* email access toggle/explanation
* voice data explanation
* delete my data
* export my data

---

# Analytics

Track product analytics events:

* onboarding_completed
* permission_granted_sms
* permission_denied_sms
* transaction_detected
* clarification_created
* clarification_answered
* transaction_category_corrected
* budget_created
* goal_created
* weekly_summary_opened
* monthly_summary_opened
* assistant_query_sent
* assistant_voice_used

Use PostHog or similar.

---

# Testing requirements

## Mobile

* widget tests
* unit tests for domain logic
* integration tests for key flows

## Backend

* unit tests
* service tests
* e2e tests for major APIs

Critical test coverage:

* auth
* SMS parsing
* categorization
* clarification flow
* goal projection logic
* budget threshold alerts

---

# Seed/demo data

Include demo mode or local seed data with:

* realistic transactions
* sample goals
* budgets
* clarifications
* dashboard insights

This helps quickly preview the app.

---

# Initial UI styling requirements

Use a premium fintech style.

Theme:

* dark + light mode
* soft green/blue accent
* polished cards
* rounded corners
* subtle shadows
* clean typography
* clear hierarchy

Key UI components:

* balance cards
* category chips
* progress bars
* donut/pie charts
* line charts
* floating voice button
* transaction confidence badges
* insight cards
* chat bubbles
* bottom navigation

Bottom nav tabs:

* Home
* Transactions
* Assistant
* Goals
* Settings

---

# Acceptance criteria for MVP

The MVP is successful if:

1. User can sign up and log in
2. User can grant SMS access on Android
3. App can parse at least common bank transaction SMS patterns into structured transactions
4. App can create pending clarifications for ambiguous transactions
5. User can answer clarifications by voice or text
6. App updates the transaction correctly after clarification
7. User can view dashboard totals and recent transactions
8. User can create and track budgets
9. User can create and track goals
10. App can estimate whether goal is on track or off track
11. User can ask assistant simple financial questions
12. Weekly and monthly summaries are generated
13. Notifications work for clarifications and budget warnings
14. Codebase is clean, modular, documented, and runnable locally

---

# Delivery requirements

Generate a working repo with:

* complete Flutter mobile app
* complete NestJS backend
* PostgreSQL schema via Prisma
* Docker setup for backend database + Redis
* environment variable examples
* README with setup instructions
* sample seed script
* Swagger docs
* basic tests
* clean architecture
* sensible comments
* no placeholder junk unless clearly marked

---

# README requirements

The repo README should include:

* project overview
* architecture overview
* tech stack
* local setup
* environment variables
* how to run mobile app
* how to run backend
* how to run database and Redis
* how SMS ingestion currently works
* platform limitations
* privacy notes
* future roadmap

---

# Phased implementation plan

## Phase 1

* auth
* onboarding
* transaction CRUD
* Android SMS parsing
* clarifications
* dashboard
* budgets
* goals
* assistant basic Q&A
* summaries
* notifications

## Phase 2

* email integration
* smarter AI learning
* recurring transaction detection
* better insights
* improved iOS path

## Phase 3

* bank integrations
* receipt OCR
* shared budgets
* subscription management intelligence
* debt planning

---

# Specific engineering guidance for Copilot

Please scaffold and implement this project end-to-end with clean, maintainable code.

Prioritize:

* working MVP over perfection
* modular architecture
* realistic demo data
* strong typing
* clear docs
* clean UI
* easy local setup

Do not over-engineer with unnecessary abstraction, but keep extensibility in mind.

Where platform policies or native permission constraints may vary, encapsulate that logic cleanly and document assumptions.

Implement a polished experience with enough completeness that a developer can clone the repo, run it locally, and meaningfully test the app.
