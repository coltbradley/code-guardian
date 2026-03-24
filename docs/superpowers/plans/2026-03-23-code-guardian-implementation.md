# Code Guardian Plugin — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform this repo from the existing "claude-code-agents" plugin (24 agents, programmer-focused, Next.js-specific) into "code-guardian" (12 agents, non-programmer-focused, code-agnostic).

**Architecture:** 9 auditor agents + 3 action agents + 8 skills (subdirectory format) + hook scripts + plugin packaging. All agents use a layered output format (executive summary → plain English → technical detail). All are code-agnostic with language auto-detection.

**Tech Stack:** Claude Code plugin format (markdown agents/skills with YAML frontmatter, JSON hooks, shell scripts)

**Design doc:** `docs/superpowers/plans/2026-03-23-code-guardian-plugin-design.md`

---

## Task Groups

Tasks are organized into groups. Tasks within a group are independent and can be parallelized. Groups must be completed in order.

- **Group 1:** Scaffolding (plugin manifest, directory structure, cleanup)
- **Group 2:** Core auditor agents (9 agents, all independent)
- **Group 3:** Action agents (3 agents, all independent)
- **Group 4:** Skills (8 skills, all independent)
- **Group 5:** Hooks (scripts + hooks.json)
- **Group 6:** Documentation & packaging (CLAUDE.md, README, LICENSE, CHANGELOG, package.json)
- **Group 7:** Validation (load test, verify all skills/agents discoverable)

---

## Group 1: Scaffolding

### Task 1.1: Clean up old agent files

**Files:**
- Delete: `agents/api-tester.md`
- Delete: `agents/architect-reviewer.md`
- Delete: `agents/browser-qa-agent.md`
- Delete: `agents/code-auditor.md`
- Delete: `agents/console-monitor.md`
- Delete: `agents/db-auditor.md`
- Delete: `agents/dep-auditor.md`
- Delete: `agents/deploy-checker.md`
- Delete: `agents/doc-auditor.md`
- Delete: `agents/env-validator.md`
- Delete: `agents/fullstack-qa-orchestrator.md`
- Delete: `agents/infra-auditor.md`
- Delete: `agents/perf-auditor.md`
- Delete: `agents/pr-writer.md`
- Delete: `agents/seed-generator.md`
- Delete: `agents/seo-auditor.md`
- Delete: `agents/test-writer.md`
- Delete: `agents/ui-auditor.md`
- Delete: `agents/visual-diff.md`
- Keep (will be rewritten): `agents/security-auditor.md`, `agents/bug-auditor.md`, `agents/code-fixer.md`, `agents/fix-planner.md`, `agents/test-runner.md`

**Step 1:** Delete the 19 agent files that are being dropped or replaced by renamed versions.

```bash
cd /Users/coltbradley/Documents/code/claude-code-agents-review
rm agents/api-tester.md agents/architect-reviewer.md agents/browser-qa-agent.md
rm agents/code-auditor.md agents/console-monitor.md agents/db-auditor.md
rm agents/dep-auditor.md agents/deploy-checker.md agents/doc-auditor.md
rm agents/env-validator.md agents/fullstack-qa-orchestrator.md agents/infra-auditor.md
rm agents/perf-auditor.md agents/pr-writer.md agents/seed-generator.md
rm agents/seo-auditor.md agents/test-writer.md agents/ui-auditor.md agents/visual-diff.md
```

**Step 2:** Commit.

```bash
git add -A && git commit -m "Remove old agents being replaced by code-guardian rewrites"
```

### Task 1.2: Clean up old skill and workflow files

**Files:**
- Delete: `skills/bug-fix.md`, `skills/full-audit.md`, `skills/new-feature.md`, `skills/pre-commit.md`, `skills/pre-deploy.md`, `skills/release-prep.md`
- Delete: entire `workflows/` directory
- Delete: `bin/` directory (will be replaced by new packaging)
- Delete: `install.sh`, `uninstall.sh`, `setup-project.sh`
- Delete: `CLAUDE.md.template`
- Delete: `CONTRIBUTING.md` (will rewrite)
- Delete: `assets/`, `badges/`

**Step 1:** Delete old files.

```bash
rm -r skills/ workflows/ bin/
rm install.sh uninstall.sh setup-project.sh CLAUDE.md.template CONTRIBUTING.md
rm -r assets/ badges/
```

**Step 2:** Create new directory structure.

```bash
mkdir -p skills/audit skills/quick-check skills/review-code skills/pre-deploy
mkdir -p skills/explain skills/health-report skills/compare skills/language-advisor
mkdir -p hooks/scripts
```

