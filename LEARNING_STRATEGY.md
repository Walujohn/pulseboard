# Pulseboard Deep Dive: Strategy for Enterprise Rails API Engineering

## Overview
This document outlines a systematic approach to understanding Pulseboard and preparing for enterprise Rails API development (monoliths + React, API-first architecture, TDD culture).

## Why This Matters for Enterprise (USCIS/Global Context)

At enterprise scale (USCIS, government systems), you'll encounter:
- **Complex Domain Models**: Immigration cases have multiple statuses, actors, workflows
- **API Contracts**: Mobile apps, third-party integrations, partner agencies consuming your API
- **Multi-Frontend Strategy**: Some teams use React, others use Hotwire; you need to support both paradigms
- **TDD as Non-Negotiable**: Government procurement often requires test coverage > 80%
- **API Versioning**: You can't break partners' integrations; `/api/v1/` exists for a reason
- **Audit Trails & Compliance**: Every action must be traceable
- **Performance at Scale**: Millions of immigration cases, not thousands of status updates

Pulseboard mirrors this with a smaller scope: status updates (like case records), comments (like notes/activity), reactions (like approvals).

---

## Learning Path: 4 Core Phases

### Phase 1: Understand the Domain (Today)
**Goal**: Know what the app does and why each piece exists.

**Topics**:
- Domain model (StatusUpdate, Comment, Reaction)
- Database schema and relationships
- Why certain design choices (e.g., reactions have uniqueness on emoji+user+update)
- Business logic vs. Rails framework code

**Time**: 1-2 hours

---

### Phase 2: Understand the Rails Architecture (Day 2)
**Goal**: Know how Rails moves data from database to users.

**Topics**:
- Routes and API versioning
- Controllers (web vs. API)
- Models and validations
- Serializers (how we shape JSON responses)
- Before/after actions and callbacks

**Time**: 3-4 hours (includes hands-on code reading)

---

### Phase 3: Understand Testing & TDD (Day 2-3)
**Goal**: Know how to write tests that prevent bugs and document behavior.

**Topics**:
- Unit tests (model specs)
- Integration tests (request specs, system tests)
- Test factories and fixtures
- TDD workflow: Red → Green → Refactor
- Why testing matters in enterprise (audit trail, regressions)

**Time**: 3-4 hours (includes writing new tests)

---

### Phase 4: Understand Frontend Architecture Choices (Day 3-4)
**Goal**: Know when to use React vs. Hotwire and why the choice matters.

**Topics**:
- React component pattern (ReactionPicker)
- Hotwire pattern (Stimulus + Turbo Rails)
- Trade-offs: bundle size, SEO, real-time updates, team skills
- When government projects choose one vs. the other
- API design for both audiences

**Time**: 2-3 hours

---

## Enterprise Context: What You'll See at USCIS/Global

### 1. **Domain Complexity**
- **Pulseboard**: "Status updates can be liked/reacted to"
- **USCIS**: "Immigration cases move through 20+ statuses, each with permissions, audit logs, SLA timers"
- **Your job**: Design APIs that express this without leaking implementation details

### 2. **API Design**
- **Pulseboard**: `/api/v1/status_updates/:id/reactions` (nested resources)
- **USCIS**: `/api/v1/cases/:id/status-transitions` (semantic naming), `/api/v1/cases/:id/audit-log` (compliance)
- **Your job**: Design APIs that are:
  - Backwards compatible (v1 stays stable forever)
  - Self-documenting (naming makes intent clear)
  - Auditable (who changed what, when)

### 3. **Frontend Strategy**
- **Pulseboard**: Shows both React AND Hotwire (you decide which is better)
- **USCIS Global**: Likely has legacy JSP/JSF, modern React, and Hotwire coexisting
- **Your job**: Recommend migrations, support multiple clients, document API clearly so frontend teams aren't blocked

### 4. **Testing Culture**
- **Pulseboard**: ~90% test coverage (17 RSpec + 16 Minitest = 33 tests for small feature)
- **USCIS**: ~95%+ required (government contracts mandate this)
- **Your job**: Write tests that document behavior, catch regressions, enable confident refactoring

### 5. **Team Collaboration**
- **Pulseboard**: One developer (you) builds feature end-to-end
- **USCIS**: 
  - Backend team (you) publishes API contract
  - Frontend team (React devs) consumes 2 weeks later
  - QA team tests both old paths and new paths
  - DevOps team deploys with backward compatibility
- **Your job**: Write APIs, tests, and docs so everyone can work independently

---

## How This Walkthrough Works

I'll show you:
1. **What each file does** (purpose)
2. **How it connects** (dependencies)
3. **Why this pattern** (Rails convention vs. business requirement)
4. **What could break** (common mistakes at scale)
5. **How tests catch this** (TDD perspective)

---

## Assumptions About Your Background

✅ You know:
- Rails basics (MVC, models, controllers, views)
- Database basics (relational, foreign keys)
- HTTP basics (GET, POST, JSON)

🔄 You're rusty on:
- TDD workflow and mindset
- API design patterns
- React/Hotwire differences
- How teams coordinate around APIs

❌ Not required:
- JavaScript mastery (we'll explain React/Stimulus at high level)
- Database optimization (we'll note where it matters)
- DevOps/deployment (we'll mention it, not deep-dive)

---

## Next Steps

**Phase 1 starts**: Let's look at the database schema and understand what data we're working with.

Run this to see the schema:
```bash
cat db/schema.rb
```

Then ask: "What is a StatusUpdate? What is a Comment? What is a Reaction? Why do they relate this way?"

I'll guide you from there.
