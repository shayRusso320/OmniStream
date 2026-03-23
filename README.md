# 🚨 Missile Alarm Intelligence System

A real-time intelligence aggregation system that monitors active missile alarms in Israel, collects relevant Telegram channel reports, and produces live AI-generated summaries of each threat event. The system also continuously monitors Telegram channels for early signs of incoming attacks — before any official alarm is issued.

---

## Purpose

When a missile alarm fires in Israel, thousands of Telegram messages flood news channels, military reporters, and local community groups within seconds. Some contain firsthand eyewitness reports of interceptions or impacts. Others are noise. Most people have no way to quickly make sense of what is actually happening and where.

This system automates that process. It listens for official alarms, finds the relevant Telegram reports, filters out the noise, and builds a continuously updated plain-language summary of the situation — from the first incoming message until the alarm window closes.

A secondary feature monitors Telegram continuously for signs of an imminent attack before any official alarm fires, providing potential early warning intelligence.

---

## What It Does

- **Detects official missile alarms** in real time via the tzevaadom API
- **Aggregates Telegram messages** from monitored news channels and military reporters
- **Filters messages** using semantic similarity and LLM classification to keep only genuinely relevant reports
- **Matches messages to active threats** using vector similarity search on geographic location concepts
- **Generates live summaries** that update incrementally as new relevant messages arrive
- **Detects pre-alarm threats** from Telegram activity before any official alarm is issued
- **Stores all events** for historical browsing — alarms, threats, contributing messages, and summaries

---

## Architecture Overview

The system is split across two environments: a lightweight **local agent** running on a personal computer in Israel, and a fully **event-driven AWS cloud pipeline**.