**Step 3:** Commit.

```bash
git add -A && git commit -m "Remove old skills/workflows/scripts, create code-guardian directory structure"
```

### Task 1.3: Update plugin manifest

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Delete: `.claude-plugin/marketplace.json` (will recreate in Group 6)

**Step 1:** Replace `.claude-plugin/plugin.json` with:

```json
{
  "name": "code-guardian",
  "version": "1.0.0",
  "description": "Code-agnostic guardrails for non-programmers building with AI tools. 9 specialist auditors + 8 workflow skills that report in plain English.",
  "author": {
    "name": "Colt Bradley",
    "url": "https://github.com/coltbradley"
  },
  "license": "MIT",
  "repository": "https://github.com/coltbradley/code-guardian",
  "keywords": ["audit", "code-review", "non-programmer", "vibe-coding", "guardrails", "security"],
  "agents": "agents/",
  "skills": "skills/",
  "hooks": "hooks/hooks.json",
  "minClaudeCodeVersion": "1.0.0"
}
```

**Step 2:** Delete marketplace.json (recreated later).

```bash
rm .claude-plugin/marketplace.json
```

**Step 3:** Commit.

```bash
git add -A && git commit -m "Update plugin manifest for code-guardian"
```

---

## Group 2: Core Auditor Agents (9 agents — all independent, can be parallelized)

Every auditor follows the universal template from the design doc. Key requirements:
- Code-agnostic: detect project language, adapt checks, skip gracefully
- Layered output: executive summary → plain-English findings → technical detail
- Non-overlapping scope: explicit delegation to other agents
- Adversarial framing: find problems, don't approve code
- Audience: non-programmers who build with AI tools

### Task 2.1: Write security-auditor agent

**Files:**
- Rewrite: `agents/security-auditor.md`
- Output: `.claude/audits/AUDIT_SECURITY.md`

**Step 1:** Rewrite `agents/security-auditor.md` with the code-guardian template. Must include:

- Frontmatter: `name: security-auditor`, `description: Finds security vulnerabilities — secrets in code, injection attacks, authentication gaps, data exposure. Runs on any language.`, `tools: Read, Grep, Glob, Bash`, `model: inherit`
- Audience section (non-programmers)
- Language-agnostic detection: detect language from file extensions, dependency files, then adapt grep patterns
- Status block format with `critical`, `important`, `minor` counts
- Layered output format
- Scope: ALL security (injection, auth, secrets, headers, CSRF, rate limiting, crypto, data exposure)
- Not in scope: runtime bugs (bug-auditor), code quality (code-quality-auditor)
- Checks organized by category, each with multi-language grep patterns:
  - Secrets detection (API keys, passwords, tokens — patterns for Python, JS/TS, Go, Rust, Ruby, Java, PHP, .env files)
  - Injection attacks (SQL, NoSQL, command, XSS — patterns per language)
  - Authentication & session management
  - Authorization & access control
  - Security headers & configuration
  - CSRF protection
  - Data exposure risks
  - Cryptographic issues
- Each check: what to look for, multi-language grep patterns, how to assess severity
- Graceful skip: never skips (security applies to everything)

**Step 2:** Commit.

```bash
git add agents/security-auditor.md && git commit -m "Rewrite security-auditor: code-agnostic, layered output, non-programmer audience"
```

### Task 2.2: Write bug-auditor agent

**Files:**
- Rewrite: `agents/bug-auditor.md`
- Output: `.claude/audits/AUDIT_BUGS.md`

**Step 1:** Rewrite `agents/bug-auditor.md`. Must include:

- Frontmatter: `name: bug-auditor`, `description: Finds runtime bugs — crashes, null references, race conditions, error handling gaps, logic errors. Runs on any language.`
- Code-agnostic checks:
  - Error handling gaps (empty catch blocks, swallowed errors, unhandled exceptions — per language)
  - Null/undefined safety (null derefs, missing guards — per language)
  - Race conditions (TOCTOU, concurrent state, shared mutable state)
  - Resource leaks (files, connections, memory — per language)
  - Logic errors (off-by-one, boundary conditions, type coercion)
  - Async/concurrency issues (unhandled promises, deadlocks, goroutine leaks, etc.)
- Not in scope: security (security-auditor), code quality (code-quality-auditor)
- Graceful skip: never skips

**Step 2:** Commit.

```bash
git add agents/bug-auditor.md && git commit -m "Rewrite bug-auditor: code-agnostic, layered output, non-programmer audience"
```

