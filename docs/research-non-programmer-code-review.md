# Research: AI Code Review for Non-Programmers

Research compiled 2026-03-23. This document captures findings on how non-programmers interact with AI-generated code, the risks they face, and how review agents and structured workflows mitigate (or fail to mitigate) those risks.

For the practical guide, see the main [CLAUDE.md](../CLAUDE.md).

---

## Table of Contents

1. [Core Dynamics](#1-core-dynamics)
2. [Failure Modes](#2-failure-modes)
3. [The Circular Validation Problem](#3-the-circular-validation-problem)
4. [Language Choice](#4-language-choice)
5. [The Superpowers Plugin](#5-the-superpowers-plugin)
6. [Contractor & Vendor Review](#6-contractor--vendor-review)
7. [Automated Guardrails](#7-automated-guardrails)
8. [Effective Workflows](#8-effective-workflows)
9. [Gaps & Proposed Agents](#9-gaps--proposed-agents)
10. [Key Takeaways](#10-key-takeaways)

---

## 1. Core Dynamics

Three dynamics are unique to non-programmers building with AI:

### Language agnosticism as advantage

A programmer picks Python because they know Python. A non-programmer has no such bias. If Rust is better for the job, the switching cost is the same (zero familiarity with all languages). This means non-programmers can make the *right* language choice up front — but need agents to validate that AI writes idiomatic, correct code in whatever was chosen.

### Refactoring introduces double-debugging risk

When AI refactors code for a non-programmer (e.g., Python to Go), it introduces new bugs on top of whatever existed before. The non-programmer can't catch either set. The correct strategy is to get it right the first time rather than plan to refactor later.

### AI-generated code rots invisibly

AI produces code that works but is poorly structured — inconsistent naming, duplicated logic, tangled dependencies, functions doing too many things. A programmer spots this and cleans it up. A non-programmer can't see it accumulating. Over months, the codebase becomes unmaintainable.

**Implication:** Code quality auditing is MORE important for non-programmers, not less. The auditors aren't optional polish — they're the only way to know if things are going off the rails.

---

## 2. Failure Modes

### "Works on demo, breaks on reality"

AI-generated code handles the happy path beautifully but fails on edge cases, error handling, and real-world data. Non-programmers evaluate by visible behavior ("it runs"), not structural soundness ("it's correct").

Documented examples:
- Booking systems without transactional integrity (double-bookings possible)
- Form handlers trivially vulnerable to SQL injection
- Financial calculations using floating-point instead of decimal
- APIs returning full database records including other users' PII

### Technical debt acceleration ("AI slop")

AI-generated codebases grow 3-5x larger than human-written equivalents. Rather than creating abstractions, LLMs generate similar-but-slightly-different code blocks. Each prompt generates code in a slightly different style. Over weeks, the codebase becomes a patchwork of contradictory patterns.

One startup post-mortem described inheriting a "vibe-coded" codebase: 47 separate API route files, each with its own error handling approach, no shared middleware. The rewrite took longer than building from scratch.

### The lock-in trap

The non-programmer builds a working system with AI. Then:
- A dependency has a breaking change
- A bug requires understanding interactions between 3+ modules
- The hosting provider changes pricing
- The AI model's behavior changes between versions

Without understanding the code, you end up in **prompt loops** — asking AI to fix a bug, the fix breaks something else, which reintroduces the original bug.

**The fundamental asymmetry:** AI dramatically reduces creation cost but doesn't proportionally reduce the cost of understanding, debugging, evolving, securing, scaling, or maintaining the code.

### Security as an afterthought

Non-programmers don't know to ask about security. AI generates functionally correct code that is insecure by default unless specifically prompted.

Stanford research (Perry et al., 2023) found that developers using AI assistants produced significantly more security vulnerabilities while being *more confident* their code was secure. The code looked more professional, creating false confidence.

Common AI-generated security mistakes:
- Placeholder API keys that get replaced with real ones and committed
- `eval()`, `pickle.loads()`, unsafe YAML loaders
- String concatenation instead of parameterized queries
- Auth flows that work but store tokens insecurely
- Password reset links containing the actual password

### The Dunning-Kruger amplifier

AI tools give non-programmers the ability to produce working software, which creates confidence disconnected from actual understanding. "Vibe coding" (Karpathy, 2025) explicitly celebrates not understanding the code. The person who can't build something will hire someone who can. The person who thinks they've already built it won't.

### Tests that test nothing

AI generates comprehensive-looking test suites with high line coverage but low mutation testing scores. The tests exercise code paths but don't assert meaningful behavior. When mutation testing tools run against AI-generated tests, 40-60% of mutations survive — meaning those bugs would go undetected.

---

## 3. The Circular Validation Problem

When AI writes code and AI reviews it, they share blind spots.

### Key findings

- **Same-model review is rubber-stamping.** LLMs approve their own output at ~70-80% rates even when buggy. Reframing the same code as "written by a junior developer" raises detection to 45-55%.
- **Cross-model review helps but doesn't solve it.** Different models catch 15-30% more issues than same-model review, but still converge on similar patterns.
- **Blind spots are correlated.** AI doesn't miss random bugs — it systematically misses the same categories it systematically generates: state management, race conditions, off-by-one errors, boundary conditions.
- **Self-repair is overstated.** Stanford/UC Berkeley research (Olausson et al., 2023) found that without external feedback (test failures, error messages), LLM self-repair rarely succeeds.

### What AI review catches well (pattern level)

- Null/undefined reference potential
- Type mismatches (in typed languages)
- Common API misuse patterns
- SQL injection via obvious string concatenation
- Missing error handling on promises/futures
- Unused variables and imports

### What AI review catches poorly (design level)

- Coupling violations and abstraction leaks
- Scalability cliffs (O(n^2) hidden in innocent-looking code)
- Distributed systems failures (split-brain, consensus, idempotency)
- Domain logic errors (wrong business calculations)
- Missing functionality (what *should* be there but isn't)
- Cross-cutting concerns (observability, debuggability)

### What works

**Multi-model review:** Using different AI models for generation vs. review catches 15-30% more issues. Models from different providers have partially different blind spots.

**Adversarial prompting:** "Find the bugs in this code" dramatically outperforms "review this code." Specific attack scenarios outperform generic review. Role-separated adversarial setups outperform single-instance review.

**Formal tools as complement:** Type systems, property-based testing, mutation testing, and SAST tools catch entire categories that AI review misses — and they do it deterministically.

**The layered strategy:**
1. Automated static analysis (linters, type checkers, SAST) — deterministic
2. AI review with adversarial prompting, multiple models — probabilistic
3. Human review for architecture, domain logic, risk — contextual
4. Runtime verification (integration tests, load tests, chaos engineering) — behavioral

---

## 4. Language Choice

Since non-programmers are equally unfamiliar with all languages, the choice should optimize for safety, not ease.

### AI code generation quality by language

| Language | Training data volume | AI generation quality | Compile-time error catching | "Silently wrong" risk |
|----------|---------------------|----------------------|---------------------------|----------------------|
| Python | Largest | Best (80-90%+ HumanEval) | Almost nothing | Highest |
| TypeScript | Large | Very good | Many (strict mode) | Low-moderate |
| Go | Medium | Good | Some | Moderate |
| Rust | Smallest | Weakest (often doesn't compile) | Most | Lowest |

### Key insight: inverse relationship

There's an inverse relationship between initial generation ease and downstream correctness. Python is easiest to generate, hardest to verify. Rust is hardest to generate, easiest to verify (the compiler does it).

### AI Rust code is bimodal

AI Rust code has a bimodal quality distribution. It either doesn't compile (and you know immediately) or it works well. AI Python code has a normal distribution — most of it runs, but correctness varies on a spectrum that's hard to evaluate without expertise.

### The compiler as reviewer

For a non-programmer, compile-time errors are dramatically better than runtime errors:
1. They appear immediately, not after deployment
2. They have a specific location and often a suggested fix
3. They can be fed back to the AI for automatic correction
4. They don't corrupt data or cause partial failures

### What each type system catches

| Bug Category | Python | TypeScript (strict) | Go | Rust |
|---|---|---|---|---|
| Wrong argument type | Runtime (maybe) | Compile time | Compile time | Compile time |
| Null/None access | Runtime crash | Compile time | Runtime (nil) | Compile time (Option) |
| Missing error handling | Silent | Depends | Compile time | Compile time (Result) |
| Data race | Silent corruption | N/A (single-threaded) | Runtime | Compile time (Send/Sync) |
| Exhaustive matching | N/A | Compile time | N/A | Compile time |

### Practical recommendation

- **TypeScript with strict mode** for web projects — 80% of Rust's safety with 90% of Python's generation quality
- **Rust** for anything where correctness matters more than development speed
- **Go** for CLIs, services, anything needing simple deployment (single binary)
- **Python** only for throwaway scripts and prototypes

### Caution: AI can defeat type safety

AI-generated TypeScript frequently uses `any` types everywhere, disabling the type system. AI-generated Rust overuses `.unwrap()` and `unsafe` blocks. A non-programmer wouldn't know to reject these patterns. Code-auditor should flag them.

---

## 5. The Superpowers Plugin

The superpowers plugin (v5.0.5) provides 15 skills that form a structured development workflow. Here's how it maps to non-programmer risks.

### What it provides

**The full pipeline:**
1. **Brainstorming** — Explore intent, propose approaches, write design spec
2. **Writing plans** — Break spec into bite-sized tasks with exact file paths and commands
3. **Using git worktrees** — Isolate feature work from main branch
4. **Subagent-driven development** — Fresh subagent per task, two-stage review
5. **Test-driven development** — No production code without a failing test first
6. **Systematic debugging** — Root cause investigation before fixes
7. **Verification before completion** — No claims without evidence
8. **Requesting/receiving code review** — Structured review with push-back protocol
9. **Finishing a development branch** — Clean merge/PR/discard options

**Decision documentation:**
- Specs → `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Plans → `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

### What it mitigates

**Invisible code rot — strongly mitigated.** Two-stage review (spec compliance THEN code quality) with separate subagents is exactly what's needed. Each reviewer gets a clean context window with different goals. TDD builds a regression safety net over time.

**"Works but wrong" — partially mitigated.** The brainstorming → spec → plan pipeline forces design decisions before code is written. Specs capture the *why* behind decisions. Verification-before-completion prevents "it should work now" claims.

**The lock-in trap — partially mitigated.** Plans document every decision with exact file paths and commands. This is a massive improvement over "each AI session generates different approaches." Git worktrees prevent half-finished changes from corrupting main.

**Circular validation — meaningfully addressed.** Fresh subagents for each review step don't share context from generation. The implementer, spec-reviewer, and code-quality-reviewer each get clean windows with different prompts. This is better than same-context review.

**Refactoring risk — strongly mitigated.** Brainstorming forces language and architecture choices BEFORE code is written. Three gates (spec review → plan review → implementation review) before code is committed.

### What it doesn't mitigate

**Complexity overhead.** The full pipeline is 9+ steps per feature. For a non-programmer building something simple, this may be overkill. The risk is cargo cult discipline — blindly following ritual without understanding what each gate checks.

**Plans document AI decisions, not human understanding.** A non-programmer may approve a spec they don't fully understand because it "looks thorough." The plan then faithfully implements a misunderstood design.

**TDD assumes meaningful tests.** "Write a failing test first" requires someone to evaluate whether the test is meaningful. AI-generated tests that test the wrong thing create false confidence.

**No business-impact translation.** Superpowers speaks entirely in technical language. No skill connects findings to user/revenue impact or translates for non-technical stakeholders.

**No integration with review agents.** The 24 review agents and the superpowers pipeline are completely separate systems. There's no point in the superpowers workflow where the 11 auditors run automatically. They could complement each other — auditors as an additional gate in plan execution — but right now they're disconnected.

### New risks it introduces

**Over-reliance on process as substitute for understanding.** The superpowers pipeline gives a non-programmer the *feeling* of rigor without necessarily the *substance*. Each gate passes, but the person approving the gates can't evaluate the work.

**Spec approval without comprehension.** The brainstorming skill produces detailed specs. A non-programmer reads it, it looks professional and thorough, they approve it. But they may not understand the tradeoffs being made — e.g., choosing eventual consistency over strong consistency for a financial application.

**Subagent cost accumulation.** Each task dispatches an implementer + spec-reviewer + code-quality-reviewer. For a 20-task plan, that's 60+ subagent invocations. The API cost adds up, and each subagent only sees its narrow slice.

### The opportunity: connecting the two systems

The biggest opportunity is integrating review agents into the superpowers pipeline:

- **After brainstorming/spec phase:** Run code-auditor on existing code to understand current quality before planning changes
- **After each task:** Run security-auditor and bug-auditor as additional gates alongside spec-reviewer and code-quality-reviewer
- **Before finishing a branch:** Run all 11 auditors as a final gate before merge/PR
- **Weekly:** Run full audit and compare to previous week, storing results alongside plans for trend tracking

Plans (`docs/superpowers/plans/`) document the "why" behind decisions. Audits (`.claude/audits/`) capture the "what's wrong" at a point in time. Together they give a non-programmer both rationale and health status.

---

## 6. Contractor & Vendor Review

### The core workflow

```
Step 1: Plain-English overview
   "Explain this codebase like I'm a business owner."

Step 2: Scope verification
   "Compare to my SOW. What's done, missing, or stubbed out?"

Step 3: Full parallel audit
   All 11 auditors + fix-planner

Step 4: Red flag detection
   Hardcoded passwords, placeholder data, empty functions,
   meaningless tests, machine-specific configuration

Step 5: Maintainability assessment ("bus factor")
   "If this contractor disappeared, how hard is the handoff?"
```

### Red flags AI can catch

- Functions that exist but only return placeholder data
- API endpoints that don't connect to real databases
- Test files with no meaningful assertions
- Code that depends on the contractor's personal infrastructure
- Dependencies with copyleft licenses (GPL/AGPL) in commercial projects
- Copy-pasted code with inconsistent styles (Stack Overflow or AI without understanding)

### Contract quality gates

Require deliverables to pass before acceptance:
- Test coverage >= 70% for business logic
- No critical/high security vulnerabilities
- Code maintainability rating B+ or above
- Zero hardcoded secrets
- README that lets a new developer set up in 30 minutes
- AI audit with no High/Critical findings

### Gaming tactics contractors use

| Tactic | Detection |
|--------|-----------|
| Fake test coverage (tests don't assert anything) | Mutation testing; ask AI "which tests would catch real bugs?" |
| Feature stuffing (easy features to pad hours) | Compare effort per feature against SOW |
| Dependency bloat (libraries for trivial tasks) | Ask "could we do this without this dependency?" |
| Copy-paste without understanding | Look for inconsistent styles within same file |
| "Only works on my machine" delivery | Check for absolute paths, contractor-hosted services, missing docs |
| Vendor lock-in (deliberately hard to maintain without them) | "Bus factor" assessment |

---

## 7. Automated Guardrails

Tools a non-programmer can set up once and benefit from automatically. They produce green/red signals without requiring code understanding.

### Priority order

| Priority | Tool | What it catches | Effort to set up |
|----------|------|----------------|-----------------|
| 1 | Branch protection on `main` | Prevents merging without passing checks | 5 minutes |
| 2 | Linting in CI (ruff, eslint) | Formatting, unused code, common mistakes | 30 minutes |
| 3 | Type checking (mypy strict, tsc strict) | Subtly wrong code that would fail at runtime | 30 minutes |
| 4 | Security scanning (Semgrep, CodeQL) | Vulnerability patterns on every PR | 30 minutes |
| 5 | Dependency auditing (Dependabot) | Known vulnerabilities in libraries | 10 minutes |
| 6 | Secret detection (detect-secrets) | API keys, passwords in committed code | 15 minutes |
| 7 | Test coverage threshold | Fails CI if coverage drops below minimum | 15 minutes |

### The key insight

You don't need to understand the code. You need to understand the traffic light. Green check = safe to merge. Red X = don't merge until it's fixed.

### What each tool catches that AI misses

| AI Mistake | Caught By |
|-----------|-----------|
| Hardcoded secrets | detect-secrets, Semgrep |
| SQL injection | Bandit, Semgrep, CodeQL |
| Vulnerable dependencies | pip-audit, Dependabot |
| Type mismatches | mypy strict, TypeScript compiler |
| Tests that test nothing | Mutation testing (mutmut, Stryker) |
| Insecure deserialization | Bandit, Semgrep |
| Hallucinated imports | pip install fails in CI |
| Performance regressions | pytest-benchmark + threshold alerts |

---

## 8. Effective Workflows

### The Describe-Build-Review Loop

Core cycle: describe outcomes → AI builds → review visually → AI reviews structurally → commit → repeat.

Key rules:
- Describe WHAT, never HOW
- One feature per prompt
- Commit after every working increment (save points)
- Run auditors on what you can't see

### Parallel Audit with Subagents

Spawn 5-11 auditors simultaneously, each in its own context window. Get a comprehensive picture in roughly the time of a single audit.

### Adversarial Review Framing

"Find the bugs" dramatically outperforms "review this code." Specific attack scenarios outperform generic review. Role-separated adversarial setups outperform single-instance review.

Example:
```
You are a skeptical senior engineer. Your job is to find problems.
For each change: What could go wrong in production? What edge cases
aren't handled? What breaks under load? What security assumptions
might be wrong? Be harsh.
```

### Superpowers + Review Agents Combined Pipeline

```
1. Brainstorming → spec (docs/superpowers/specs/)
2. Writing plans → plan (docs/superpowers/plans/)
3. Create worktree
4. For each task:
   a. Subagent implements (TDD: test first, then code)
   b. Spec-reviewer checks compliance
   c. Code-quality-reviewer checks quality
   d. Run security-auditor + bug-auditor as additional gates
5. Run full 11-auditor suite before finishing branch
6. Finish branch (merge, PR, or discard)
```

This combines superpowers' structured discipline with the review agents' specialized expertise.

---

## 9. Gaps & Proposed Agents

### Business Impact Translator

Takes audit findings and translates into business language. "SQL injection in user search endpoint" → "An attacker could access customer payment information. This is a PCI-DSS violation that could result in fines."

### Health Dashboard

Single-page red/yellow/green status across all audit areas. One-page overview instead of 11 detailed reports.

### Stakeholder Report Generator

Converts FIXES.md into executive summaries with cost/timeline. Bridges non-technical stakeholders and developers.

### Compliance Mapper

Maps findings to regulatory frameworks (SOC 2, GDPR, PCI-DSS). Connects technical findings to business deadlines.

### Audit Trend Tracker

Compares weekly audits to show improvement over time. "Security issues dropped from 12 to 3 this month."

### Spec Comprehension Checker

Before a non-programmer approves a spec, asks them targeted questions to verify they understand the key tradeoffs. "This spec uses eventual consistency for financial data. That means two users might briefly see different account balances. Is that acceptable?"

### Integration Gate Agent

Sits between superpowers' plan execution and the review agents. Automatically runs the appropriate auditors after each plan task completes. No manual invocation needed.

---

## 10. Key Takeaways

1. **Non-programmers need review agents MORE, not less.** They're the only eyes on code quality when you can't evaluate it yourself.

2. **No single review layer is sufficient.** AI auditors + deterministic tools + human review for consequential decisions + runtime testing. The value is in the combination.

3. **The circular validation problem is real but manageable.** Cross-model review, adversarial prompting, fresh subagent contexts, and deterministic tools all reduce it.

4. **Language choice is a safety decision.** TypeScript strict mode or Rust catch AI mistakes at compile time. Python lets them through silently.

5. **Superpowers provides excellent process discipline** but speaks technical language only. The gap is business-impact translation and integration with the review agents.

6. **Plans and specs are the non-programmer's insurance policy.** They document decisions so you can trace back to why something was built a certain way, even across AI sessions.

7. **Get it right the first time.** Refactoring AI-generated code is double-debugging. Use brainstorming → spec → plan to make good choices up front.

8. **The trend matters more than any single audit.** Weekly audits tracked over time reveal whether things are improving or degrading.

9. **For contractor work: trust but verify.** Run audits, check scope compliance, assess bus factor. Structure contracts with AI-audited quality gates.

10. **The most dangerous outcome isn't code that doesn't work. It's code that works just well enough, for just long enough, to create real dependencies before structural problems manifest.**