```
┌─────────────────────────────────────────────────────────────────┐
│  YOUR COMPUTER  (Israeli IP required)                           │
│                                                                 │
│  Local Agent                                                    │
│  ├── Polls tzevaadom API every 2–3 seconds                      │
│  ├── Deduplicates via SQLite                                    │
│  └── POSTs new alarms to AWS API Gateway                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS POST
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS CLOUD                                                      │
│                                                                 │
│  API Gateway ──► SQS: alarm_events ──► Pipeline Processor λ    │
│                                              │                  │
│                                    ┌─────────┴──────────┐      │
│                                    │  Create Threat      │      │
│                                    │  Create Alarm       │      │
│                                    │  Upsert → Qdrant    │      │
│                                    │  Write → Redis TTL  │      │
│                                    └────────────────────-┘      │
│                                                                 │
│  ECS Fargate (always on) ──────────────────────────────────-   │
│  Telethon fetches Telegram 24/7                                 │
│  └──► SQS: raw_messages ──► Filter λ (capped concurrency)      │
│                                    │                            │
│                          Gate 2: Content similarity             │
│                          (OpenAI embeddings, 3 concepts)        │
│                                    │                            │
│                          Gate 3: Location match                 │
│                          (Qdrant vector search)                 │
│                                    │                            │
│                    ┌───────────────┴────────────────┐          │
│                    │ Match found   │  No match       │          │
│                    │               │                 │          │
│              Attach to         LLM eval             │          │
│            existing threat    (GPT-4o)              │          │
│                    │          confident?             │          │
│                    │          ├── no  → discard      │          │
│                    │          └── yes → new threat   │          │
│                    │                                 │          │
│                    └──────────┬──────────────────────┘          │
│                               │                                 │
│                        Write survivor → RDS                     │
│                               │                                 │
│                        Summarizer λ (async)                     │
│                        ├── Acquire Redis lock                   │
│                        ├── Read all survivors from RDS          │
│                        ├── GPT-4o regenerates summary           │
│                        └── Write → Redis cache                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## The Two Flows

### Flow 1 — Alarm Intelligence

Triggered when an official alarm fires. Creates a high-confidence threat record with exact city locations and processes incoming Telegram messages to build a live summary of what is happening — interceptions, impacts, damage reports.

```
Official alarm → Create threat (confirmed cities) → Attach relevant messages → Live summary
```

### Flow 2 — Early Warning

Runs continuously regardless of alarm state. Detects clusters of Telegram messages describing imminent attacks before any official alarm fires. Creates lower-confidence threat records from extracted location intelligence.

```
Telegram message → Content filter → No active threat match → LLM confidence check → New threat
```

Both flows share the same ingestion infrastructure, the same embedding model, and the same summarization process. They diverge only in how threats are created and closed.

---

## Filtering Pipeline

Every Telegram message passes through two gates before being attached to a threat.

### Gate 2 — Content Relevance
The message is embedded once using the OpenAI text-embedding API. Its vector is compared against three concept vectors using cosine similarity. The message must score above threshold on at least one concept to proceed.

| Concept | String |
|---|---|
| Launch | `missile rocket launched fired incoming attack imminent warning` |
| Outcome | `interception iron dome hit impact explosion damage confirmed` |
| Alert | `alert siren threat detected aerial defense` |

**Threshold:** 0.5 on any concept. Below on all three → discard.

### Gate 3 — Location Matching
The same message vector (no extra embedding call) is sent to Qdrant, which searches against all active threat location vectors. Each threat has a location concept vector built from its confirmed cities or LLM-extracted locations plus regional aliases and Napa region data.

**Threshold:** 0.6 similarity to match an existing threat. No match → LLM evaluation for potential new threat creation.

---

## Live Summarization

After each message is attached to a threat as a survivor, the Summarizer Lambda is invoked asynchronously. It:

1. Tries to acquire a Redis distributed lock for that threat
2. If locked — exits immediately (the current lock holder will cover it)
3. If acquired — reads **all** survivors for the threat from RDS and regenerates the full summary from scratch using GPT-4o
4. Writes the updated summary to Redis for fast website reads
5. Releases the lock

Summaries are eventually consistent and grow richer with each new relevant message.

---

## Geographic Resolution

News messages rarely mention exact city names. They use regional nicknames like "Gush Dan", "the envelope", or "the south". The system resolves these using two layers:

1. **Area nickname dictionary** — manually maintained mapping of Hebrew and English area names to Napa IDs (Israel's administrative region codes)
2. **Government Cities API** — maps Napa IDs to their constituent cities dynamically

This means the dictionary only needs to map names to region codes. Actual city membership stays up to date automatically via the government API.

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Alarm detection | Python + tzevaadom API | Polls for active alarms every 2–3 seconds |
| Local persistence | SQLite | Deduplication and retry queue on local agent |
| Message ingestion | Telethon (Python) | Reads public Telegram channels |
| Compute — fetcher | ECS Fargate | Always-on persistent Telegram session |
| Session storage | AWS EFS | Telethon session file — survives container restarts |
| Message queue | AWS SQS | Decoupled async message delivery |
| Alarm entry | AWS API Gateway | Receives alarm POSTs, native SQS integration |
| Coordination | AWS Lambda | Alarm processing, filtering, summarization |
| Embeddings | OpenAI text-embedding-3-small | Message and concept vectorization |
| LLM | GPT-4o | Threat evaluation and summary generation |
| Vector search | Qdrant Cloud | Threat location vector storage and similarity search |
| Cache + locks | Redis (AWS ElastiCache) | Active threat registry, summary cache, distributed locks |
| Database | RDS PostgreSQL | All persistent relational data |
| Infrastructure | Terraform | All AWS resources statically defined |

---

## Data Model

Three tables in PostgreSQL.

**threats** — the central object. Every piece of intelligence anchors here.
- Alarm-origin threats: confirmed cities, confidence = 1.0, 15-minute window
- News-origin threats: LLM-extracted locations, confidence score, 10-minute window

**alarms** — raw official alarm data from the tzevaadom API. Points to its threat via `threat_id`.

**survivors** — Telegram messages that passed all gates. The source of truth for summary generation. Each survivor is linked to a threat.

---

## Local Agent

The local agent runs on a personal computer in Israel — required because the tzevaadom API is geo-restricted to Israeli IP addresses.

It is intentionally minimal. Its only job is to detect new alarms and forward them to the cloud. All intelligence processing happens in AWS.

- Runs as an OS background service (systemd / launchd / Windows Service)
- Deduplicates using a local SQLite database that persists across reboots
- Retries failed forwards with exponential backoff via a pending queue in SQLite
- Filters to threat type 1 (rockets / missiles) before forwarding

---

## Project Status

This project is currently in the **design and validation phase**. The architecture has been fully designed. Implementation has not yet started.

The next steps before building are:
- Validate cosine similarity thresholds using real Hebrew and Arabic Telegram messages
- Finalize the Telegram channel list to monitor
- Build the area nickname → Napa ID dictionary
- Design the website output layer

---

## Study Goals

This project was designed as a study exercise to explore:

- Event-driven cloud architecture on AWS
- Real-time data pipelines with SQS, Lambda, and ECS
- Semantic similarity and embedding-based filtering
- Vector database usage with Qdrant
- LLM integration for classification and summarization
- Infrastructure as code with Terraform
- Distributed system patterns — idempotency, distributed locks, eventual consistency