### Task 2.3: Write code-quality-auditor agent

**Files:**
- Create: `agents/code-quality-auditor.md`
- Output: `.claude/audits/AUDIT_CODE_QUALITY.md`

**Step 1:** Write `agents/code-quality-auditor.md`. Must include:

- Frontmatter: `name: code-quality-auditor`, `description: Finds code quality problems — duplication, complexity, naming inconsistency, dead code, structural mess. Runs on any language.`
- Code-agnostic checks:
  - Duplication (similar code blocks, copy-paste patterns)
  - Complexity (deeply nested logic, overly long functions/files)
  - Naming consistency (mixed conventions, unclear names)
  - Dead code (unused functions, unreachable branches, commented-out code)
  - Structural issues (circular dependencies, god objects, missing abstractions)
  - AI-specific code smells (inconsistent patterns across files suggesting different AI sessions, overuse of `any`/`unwrap`/`eval`, dependency bloat)
- Not in scope: security (security-auditor), runtime bugs (bug-auditor), performance (performance-auditor)
- Graceful skip: never skips

**Step 2:** Commit.

```bash
git add agents/code-quality-auditor.md && git commit -m "Add code-quality-auditor: code-agnostic, detects AI-specific code smells"
```

### Task 2.4: Write dependency-auditor agent

**Files:**
- Create: `agents/dependency-auditor.md`
- Output: `.claude/audits/AUDIT_DEPENDENCIES.md`

**Step 1:** Write `agents/dependency-auditor.md`. Must include:

- Frontmatter: `name: dependency-auditor`, `description: Checks dependencies for vulnerabilities, outdated packages, unused libraries, and license conflicts. Runs on any language.`
- Language detection: look for `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`, `build.gradle`, `composer.json`
- Checks:
  - Known vulnerabilities (run `npm audit`, `pip-audit`, `cargo audit`, etc. if available; otherwise analyze versions against known patterns)
  - Outdated packages (check for lock files, version pinning)
  - Unused dependencies (imported but not used in code)
  - License conflicts (GPL/AGPL in commercial-looking projects)
  - Dependency bloat (heavyweight libraries for trivial operations)
  - Supply chain risk (very new packages, single-maintainer, typosquatting patterns)
- Not in scope: security in application code (security-auditor)
- Graceful skip: when no dependency file is found, return SKIPPED

**Step 2:** Commit.

```bash
git add agents/dependency-auditor.md && git commit -m "Add dependency-auditor: multi-language dependency scanning"
```

### Task 2.5: Write documentation-auditor agent

**Files:**
- Create: `agents/documentation-auditor.md`
- Output: `.claude/audits/AUDIT_DOCUMENTATION.md`

**Step 1:** Write `agents/documentation-auditor.md`. Must include:

- Frontmatter: `name: documentation-auditor`, `description: Finds documentation gaps — missing READMEs, setup instructions, outdated comments, undocumented decisions. Runs on any language.`
- Checks:
  - README existence and completeness (setup instructions, purpose, prerequisites)
  - Setup reproducibility (can a new person get this running from docs alone?)
  - Inline documentation gaps (complex functions without explanation)
  - Outdated comments (TODO/FIXME/HACK/XXX counts and age)
  - API documentation (if API code exists)
  - Architecture documentation (for non-trivial projects)
  - CLAUDE.md / project memory (for AI-assisted projects)
- Bus factor assessment: rate 1-10 how hard it would be for someone new to take over
- Not in scope: code quality (code-quality-auditor)
- Graceful skip: never skips

**Step 2:** Commit.

```bash
git add agents/documentation-auditor.md && git commit -m "Add documentation-auditor: bus factor assessment, setup reproducibility check"
```

### Task 2.6: Write infrastructure-auditor agent

**Files:**
- Create: `agents/infrastructure-auditor.md`
- Output: `.claude/audits/AUDIT_INFRASTRUCTURE.md`

**Step 1:** Write `agents/infrastructure-auditor.md`. Must include:

- Frontmatter: `name: infrastructure-auditor`, `description: Checks infrastructure and configuration — environment variables, deployment settings, health checks, CORS, containerization. Runs on any language.`
- Language detection: look for Dockerfiles, docker-compose, terraform, CloudFormation, Kubernetes manifests, Vercel/Netlify config, `.env.example`, CI/CD configs
- Checks:
  - Environment variable management (.env.example exists, no hardcoded env-specific values)
  - Deployment configuration (production-ready settings, debug mode off)
  - Health checks (endpoint exists or equivalent)
  - CORS configuration (not wildcard in production)
  - Container configuration (if Docker: non-root user, minimal image, no secrets in build)
  - CI/CD pipeline (exists, runs tests, has quality gates)
  - SSL/TLS configuration
