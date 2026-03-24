# Agent Conventions

All auditor agents MUST follow these conventions. Do not restate them — reference this document.

## Audience

Your reports are read by NON-PROGRAMMERS who build software with AI tools. They cannot read code. Every finding must explain what is wrong, why it matters to their business or users, and what to do about it — in plain English. Never lead with code. Lead with consequences.

## Language-Agnostic

You are language-agnostic. Detect the project's language(s) from file extensions and dependency files (package.json, requirements.txt, go.mod, Gemfile, pom.xml, Cargo.toml, composer.json). Adapt checks accordingly. If a check doesn't apply to the detected language(s), skip it.

## Standard Exclusion List

When scanning code, always skip these directories:
- `node_modules`, `venv`, `.venv`, `__pycache__`, `dist`, `build`, `vendor`, `.git`

When using bash grep, append:
```
--exclude-dir=node_modules --exclude-dir=venv --exclude-dir=.venv --exclude-dir=__pycache__ --exclude-dir=dist --exclude-dir=build --exclude-dir=vendor --exclude-dir=.git
```

## Status Block Schema

Every audit report MUST begin with this exact set of fields. All fields are required — use `0` for counts and `[]` for empty lists, never omit a field.

```yaml
---
agent: [agent-name]
status: COMPLETE | PARTIAL | SKIPPED | ERROR
timestamp: [ISO 8601 timestamp]
duration: [seconds]
findings: [total count]
critical_count: [count]
important_count: [count]
minor_count: [count]
skipped_checks: [list of check names skipped, or empty list]
errors: [list of errors encountered, or empty list]
---
```

## Severity Levels

Use exactly these three levels. No other names (not "High", "Medium", "Low").

**Critical** — Users or data are at risk RIGHT NOW. Examples: exposed secrets, authentication bypass, data loss on normal usage paths.

**Important** — Problems that will cause real harm soon under normal conditions. Examples: missing input validation that causes errors, bugs on common user paths, performance issues that degrade the experience.

**Minor** — Worth fixing when time allows, no immediate risk. Examples: code cleanup, small optimizations, documentation gaps.

### Calibration Rules

- Theoretical risks that require unlikely conditions are **Minor at most**.
- If the suggested fix is more complex than the problem itself, downgrade to **Minor** or omit entirely.
- "Nice to have" improvements (architecture decision records, inline comments, documentation restructuring) are **not findings**. Only flag documentation that is factually wrong or dangerously misleading.
- Do not flag a pattern as a problem if the codebase already has a mitigation in place. Check for mitigations before reporting.

### Evidence Requirements

- Every finding MUST cite a specific file and line number with a concrete consequence.
- "This could theoretically cause X" is not a finding. "Line 42 of file.sh does X, which means Y will happen when Z" is a finding.
- Before including a finding, ask: can a non-programmer act on this? If the answer is no, it belongs in Minor at most, and the plain-English explanation must include enough context to make a decision.

## Output Format

Use this layered format so readers can stop as soon as they have enough context:

1. **Executive Summary** — One paragraph, plain English. State what was found and why it matters in business terms. Use severity counts.

2. **Findings** — One section per finding:
   - **Plain English:** What is wrong, in one sentence, no jargon
   - **Why it matters:** Business impact (data theft, downtime, user trust, maintenance cost)
   - **Severity:** Critical | Important | Minor
   - **Technical detail:** File path, line number, specific pattern found
   - **Suggested fix:** One sentence describing what needs to change

3. **Recommendations** — Prioritized checklist: Must Fix, Should Fix, Worth Considering.

## Check Ownership

Each check has exactly one owning agent. Do not duplicate checks. If your agent does not own a check, add a cross-reference note instead.

| Check Area | Owner | Other Agents: Do Not Duplicate |
|---|---|---|
| Rate limiting | api-auditor | security-auditor |
| CORS configuration | security-auditor | infrastructure-auditor |
| TODO/FIXME/HACK markers | documentation-auditor | code-quality-auditor |
| N+1 / DB queries in loops | database-auditor | performance-auditor |

## Execution Logging

Append to `.claude/audits/EXECUTION_LOG.md`:
```
| [timestamp] | [agent-name] | [status] | [duration]s | critical=[X] important=[X] minor=[X] | [errors] |
```

## Output Verification

Before completing:
1. Verify your output file was written with content beyond headers
2. If skipped, the status block must state the reason clearly
3. If no issues found, write "No issues detected" — never leave an empty file
