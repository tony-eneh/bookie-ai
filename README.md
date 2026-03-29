# BookieAI

**Track nothing. Know everything.**

A voice-first, AI-powered personal finance app that automatically tracks transactions, reconciles balances, supports multi-currency accounts, and helps users achieve real-life financial goals with minimal effort.

---

## 🚀 Overview

BookieAI is designed for people who don’t want to manually track their finances.

Instead of spreadsheets and manual entry, BookieAI:

- Automatically detects transactions from SMS and email
- Asks for clarification when needed (via voice or chat)
- Learns from user behavior over time
- Tracks budgets, goals, and income targets
- Handles multiple currencies seamlessly
- Reconciles account balances to stay accurate

This is not just a budgeting app — it’s a **financial assistant**.

---

## ✨ Key Features

### 📩 Automatic Transaction Tracking
- SMS-based transaction detection (Android)
- Email ingestion (alerts, receipts, statements)
- Voice and manual transaction entry
- AI-assisted parsing and categorization

---

### 🧠 AI Financial Assistant
- Ask questions like:
  - “How much did I spend on food this month?”
  - “Can I afford a car next year?”
- Voice + chat interface
- Smart clarifications for unknown transactions

---

### 🏦 Accounts & Balance Tracking
- Multiple accounts (bank, wallet, cash, business)
- Per-account balances
- Real-time estimated balance
- Ground-truth reconciliation system

---

### 🔄 Balance Reconciliation
- Handles missing or incomplete transaction data
- Uses:
  - SMS balance messages
  - user input
  - imported statements
- Detects and corrects drift automatically

---

### 🌍 Multi-Currency Support
- Native currency per account (e.g., KRW, NGN, USD)
- Unified dashboard in a primary currency
- Real-time FX conversion
- Currency exposure and FX impact insights

---

### 📊 Budgets & Spending Control
- Category-based budgets
- Overspending alerts
- Weekly/monthly tracking
- Smart recommendations

---

### 🎯 Goals & Life Planning
- Set goals like:
  - buying a car
  - saving for rent
  - hitting income targets
- Tracks progress across currencies
- Calculates required income/savings
- Warns when goals are at risk

---

### 🔮 Scenario Planning
- Simulate:
  - “What if I increase income?”
  - “What if I cut spending?”
- See impact on goals and timelines

---

### 🔔 Smart Notifications
- Transaction clarifications
- Budget warnings
- Goal risk alerts
- Balance mismatch detection
- Weekly/monthly summaries

---

## 🏗️ Tech Stack

### Mobile
- Flutter
- Dart
- Riverpod (state management)
- GoRouter (navigation)
- Dio (HTTP client)
- Hive / Isar (local storage)
- speech_to_text / TTS
- fl_chart

---

### Backend
- NestJS (TypeScript)
- PostgreSQL
- Prisma ORM
- Redis + BullMQ (background jobs)
- JWT authentication

---

### AI Layer
- OpenAI-compatible provider (pluggable)
- Structured JSON outputs
- Used for:
  - parsing
  - categorization
  - assistant responses
  - insights

---

### Infrastructure
- Docker
- GitHub Actions (CI/CD)
- Deployable to:
  - Railway / Render / Fly.io / AWS

---

## 📁 Project Structure

```

/mobile        # Flutter app
/server        # NestJS API
docker-compose.yml
SPEC.md
SPEC_update_1.md
SPEC_update_2.md

````

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK
- Node.js (>= 20)
- Docker
- PostgreSQL (or Dockerized)

---

## 🧩 Backend Setup

```bash
docker compose up -d   # starts postgres + redis from repo root
cd server
cp .env.example .env
npm install
npm run prisma:generate
npx prisma migrate dev
npx prisma db seed
npm run start:dev
````

API will run on: `http://localhost:3000`

Swagger docs: `http://localhost:3000/api`

---

## 📱 Mobile App Setup

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🔐 Environment Variables (Backend)

Create `.env` in `/server`:

```

DATABASE_URL=postgresql://user:password@localhost:5432/bookieai
JWT_SECRET=your_secret
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your_key
APP_URL=http://localhost:3000
GOOGLE_CLIENT_ID=your_google_client_id
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your_smtp_user
SMTP_PASS=your_smtp_password
SMTP_FROM=BookieAI <no-reply@bookieai.com>

```

For the full backend environment reference, see `server/.env.example` and `server/README.md`.

---

## 🧠 How It Works

### 1. Transaction Ingestion

* SMS/email parsed into structured transactions
* AI used only when rules are insufficient

---

### 2. Categorization

* Rules → history → AI fallback → user correction

---

### 3. Balance Tracking

* Estimated balance = sum of transactions
* Reconciled balance = ground truth (user or statement)

---

### 4. Drift Detection

* Detects mismatch between expected and real balances
* Prompts user to fix inconsistencies

---

### 5. Multi-Currency Engine

* Keeps original currency intact
* Converts for unified views only
* Uses cached FX rates

---

### 6. Assistant

* Answers questions from structured financial data
* Can trigger actions (e.g., categorize, simulate)

---

## 🔒 Privacy & Security

* Sensitive data handled securely
* Tokens encrypted
* Minimal raw message storage
* User can:

  * disconnect email
  * delete all data
  * export data

---

## ⚠️ Platform Limitations

### Android

* SMS ingestion supported

### iOS

* No SMS access
* Uses:

  * manual input
  * email ingestion
  * assistant interaction

---

## 🧪 Testing

### Backend

```bash
npm run test
npm run test:e2e
```

### Mobile

```bash
flutter test
```

---

## 📊 Roadmap

### Phase 1 (MVP)

* SMS ingestion (Android)
* accounts + balances
* budgets
* goals
* assistant
* reconciliation

---

### Phase 2

* email integration
* smarter AI learning
* recurring detection
* improved insights

---

### Phase 3

* bank integrations
* receipt OCR
* shared budgets
* subscription intelligence

---

## 🤝 Contributing

Contributions are welcome.

* Fork repo
* Create feature branch
* Submit PR

---

## 📜 License

MIT License

---

## 💡 Philosophy

> The app should not pretend to be perfectly accurate.
>
> Instead, it should:
>
> * show confidence
> * ask questions
> * improve with the user
> * remove friction from financial awareness

---

## 🧾 Tagline

**Track nothing. Know everything.**