- Not in scope: security vulnerabilities in code (security-auditor), dependencies (dependency-auditor)
- Graceful skip: when no config/infra files found, return SKIPPED

**Step 2:** Commit.

```bash
git add agents/infrastructure-auditor.md && git commit -m "Add infrastructure-auditor: deployment readiness, env var management"
```

### Task 2.7: Write performance-auditor agent

**Files:**
- Create: `agents/performance-auditor.md`
- Output: `.claude/audits/AUDIT_PERFORMANCE.md`

**Step 1:** Write `agents/performance-auditor.md`. Must include:

- Frontmatter: `name: performance-auditor`, `description: Finds performance problems — slow algorithms, large files, unoptimized assets, resource-heavy patterns. Runs on any language.`
- Code-agnostic checks:
  - Algorithmic complexity (nested loops over collections, O(n^2) patterns)
  - Large file/bundle issues (unoptimized images, large static assets)
  - Resource-heavy patterns (loading everything into memory, no pagination, no streaming)
  - Missing caching (repeated expensive operations)
  - Database query patterns (queries inside loops — overlaps with database-auditor but from performance angle)
  - Startup/initialization overhead
- Not in scope: database schema/index issues (database-auditor), code quality (code-quality-auditor)
- Graceful skip: never skips

**Step 2:** Commit.

```bash
git add agents/performance-auditor.md && git commit -m "Add performance-auditor: algorithmic complexity, resource patterns"
```

### Task 2.8: Write database-auditor agent

**Files:**
- Create: `agents/database-auditor.md`
- Output: `.claude/audits/AUDIT_DATABASE.md`

**Step 1:** Write `agents/database-auditor.md`. Must include:

