# Code Guardian

Code Guardian is a code-agnostic guardrails plugin for non-programmers building with AI tools. It provides 12 specialized agents and 9 skills that analyze any codebase — regardless of language or framework — and report findings in plain English, translating technical risk into business impact so you can make informed decisions without needing to read the code yourself.

## Quick Start

```
/code-guardian:quick-check          # Fast check before committing
/code-guardian:audit                # Full comprehensive audit
/code-guardian:explain [path]       # Understand code in plain English
/code-guardian:review-code          # Evaluate external code before using it
```

For full details on all agents, skills, hooks, and troubleshooting, see [README.md](README.md).

## Architecture

- **Agents** (12): 9 auditors + 3 action agents. Each runs independently.
- **Skills** (9): Orchestration workflows that dispatch agents and present results.
- **Hooks** (4): Automatic safety checks on commits and edits.
- **Conventions**: Shared standards in `agents/CONVENTIONS.md`.

All audit output goes to `.claude/audits/`. Reports use a layered format: Executive Summary, Findings, Technical Detail.

## Key Principles

- **Code-agnostic** — works on any language, framework, or project type
- **Plain English first** — every finding explained as a business consequence
- **Adversarial by default** — looks for problems, not reassurance
- **Business-impact severity** — Critical, Important, Minor (defined in `agents/CONVENTIONS.md`)
- **Clear ownership** — each check has exactly one owning agent (see `agents/CONVENTIONS.md`)