- Frontmatter: `name: database-auditor`, `description: Finds database problems — N+1 queries, missing indexes, schema issues, migration safety. Runs on any language with database code.`
- Language detection: look for ORM usage (Prisma, SQLAlchemy, ActiveRecord, GORM, Diesel, Eloquent, Hibernate), raw SQL files, migration directories, schema files
- Checks:
  - N+1 query patterns (queries inside loops, missing eager loading)
  - Missing indexes (queries filtering on unindexed columns)
  - Schema issues (missing constraints, wrong column types, no timestamps)
  - Migration safety (destructive migrations without rollback, data loss risk)
  - Connection management (connection pooling, connection leak patterns)
  - Transaction usage (operations that should be atomic but aren't)
- Not in scope: SQL injection (security-auditor), query performance tuning (performance-auditor for algorithmic patterns)
- Graceful skip: when no database code found, return SKIPPED

**Step 2:** Commit.

```bash
git add agents/database-auditor.md && git commit -m "Add database-auditor: N+1 detection, schema analysis, migration safety"
```

### Task 2.9: Write api-auditor agent

**Files:**
- Create: `agents/api-auditor.md`
- Output: `.claude/audits/AUDIT_API.md`

**Step 1:** Write `agents/api-auditor.md`. Must include:

- Frontmatter: `name: api-auditor`, `description: Checks API endpoints for design consistency, input validation, error responses, and rate limiting. Runs on any language with API code.`
- Language detection: look for route definitions (Express, FastAPI, Django, Gin, Actix, Laravel, Spring), OpenAPI/Swagger specs, GraphQL schemas
- Checks:
  - Endpoint consistency (naming conventions, HTTP method usage, response format uniformity)
  - Input validation (are request bodies/params validated before use?)
  - Error responses (consistent error format, appropriate status codes, no stack traces in production)
  - Rate limiting (exists or documented as not needed)
  - Pagination (large collections have pagination)
  - API documentation (OpenAPI spec, inline docs, or README coverage)
  - Versioning strategy (if multiple versions exist)
- Not in scope: security of endpoints (security-auditor), performance of endpoints (performance-auditor)
- Graceful skip: when no API code found, return SKIPPED

**Step 2:** Commit.

```bash
git add agents/api-auditor.md && git commit -m "Add api-auditor: endpoint consistency, validation, error handling"
```

---

## Group 3: Action Agents (3 agents — all independent, can be parallelized)

### Task 3.1: Rewrite fix-planner agent

**Files:**
- Rewrite: `agents/fix-planner.md`
- Output: `.claude/audits/FIXES.md`

**Step 1:** Rewrite `agents/fix-planner.md`. Key changes from original:

- Update audit sources list to match new agent names (AUDIT_CODE_QUALITY, AUDIT_DEPENDENCIES, AUDIT_DOCUMENTATION, AUDIT_INFRASTRUCTURE, AUDIT_API — replacing old names)
- Add layered output format to FIXES.md:
  - Executive summary at top ("X critical, Y important, Z minor across N audits")
  - Each fix item: plain-English description + why it matters + technical detail + effort estimate
- Severity = business impact framing (P1 = "users at risk", not "critical CVE")
- Deduplication algorithm: same as original (match by file + line + category)
- Non-programmer audience in all descriptions

**Step 2:** Commit.

```bash
git add agents/fix-planner.md && git commit -m "Rewrite fix-planner: updated audit sources, layered output, business-impact severity"
```

### Task 3.2: Rewrite code-fixer agent

**Files:**
- Rewrite: `agents/code-fixer.md`

**Step 1:** Rewrite `agents/code-fixer.md`. Key changes:

- Remove Next.js/TypeScript-specific patterns
- Code-agnostic: detect project language, follow existing patterns
- After each fix: explain in plain English what was changed and why
- Follows FIXES.md priorities (P1 first)
- Makes minimal changes (don't refactor surrounding code)
- Commits after each fix with descriptive message

**Step 2:** Commit.

```bash
git add agents/code-fixer.md && git commit -m "Rewrite code-fixer: code-agnostic, explains changes in plain English"
```

### Task 3.3: Rewrite test-runner agent

**Files:**
- Rewrite: `agents/test-runner.md`

**Step 1:** Rewrite `agents/test-runner.md`. Key changes:

- Auto-detect test framework: pytest, jest, mocha, cargo test, go test, rspec, phpunit, JUnit
- Run tests and report in layered format:
  - Executive summary: "X passed, Y failed, Z skipped"
  - Plain English: "The login feature tests all pass. The payment tests have 2 failures — [description of what's broken]."
  - Technical detail: specific test names, error messages, file locations
- If no tests exist: report SKIPPED with note "No test framework detected. Consider adding tests."
- Output to `.claude/audits/TEST_REPORT.md`

**Step 2:** Commit.

```bash
git add agents/test-runner.md && git commit -m "Rewrite test-runner: auto-detect framework, plain-English reporting"
```

---

## Group 4: Skills (8 skills — all independent, can be parallelized)

Each skill is a `skills/<name>/SKILL.md` file with YAML frontmatter. Skills orchestrate agents and present results to the user.

### Task 4.1: Write audit skill

**Files:**
- Create: `skills/audit/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: audit
description: Use when you want a comprehensive code review across all areas — security, bugs, quality, dependencies, documentation, infrastructure, performance, database, and API. Also use for weekly health checks or before releases.
---
```

Body: Instructions to detect project language, dispatch all 9 auditors in parallel as subagents, wait for completion, dispatch fix-planner, present executive summary to user.

**Step 2:** Commit.

```bash
git add skills/audit/SKILL.md && git commit -m "Add audit skill: full 9-auditor parallel dispatch"
```

### Task 4.2: Write quick-check skill

**Files:**
- Create: `skills/quick-check/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: quick-check
description: Use when you want a fast check before committing or after making changes — runs security, bug, and code quality checks only. Gives a GO/CONCERNS/STOP verdict.
---
```

Body: Dispatch security + bug + code-quality auditors in parallel (3 only). No fix-planner. Present GO/CONCERNS/STOP verdict with plain-English reasoning.

**Step 2:** Commit.

```bash
git add skills/quick-check/SKILL.md && git commit -m "Add quick-check skill: fast 3-auditor check with GO/STOP verdict"
```

### Task 4.3: Write review-code skill

**Files:**
- Create: `skills/review-code/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: review-code
description: Use when reviewing code you didn't write — contractor deliveries, GitHub repos you're pulling in, inherited projects, or open-source libraries you're incorporating. Guides you through a structured evaluation.
---
```

Body: Interactive workflow — ask context, explain codebase in plain English, optional SOW comparison, full 9-auditor suite, red flag scan, bus factor assessment, final verdict (Accept/Accept with conditions/Push back).

**Step 2:** Commit.

```bash
git add skills/review-code/SKILL.md && git commit -m "Add review-code skill: contractor/external code evaluation workflow"
```

### Task 4.4: Write pre-deploy skill

**Files:**
- Create: `skills/pre-deploy/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: pre-deploy
description: Use before deploying to production — checks security, infrastructure, dependencies, and API endpoints for deployment blockers. Gives a GO or BLOCKED verdict.
---
```

Body: Dispatch security + infrastructure + dependency + api auditors (4) in parallel. Single GO/BLOCKED verdict with plain-English reasoning.

**Step 2:** Commit.

```bash
git add skills/pre-deploy/SKILL.md && git commit -m "Add pre-deploy skill: deployment readiness gate"
```

### Task 4.5: Write explain skill

**Files:**
- Create: `skills/explain/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: explain
description: Use when you want to understand code, a file, a directory, or recent changes in plain English — no auditing, purely educational. Helps you learn what AI built for you.
---
```

Body: Read target (file, dir, diff, or whole project). Explain purpose, structure, key decisions, relationships. No auditing, no judgment. Offer to go deeper. Use `$ARGUMENTS` for the target path.

**Step 2:** Commit.

```bash
git add skills/explain/SKILL.md && git commit -m "Add explain skill: plain-English code translation"
```

### Task 4.6: Write health-report skill

**Files:**
- Create: `skills/health-report/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: health-report
description: Use when you want a single-page health dashboard of your codebase — red/yellow/green status across all areas. Designed to share with stakeholders or team members.
---
```

Body: Run full audit (or use recent results if <24h old). Generate single-page dashboard with emoji status per category, overall rating, top priority. Save to `.claude/audits/HEALTH_REPORT.md`. Designed to be copy-pasted.

**Step 2:** Commit.

```bash
git add skills/health-report/SKILL.md && git commit -m "Add health-report skill: stakeholder-ready dashboard"
```

### Task 4.7: Write compare skill

**Files:**
- Create: `skills/compare/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: compare
description: Use when you want to compare the current state of the codebase against a previous audit — shows what improved, what regressed, and trends over time.
---
```

Body: Run full audit. Save snapshot to `.claude/audits/snapshots/YYYY-MM-DD/`. Find most recent previous snapshot. Diff findings. Report: improved, regressed, unchanged, trend summary. If first audit, explain that next run will enable comparison.

**Step 2:** Commit.

```bash
git add skills/compare/SKILL.md && git commit -m "Add compare skill: audit trend tracking with snapshots"
```

### Task 4.8: Write language-advisor skill

**Files:**
- Create: `skills/language-advisor/SKILL.md`

**Step 1:** Write the skill. Frontmatter:

```yaml
---
name: language-advisor
description: Use when starting a new project or considering a language or framework change — recommends the right stack based on your goals, with honest tradeoffs about AI code generation quality and type safety.
---
```

Body: Interactive Q&A (what building, what matters most, who maintains). Recommend language + framework with rationale covering: fitness for use case, compile-time safety, AI generation quality, deployment simplicity, ecosystem maturity. Reference research findings on type safety as guardrail. Offer to create starter CLAUDE.md.

**Step 2:** Commit.

```bash
git add skills/language-advisor/SKILL.md && git commit -m "Add language-advisor skill: pre-project language/framework guidance"
```

---

## Group 5: Hooks

### Task 5.1: Write hook scripts

**Files:**
- Create: `hooks/scripts/detect-secrets.sh`
- Create: `hooks/scripts/check-env-files.sh`
- Create: `hooks/scripts/check-large-files.sh`
- Create: `hooks/scripts/change-size-nudge.sh`

**Step 1:** Write `hooks/scripts/detect-secrets.sh`:

```bash
#!/bin/bash
# Detect common secret patterns in staged files
# Exit code 2 = block the action

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

PATTERNS='(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9\-]{20,}|password\s*[=:]\s*["\x27][^"\x27]{4,}|secret\s*[=:]\s*["\x27][^"\x27]{4,})'

FOUND=""
for file in $STAGED; do
  if [ -f "$file" ]; then
    MATCHES=$(grep -nEi "$PATTERNS" "$file" 2>/dev/null | grep -v '\.example\|\.sample\|\.template\|test\|mock\|fake\|placeholder')
    if [ -n "$MATCHES" ]; then
      FOUND="$FOUND\n$file:\n$MATCHES\n"
    fi
  fi
done

if [ -n "$FOUND" ]; then
  echo "🔴 BLOCKED: Possible secrets detected in staged files:"
  echo -e "$FOUND"
  echo ""
  echo "If these are false positives (test data, examples), move the values to a"
  echo ".env.example file with placeholders, or rename the file with a .sample extension."
  echo "WARNING: Do not use --no-verify — it disables ALL pre-commit hooks, not just this one."
  echo "If these are real secrets, remove them and use environment variables instead."
  exit 2
fi

exit 0
```

**Step 2:** Write `hooks/scripts/check-env-files.sh`:

```bash
#!/bin/bash
# Block committing .env files (except .env.example, .env.sample, .env.template)
# Exit code 2 = block the action

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

BLOCKED=""
for file in $STAGED; do
  case "$file" in
    .env|.env.local|.env.production|.env.development|.env.staging|*/.env|*/.env.local)
      BLOCKED="$BLOCKED  - $file\n"
      ;;
  esac
done

if [ -n "$BLOCKED" ]; then
  echo "🔴 BLOCKED: Environment files should not be committed:"
  echo -e "$BLOCKED"
  echo "These files may contain secrets. Add them to .gitignore instead."
  echo "Use .env.example to document required variables (without real values)."
  exit 2
fi

exit 0
```

**Step 3:** Write `hooks/scripts/check-large-files.sh`:

```bash
#!/bin/bash
# Warn about files larger than 500KB being committed
# Exit code 2 = block the action

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

LARGE=""
for file in $STAGED; do
  if [ -f "$file" ]; then
    SIZE=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
    if [ "$SIZE" -gt 512000 ]; then
      SIZE_KB=$((SIZE / 1024))
      LARGE="$LARGE  - $file (${SIZE_KB}KB)\n"
    fi
  fi
done

if [ -n "$LARGE" ]; then
  echo "🔴 BLOCKED: Large files detected in staged changes:"
  echo -e "$LARGE"
  echo "Large binary files should not be committed to git."
  echo "Consider using Git LFS, a CDN, or .gitignore for these files."
  exit 2
fi

exit 0
```

**Step 4:** Write `hooks/scripts/change-size-nudge.sh`:

```bash
#!/bin/bash
# Advisory: suggest running quick-check when many files have changed
# Reads JSON from stdin (PostToolUse hook format)
# Exit code 0 = advisory only, does not block

INPUT=$(cat)
TOOL=$(echo "$INPUT" | grep -o '"tool":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$TOOL" != "Write" ] && [ "$TOOL" != "Edit" ]; then
  exit 0
fi

CHANGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((CHANGED + STAGED))

if [ "$TOTAL" -ge 5 ]; then
  echo "💡 You've changed $TOTAL files in this session. Consider running /code-guardian:quick-check before committing."
fi

exit 0
```

**Step 5:** Make scripts executable.

```bash
chmod +x hooks/scripts/*.sh
```

**Step 6:** Commit.

```bash
git add hooks/scripts/ && git commit -m "Add hook scripts: secret detection, env protection, large files, change nudge"
```

### Task 5.2: Write hooks.json

**Files:**
- Create: `hooks/hooks.json`

**Step 1:** Write `hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-secrets.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-env-files.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-large-files.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/change-size-nudge.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 2:** Commit.

```bash
git add hooks/hooks.json && git commit -m "Add hooks.json: pre-commit gates and post-edit nudge"
```

---

## Group 6: Documentation & Packaging

### Task 6.1: Write plugin CLAUDE.md

**Files:**
- Rewrite: `CLAUDE.md`

**Step 1:** Replace `CLAUDE.md` with a trimmed version of the current one, focused on:
- What code-guardian is (1 paragraph)
- Agent reference table (12 agents)
- Skill reference table (8 skills)
- Quick start examples
- Layered output format explanation
- Superpowers integration guide
- Key principles (code-agnostic, plain English, adversarial, business-impact severity)

Keep it under 200 lines. Remove the research sections (those live in docs/).

**Step 2:** Commit.

```bash
git add CLAUDE.md && git commit -m "Rewrite CLAUDE.md as code-guardian plugin reference"
```

### Task 6.2: Write README.md

**Files:**
- Rewrite: `README.md`

**Step 1:** Write a comprehensive README covering:
- What code-guardian is and who it's for
- Installation (marketplace, local dev, npm)
- Quick start (3 example commands)
- All 8 skills with descriptions and example usage
- All 12 agents with scope descriptions
- Output format explanation (layered)
- Hooks explanation (what auto-runs)
- Superpowers integration
- Configuration
- Contributing
- License

**Step 2:** Commit.

```bash
git add README.md && git commit -m "Rewrite README for code-guardian plugin"
```

### Task 6.3: Write package.json, LICENSE, CHANGELOG

**Files:**
- Rewrite: `package.json`
- Keep: `LICENSE` (verify MIT)
- Create: `CHANGELOG.md`

**Step 1:** Replace `package.json`:

```json
{
  "name": "code-guardian",
  "version": "1.0.0",
  "description": "Code-agnostic guardrails for non-programmers building with AI tools",
  "keywords": ["claude", "claude-code", "audit", "code-review", "non-programmer", "vibe-coding", "guardrails"],
  "author": "Colt Bradley",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/coltbradley/code-guardian.git"
  },
  "files": [
    "agents/",
    "skills/",
    "hooks/",
    ".claude-plugin/"
  ]
}
```

**Step 2:** Write `CHANGELOG.md`:

```markdown
# Changelog

## 1.0.0 (2026-03-23)

Initial release of code-guardian.

- 9 code-agnostic auditor agents (security, bugs, code quality, dependencies, documentation, infrastructure, performance, database, API)
- 3 action agents (fix-planner, code-fixer, test-runner)
- 8 workflow skills (audit, quick-check, review-code, pre-deploy, explain, health-report, compare, language-advisor)
- Automated hooks (secret detection, .env protection, large file warning, change size nudge)
- Layered output format (executive summary → plain English → technical detail)
- Designed for non-programmers building with AI tools
```

**Step 3:** Verify LICENSE exists and is MIT.

**Step 4:** Commit.

```bash
git add package.json CHANGELOG.md && git commit -m "Add package.json and CHANGELOG for code-guardian v1.0.0"
```

### Task 6.4: Write marketplace.json

**Files:**
- Create: `.claude-plugin/marketplace.json`

**Step 1:** Write marketplace.json:

```json
{
  "marketplace": "community",
  "category": "code-quality",
  "tags": ["audit", "code-review", "non-programmer", "vibe-coding", "guardrails", "security"],
  "pricing": "free",
  "changelog": {
    "1.0.0": "Initial release — 12 agents, 8 skills, automated hooks"
  }
}
```

**Step 2:** Commit.

```bash
git add .claude-plugin/marketplace.json && git commit -m "Add marketplace.json for plugin distribution"
```

---

## Group 7: Validation

### Task 7.1: Validate plugin loads correctly

**Step 1:** Run plugin validation.

```bash
claude plugin validate .
```

Expected: No errors. All 12 agents and 8 skills discovered.

**Step 2:** Test local loading.

```bash
claude --plugin-dir . --print-agents
```

Expected: All 12 agents listed.

**Step 3:** If validation fails, fix issues and re-validate.

**Step 4:** Commit any fixes.

### Task 7.2: Test a skill invocation

**Step 1:** Load plugin locally and invoke the explain skill on a small file.

```bash
claude --plugin-dir . -m "Use the code-guardian:explain skill on the CLAUDE.md file"
```

Expected: Plain-English explanation of the file. No errors.

**Step 2:** Test quick-check on the plugin's own code (meta-test).

```bash
claude --plugin-dir . -m "Use the code-guardian:quick-check skill on this project"
```

Expected: GO/CONCERNS/STOP verdict. Agents run, produce layered output.

### Task 7.3: Clean up and final commit

**Step 1:** Remove any leftover files from the old plugin that weren't caught in Group 1.

```bash
# Check for orphaned files
git status
ls -la
```

**Step 2:** Update .gitignore if needed (ensure `.claude/audits/` is ignored).

**Step 3:** Final commit.

```bash
git add -A && git commit -m "code-guardian v1.0.0: complete plugin with 12 agents, 8 skills, hooks"
```

---

## Task Summary

| Group | Tasks | Can Parallelize? | Depends On |
|-------|-------|-----------------|-----------|
| 1: Scaffolding | 1.1, 1.2, 1.3 | Sequential (1.1→1.2→1.3) | Nothing |
| 2: Auditor Agents | 2.1–2.9 | Yes, all 9 | Group 1 |
| 3: Action Agents | 3.1–3.3 | Yes, all 3 | Group 1 |
| 4: Skills | 4.1–4.8 | Yes, all 8 | Groups 2 & 3 (agents must exist for skills to reference) |
| 5: Hooks | 5.1–5.2 | Sequential (5.1→5.2) | Group 1 |
| 6: Docs & Packaging | 6.1–6.4 | Yes, all 4 | Groups 2–5 |
| 7: Validation | 7.1–7.3 | Sequential | All above |

**Total: 32 tasks across 7 groups.**

Groups 2, 3, and 5 can all run in parallel (they don't touch the same files).
Group 4 can run in parallel with Group 5 if agents from Groups 2–3 are done.
Group 6 can run in parallel within itself once Groups 2–5 are done.
