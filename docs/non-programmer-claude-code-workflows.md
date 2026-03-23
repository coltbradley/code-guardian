# Non-Programmer Workflows for Claude Code: Practical Playbooks

Research compiled March 2026. Focused on actionable, step-by-step workflows for people who do not write code but want to build and ship software using Claude Code.

---

## Table of Contents

1. [Foundational Concepts](#1-foundational-concepts)
2. [Workflow 1: Project Setup and Memory](#2-workflow-1-project-setup-and-memory)
3. [Workflow 2: The Describe-Build-Review Loop](#3-workflow-2-the-describe-build-review-loop)
4. [Workflow 3: Multi-Agent Teams for Parallel Work](#4-workflow-3-multi-agent-teams-for-parallel-work)
5. [Workflow 4: Automated Code Review Pipeline](#5-workflow-4-automated-code-review-pipeline)
6. [Workflow 5: Hooks for Automated QA](#6-workflow-5-hooks-for-automated-qa)
7. [Workflow 6: Skills and Custom Commands](#7-workflow-6-skills-and-custom-commands)
8. [Workflow 7: Deployment Without Coding](#8-workflow-7-deployment-without-coding)
9. [Workflow 8: The "AI Technical Co-Founder" Full Lifecycle](#9-workflow-8-the-ai-technical-co-founder-full-lifecycle)
10. [Prompt Engineering When You Cannot Read Code](#10-prompt-engineering-when-you-cannot-read-code)
11. [Claude Code Architecture Reference](#11-claude-code-architecture-reference)
12. [Sources](#12-sources)

---

## 1. Foundational Concepts

### What is "Vibe Coding"?

Term coined by Andrej Karpathy in February 2025. Collins Dictionary named it Word of the Year for 2025. The core idea: you describe *what* you want built in natural language, and the AI handles the *how* -- the code, logic, APIs, and database schema.

**The mindset shift:** You are not a coder. You are an "Outcome Engineer." Your job is to describe intent, user experience, and business logic clearly. Claude handles execution.

### The Single Most Important Rule

**Describe the WHAT, never the HOW.**

Bad prompt (tells Claude how):
```
Write a JavaScript function to filter a list of users by login date.
```

Good prompt (tells Claude what):
```
I want a dashboard where I can see all users who haven't logged in for 3 days
and send them a pre-written nudge email with one click.
```

### The Core Development Loop

Every stage of vibe coding follows this cycle:

```
Prompt (You) -> Generate (AI) -> Review (You + AI) -> Feedback (You) -> Iterate
```

You never skip the review step. AI is a tool, not a replacement for judgment.

---

## 2. Workflow 1: Project Setup and Memory

### Why This Matters

Claude Code loses all context between sessions unless you give it persistent memory. The `CLAUDE.md` file is that memory -- it tells Claude who you are, what you are building, and how you want things done. Companies using this approach report 45% faster development vs. standard chat.

### Step-by-Step Setup

**Step 1: Create your project folder**
```bash
mkdir my-project
cd my-project
```

**Step 2: Initialize git (your safety net)**
```bash
git init
```
Commit before every major AI generation step. Always. This is your rollback mechanism when Claude breaks something three prompts later.

**Step 3: Create CLAUDE.md with your first prompt**

Open Claude Code in your project directory:
```bash
claude
```

Then prompt:
```
Create a CLAUDE.md file for this project. Include:

## Vision
[Describe your product in 2-3 sentences]

## Tech Stack
Recommend a modern, scalable stack for [describe your app type].
I have zero coding experience.

## UI/UX Guidelines
[Describe aesthetic: "dark mode, minimalist, rounded corners, etc."]

## Business Logic
[Revenue model, core user flow, key features]

## What is NOT in scope
[Explicitly list what you are NOT building yet]

## Done Criteria
[What does "finished" look like for the MVP?]
```

**Step 4: Populate with reference materials**

Upload to your project folder:
- Brand guidelines / style references
- Screenshots of similar products you like
- Copy documents (About page text, homepage copy)
- Logo and asset files

Then tell Claude:
```
Read all the files in this folder. Update CLAUDE.md to reflect the brand
guidelines, copy style, and visual references I've added.
```

### Key Principle: Specification Before Code

Before touching any AI tool, write a spec document. A good spec answers:
- What are you building and why?
- Who is the user and what problem does it solve?
- What are the key features (and what is NOT in scope)?
- What are the edge cases?
- What does "done" look like?

Put this in CLAUDE.md. Claude reads it at the start of every session.

---

## 3. Workflow 2: The Describe-Build-Review Loop

### The Non-Programmer Development Sprint

**Phase 1: Define the end result (5 minutes)**

Do not describe the build process. Describe the finished product:
```
Build a clean homepage with a bold hero section, trust signals from
customer logos, three service category blocks, a testimonials carousel,
and a simple footer with social links.
```

**Phase 2: Provide visual references**

Upload screenshots of similar layouts:
```
Use this layout style as inspiration [screenshot]. Adapt it for my brand
colors and copy from the files in this folder.
```

**Phase 3: Point Claude at your existing files**
```
Before building anything, read all the files in this project folder.
Pay special attention to:
- about-brand.md (brand voice)
- homepage-copy.md (actual text to use)
- The logo files in /assets
```

**Phase 4: Work in incremental sprints**

One deliverable per prompt. This is critical.

```
Sprint 1: Build the homepage hero section only.
Sprint 2: Add the service category blocks.
Sprint 3: Add the testimonials section.
Sprint 4: Make everything mobile-responsive.
Sprint 5: Polish the copy and CTAs.
```

After each sprint, review what Claude built. Commit to git if it looks right:
```
git add -A && git commit -m "Sprint 1: homepage hero section"
```

**Phase 5: Review with common sense**

You cannot read code, but you CAN:
- Open the HTML file in a browser. Does it look right?
- Test on mobile (resize browser window). Does it break?
- Click every link and button. Do they work?
- Read all the text. Is it correct?

If something is wrong, describe it conversationally:
```
The testimonials section overlaps the footer on mobile.
Fix the spacing and keep everything consistent.
```

### Version Control Discipline

This is the single most important safety practice for non-programmers:

```
# Before every major change:
git add -A && git commit -m "describe what works right now"

# If Claude breaks something:
git diff                    # shows what changed
git checkout -- .           # rolls everything back to last commit
```

Think of git commits as "save points" in a video game. Save often.

---

## 4. Workflow 3: Multi-Agent Teams for Parallel Work

### What Subagents Are

Subagents are specialized AI workers that Claude spawns for specific tasks. Each gets its own 200K-token context window, its own instructions, and its own tool access. The main Claude session orchestrates them.

**Key distinction:**
- **Subagents**: Work within a single Claude session. Good for focused tasks.
- **Agent Teams**: Multiple independent Claude sessions coordinating together. Good for large parallel work.

### When to Use Each Pattern

| Pattern | Use When | Example |
|---------|----------|---------|
| **No subagent** | Simple, quick task | "Fix the typo on the About page" |
| **Single subagent** | Isolated task with lots of output | "Run all tests and tell me what fails" |
| **Parallel subagents** | 3+ independent tasks, no file overlap | "Research auth, database, and API modules" |
| **Sequential subagents** | Tasks with dependencies | "Design the schema, then build the API, then the frontend" |
| **Background subagent** | Research while you keep working | "Analyze the codebase structure" |

### Setting Up Custom Subagents

**Option A: Use the interactive `/agents` command**

In Claude Code, type:
```
/agents
```

Select "Create new agent" -> Choose scope (Personal or Project) -> "Generate with Claude" -> Describe what you want:

```
A code improvement agent that scans files and suggests improvements
for readability, performance, and best practices. It should explain
each issue, show the current code, and provide an improved version.
```

**Option B: Create agent files manually**

Create `.claude/agents/code-reviewer.md`:
```markdown
---
name: code-reviewer
description: Expert code review specialist. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a senior code reviewer. When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Review for: clarity, naming, error handling, security, test coverage
4. Provide feedback organized by priority:
   - Critical issues (must fix)
   - Warnings (should fix)
   - Suggestions (consider improving)
Include specific examples of how to fix issues.
```

**Option C: Pass agents via CLI (temporary, for testing)**
```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  },
  "debugger": {
    "description": "Debugging specialist for errors and test failures.",
    "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
  }
}'
```

### Practical Multi-Agent Workflow Example

Suppose you want to add a new "AI Insights" page to your app:

**Step 1: Parallel planning (tell Claude to dispatch agents simultaneously)**
```
I want to add an "AI Insights" page to the app. Spawn three agents in parallel:
1. A product manager agent to define user stories and business value
2. A UX designer agent to propose a simple UI covering all states
3. An engineer agent to outline the technical approach and estimate effort
```

**Step 2: Review the combined output**

Claude synthesizes findings from all three agents into a coherent plan.

**Step 3: Sequential implementation**
```
Now implement the plan. Have the engineer agent write the code, then
have the code reviewer agent validate it. If there are issues, loop
back to the engineer to fix them.
```

### The `/batch` Skill for Large-Scale Changes

For sweeping changes across many files:
```
/batch migrate all React class components to functional components with hooks
```

This built-in skill:
1. Researches your codebase
2. Decomposes work into 5-30 independent units
3. Presents a plan for your approval
4. Spawns one agent per unit in isolated git worktrees
5. Each agent implements, tests, and can open a PR

### Worktree Isolation

Subagents can run in isolated git worktrees -- separate copies of your repository. If the agent's changes fail, the worktree is cleaned up automatically. No risk to your main codebase.

Configure in agent definition:
```yaml
---
name: experimental-feature
description: Try building experimental features safely
isolation: worktree
---
```

### Cost Management for Agents

Token consumption scales with agents. Monitor with:
```
/cost
```

Cost-reduction strategies:
- Use `model: haiku` for simple research/exploration agents (fast, cheap)
- Use `model: sonnet` for focused implementation tasks (balanced)
- Reserve `model: opus` for complex reasoning and architecture decisions
- Set `maxTurns` in agent config to limit runaway agents
- Break cost loops: intervene after 3 failed attempts and clarify requirements

---

## 5. Workflow 4: Automated Code Review Pipeline

### Why This Matters for Non-Programmers

You cannot review code yourself. You need AI to review AI's code. Multiple independent reviewers catch different issues, reducing the chance of shipping bugs.

### Option A: Built-in `/code-review` Plugin (Simplest)

This ships with Claude Code. No installation needed.

**Prerequisites:**
- Git repository with GitHub remote
- GitHub CLI installed and authenticated (`brew install gh` then `gh auth login`)

**Usage:**
```
/code-review              # Review outputs to terminal
/code-review --comment    # Posts review as GitHub PR comment
```

**What it does:**
1. Checks if review is needed (skips trivial/already-reviewed PRs)
2. Gathers CLAUDE.md files for guideline context
3. Summarizes PR changes
4. Launches 4 parallel review agents:
   - 2x CLAUDE.md compliance agents (do changes follow your rules?)
   - 1x Bug detector (obvious bugs in changed code only)
   - 1x History analyzer (git blame context)
5. Scores each issue 0-100 for confidence
6. Filters out issues below 80 confidence (removes false positives)
7. Posts findings

**Customize the confidence threshold** by editing `commands/code-review.md` and changing `80` to your preferred number. Higher = stricter filtering, fewer comments.

### Option B: Claude Review Loop Plugin (Two-AI Review)

Uses a *different* AI (OpenAI Codex) to review Claude's code. Independent second opinion.

**Install:**
```bash
# Install Codex CLI first
npm install -g @openai/codex

# Install the plugin
/plugin marketplace add hamelsmu/claude-review-loop
/plugin install review-loop@hamel-review
```

**Usage:**
```
/review-loop Add user authentication with JWT tokens and test coverage
```

**What happens:**
1. Claude implements your request
2. When Claude tries to finish, a Stop hook intercepts
3. Generates a Codex review script
4. Up to 4 parallel Codex agents review the changes:
   - Diff Review (code quality, tests, OWASP security)
   - Holistic Review (architecture, documentation)
   - Next.js Review (if applicable)
   - UX Review (if frontend present)
5. Findings deduplicated and consolidated
6. Claude addresses feedback it agrees with
7. Only then does the cycle complete

**Cancel if needed:**
```
/cancel-review
```

### Option C: Custom Stop Hook Auto-Review

For a DIY approach, create a Stop hook that triggers a review subagent:

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Review all files modified in this session. Check for: obvious bugs, security issues, missing error handling, and violations of the project's CLAUDE.md guidelines. If issues found, respond with {\"ok\": false, \"reason\": \"description of issues\"}.",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

**Important:** Include `stop_hook_active` check to prevent infinite loops:
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.stop_hook_active' | grep -q true && exit 0 || echo '{\"ok\": false, \"reason\": \"Review not yet completed\"}'"
          }
        ]
      }
    ]
  }
}
```

---

## 6. Workflow 5: Hooks for Automated QA

### What Hooks Are

Hooks are shell commands that run automatically at specific points in Claude Code's lifecycle. They are *deterministic* -- they always run, unlike hoping Claude remembers to check something. Think of them as automated guard rails.

### Essential Hooks for Non-Programmers

#### Hook 1: Desktop Notification When Claude Needs You

Never watch the terminal. Get a desktop alert instead.

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```
(Linux: replace with `notify-send 'Claude Code' 'Claude needs your attention'`)

#### Hook 2: Auto-Format Code After Every Edit

Ensure consistent formatting without thinking about it.

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

#### Hook 3: Block Edits to Protected Files

Prevent Claude from modifying sensitive files like `.env` or `package-lock.json`.

Create `.claude/hooks/protect-files.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

Make executable and register:
```bash
chmod +x .claude/hooks/protect-files.sh
```

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

#### Hook 4: Run Tests Before Claude Stops

Ensure all tests pass before Claude declares it is done.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. If any tests fail, respond with {\"ok\": false, \"reason\": \"failing tests: [list them]\"}.",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

#### Hook 5: Re-inject Context After Compaction

When Claude's context fills up, it summarizes (compacts) the conversation. Important details get lost. This hook re-injects critical reminders.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: Always run tests before committing. Use Tailwind for styling. Current sprint: user authentication. Check CLAUDE.md for full context.'"
          }
        ]
      }
    ]
  }
}
```

#### Hook 6: Prompt-Based Quality Check

Have an AI model check whether all requested tasks are actually complete:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks the user requested are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains to be done\"}."
          }
        ]
      }
    ]
  }
}
```

### Hook Types Summary

| Type | What It Does | Best For |
|------|-------------|----------|
| `command` | Runs a shell command | Formatting, file protection, logging |
| `prompt` | Single LLM call (yes/no decision) | "Are all tasks done?" checks |
| `agent` | Multi-turn subagent with tool access | "Run tests and verify results" |
| `http` | POSTs to a URL | Team audit logging, external services |

### Viewing Your Hooks

Type `/hooks` in Claude Code to see all configured hooks grouped by event.

---

## 7. Workflow 6: Skills and Custom Commands

### What Skills Are

Skills are reusable instruction sets stored as Markdown files. They give Claude specialized knowledge or step-by-step workflows you can trigger with `/skill-name`. Think of them as "saved prompts with superpowers."

### Creating Your First Skill

**Step 1: Create the directory**
```bash
mkdir -p ~/.claude/skills/deploy
```

**Step 2: Write SKILL.md**

Create `~/.claude/skills/deploy/SKILL.md`:
```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite and verify all tests pass
2. Build the application for production
3. Push to Vercel/Netlify deployment target
4. Verify the deployment succeeded by checking the live URL
5. Report back what URL is now live
```

The `disable-model-invocation: true` prevents Claude from auto-running this. Only you can trigger it with `/deploy`.

**Step 3: Use it**
```
/deploy
```

### Essential Skills for Non-Programmers

#### Skill: Commit with Context
`.claude/skills/commit/SKILL.md`:
```yaml
---
name: commit
description: Create a well-described git commit
disable-model-invocation: true
---

1. Run git status and git diff to see all changes
2. Write a clear commit message that describes WHAT changed and WHY
3. Stage all relevant files (never stage .env or credentials)
4. Create the commit
5. Show the result
```

#### Skill: Fix Issue from GitHub
`.claude/skills/fix-issue/SKILL.md`:
```yaml
---
name: fix-issue
description: Fix a GitHub issue by number
disable-model-invocation: true
argument-hint: "<issue-number>"
---

Fix GitHub issue $ARGUMENTS:
1. Read the issue description using: gh issue view $ARGUMENTS
2. Understand the requirements fully
3. Implement the fix
4. Write tests to verify it works
5. Create a commit referencing the issue: "Fix #$ARGUMENTS: [description]"
```

Usage: `/fix-issue 42`

#### Skill: Code Explanation
`~/.claude/skills/explain-code/SKILL.md`:
```yaml
---
name: explain-code
description: Explains code with analogies and diagrams. Use when explaining how code works.
---

When explaining code, always include:
1. Start with an analogy comparing the code to everyday life
2. Draw an ASCII diagram showing the flow
3. Walk through step-by-step what happens
4. Highlight common mistakes or gotchas
Keep explanations conversational.
```

Usage: "How does the authentication system work?" (Claude auto-invokes this)

#### Skill: Simplify (Built-in)
```
/simplify focus on removing duplicate code
```
This built-in skill spawns three parallel review agents, aggregates findings, and applies fixes.

### Skills That Run in Subagents

Add `context: fork` to run a skill in isolation (separate context window):

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

### Dynamic Context Injection

Skills can run shell commands before sending content to Claude:

```yaml
---
name: pr-summary
description: Summarize the current pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request concisely.
```

### Skill Locations

| Location | Who Can Use It |
|----------|---------------|
| `~/.claude/skills/` | You, in all projects |
| `.claude/skills/` | Anyone who clones this project |
| Enterprise managed | All users in your organization |

---

## 8. Workflow 7: Deployment Without Coding

### The Simplest Path: Claude Code + GitHub + Netlify/Vercel

**Step 1: Create a GitHub repository**
```bash
git init
gh repo create my-project --public --source=. --remote=origin
```

**Step 2: Build your app with Claude Code**

Follow Workflow 2 (Describe-Build-Review loop) until you have a working app.

**Step 3: Push to GitHub**
```bash
git add -A
git commit -m "Initial working version"
git push -u origin main
```

**Step 4a: Deploy to Netlify**
- Go to netlify.com, sign up, click "Add new site" -> "Import an existing project"
- Connect your GitHub repo
- Netlify auto-detects build settings
- Click Deploy

Or use Claude Code with the Netlify skill:
```
Deploy this project to Netlify using the GitHub integration.
```

**Step 4b: Deploy to Vercel**

If you have the Vercel plugin:
```
/deploy
```

Or manually:
- Go to vercel.com, sign up, click "Add New" -> "Project"
- Import your GitHub repo
- Vercel auto-detects framework (Next.js, React, etc.)
- Click Deploy

**Step 5: Verify**
```
Check if the deployment at [URL] is working. Test the main user flows.
```

### Critical Deployment Checklist

Before deploying, ask Claude:
```
Before I deploy, check for:
1. Any hardcoded API keys or secrets in the code
2. Missing environment variables that need to be set
3. Any development-only settings that should be changed for production
4. Whether the build succeeds without errors
```

### Continuous Deployment

Once connected, every `git push` auto-deploys. Your workflow becomes:
```
1. Tell Claude what to change
2. Review the result
3. git add -A && git commit -m "description" && git push
4. Auto-deploys within minutes
```

---

## 9. Workflow 8: The "AI Technical Co-Founder" Full Lifecycle

### Phase 1: Ideation and Specification (Day 1)

```
I'm building [product description]. Act as my technical co-founder.

Help me create:
1. A product requirements document (PRD) with user stories
2. A recommended tech stack (I have zero coding experience)
3. An architecture diagram showing the main components
4. A phased development plan (MVP first, then iterations)
5. A list of third-party services I'll need (auth, payments, email, etc.)

Save all of this to CLAUDE.md so you remember it every session.
```

### Phase 2: MVP Sprint (Days 2-5)

**Create the project structure:**
```
Set up the project based on the PRD in CLAUDE.md.
Create the folder structure, install dependencies, and set up
the development environment. Don't build features yet -- just the skeleton.
```

**Build feature by feature:**
```
Build Feature 1 from the PRD: [user registration and login].
Follow the architecture in CLAUDE.md.
Write tests for it.
```

After each feature, commit:
```
/commit
```

**Run the review loop:**
```
/code-review
```

### Phase 3: Testing and Polish (Days 6-7)

```
Run the complete test suite. Fix any failures.
Then review the entire codebase for:
- Missing error handling
- Security vulnerabilities
- Performance issues
- Mobile responsiveness
Report findings organized by severity.
```

### Phase 4: Deploy (Day 7)

Follow Workflow 7 (Deployment).

### Phase 5: Iterate (Ongoing)

The ongoing loop:
```
1. Collect user feedback
2. Create GitHub issues for each request
3. /fix-issue [number] for each one
4. /code-review after changes
5. git push to auto-deploy
```

### Cost Management

| Action | How |
|--------|-----|
| Check session cost | `/cost` |
| Reduce recurring costs | Enable prompt caching (up to 90% reduction) |
| Use cheaper models for simple tasks | Set `model: haiku` in agent configs |
| Break cost loops | Intervene after 3 failed attempts, clarify requirements |
| Monitor like a cloud bill | Check `/cost` regularly, especially with multi-agent work |

**Approximate costs (2026):** Claude Max tier ~$200/month for 20x usage. Agent operations ~$0.30/hour.

### The "Final 20%" Problem

AI can build 80% of your app in hours, but the final 20% -- polishing, edge cases, and custom integrations -- often takes as long as the entire first 80%. Plan for this. Do not promise launch dates based on the initial velocity.

---

## 10. Prompt Engineering When You Cannot Read Code

### The FATA Framework

Research (arXiv 2508.08308, 2025) shows ~40% improvement with this approach:

1. **State your intent minimally:** "I want a dashboard showing user engagement metrics"
2. **Let Claude ask clarifying questions:** "What specific metrics? What time ranges? What user segments?"
3. **Answer the questions, then let Claude proceed**

### Structural Prompt Patterns

**The Spec-First Pattern:**
```
Before writing any code, create a specification document that includes:
- What the feature does
- What inputs it accepts
- What outputs it produces
- What error cases it handles
- What tests prove it works

Show me the spec. I'll approve it before you implement.
```

**The "Explain Before You Build" Pattern:**
```
I want [feature]. Before building it:
1. Explain your approach in plain English
2. List the files you'll create or modify
3. Describe what each file will do
4. Wait for my approval before writing code
```

**The "Test-First" Pattern:**
```
Before implementing [feature], write the tests first.
Show me the test descriptions in plain English.
I'll confirm they match what I expect. Then implement.
```

**The "Checkpoint" Pattern:**
```
Build [feature] in 3 stages:
Stage 1: [foundation]. Stop and show me. Don't proceed until I say OK.
Stage 2: [core logic]. Stop and show me. Don't proceed until I say OK.
Stage 3: [polish]. Stop and show me.
```

### Verification Prompts You Can Use Without Reading Code

```
Explain what this code does in plain English, as if I'm a product manager.
```

```
What are the three most likely ways this code could break?
What happens if the user does [unexpected thing]?
```

```
Run the test suite and tell me: how many tests pass, how many fail,
and for each failure, what feature is broken?
```

```
Show me a list of every user-visible change in this session.
For each change, describe what the user sees before and after.
```

```
Are there any security vulnerabilities in the code you just wrote?
Check for: exposed secrets, SQL injection, XSS, missing auth checks.
```

### When Claude Gets Stuck in a Loop

If Claude tries the same fix 3+ times without success:
```
Stop. Do not try to fix this again.
Instead:
1. Explain what the problem is in plain English
2. List 3 different approaches to solve it
3. For each approach, rate difficulty (1-5) and likelihood of success (1-5)
4. Wait for me to choose an approach
```

---

## 11. Claude Code Architecture Reference

### Subagents vs Tasks vs Agent Teams

| Feature | Subagents | Agent Teams |
|---------|-----------|-------------|
| **Scope** | Within one session | Across separate sessions |
| **Context** | Own 200K window | Own independent contexts |
| **Communication** | Results return to parent | Shared task list |
| **Parallelism** | Background or foreground | True independent parallelism |
| **Use case** | Focused tasks | Large coordinated projects |
| **Nesting** | Cannot spawn sub-subagents | Each agent can use subagents |

### Hook Events Quick Reference

| Event | When | Use For |
|-------|------|---------|
| `SessionStart` | Session begins/resumes/compacts | Inject context, setup |
| `UserPromptSubmit` | You send a prompt | Validate/transform prompts |
| `PreToolUse` | Before a tool runs | Block dangerous operations |
| `PostToolUse` | After a tool runs | Auto-format, logging |
| `PermissionRequest` | Permission dialog appears | Auto-approve known-safe actions |
| `Stop` | Claude finishes responding | Quality gates, auto-review |
| `SubagentStart/Stop` | Subagent lifecycle | Setup/cleanup for agents |
| `Notification` | Claude needs attention | Desktop alerts |
| `ConfigChange` | Settings file changes | Audit logging |

### Skill Frontmatter Quick Reference

| Field | What It Does |
|-------|-------------|
| `name` | The `/slash-command` name |
| `description` | When Claude should auto-invoke this |
| `disable-model-invocation: true` | Only you can trigger it |
| `user-invocable: false` | Only Claude can trigger it |
| `context: fork` | Run in isolated subagent |
| `agent: Explore` | Which agent type to use with `context: fork` |
| `allowed-tools` | Restrict available tools |
| `model` | Which AI model to use |
| `argument-hint` | Shown during autocomplete |

### Key Built-in Skills

| Skill | What It Does |
|-------|-------------|
| `/batch <instruction>` | Parallel large-scale changes across codebase (5-30 isolated agents) |
| `/simplify [focus]` | Three parallel review agents check for code reuse and quality |
| `/loop [interval] <prompt>` | Repeat a prompt on schedule (polling deploys, watching PRs) |
| `/debug [description]` | Troubleshoot your Claude Code session |
| `/code-review` | 4-agent parallel PR review with confidence scoring |

### Persistent Agent Memory

Agents can build up knowledge across sessions:

```yaml
---
name: code-reviewer
description: Reviews code with accumulated project knowledge
memory: project    # stored in .claude/agent-memory/code-reviewer/
---

Review code and update your agent memory with patterns and conventions
you discover. Check your memory before starting each review.
```

Memory scopes: `user` (all projects), `project` (this repo, shareable), `local` (this repo, not shareable).

---

## 12. Sources

### Official Documentation
- [Claude Code Overview](https://code.claude.com/docs/en/overview)
- [Create Custom Subagents](https://code.claude.com/docs/en/sub-agents)
- [Automate Workflows with Hooks](https://code.claude.com/docs/en/hooks-guide)
- [Extend Claude with Skills](https://code.claude.com/docs/en/skills)
- [Code Review Plugin](https://github.com/anthropics/claude-code/blob/main/plugins/code-review/README.md)
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices)

### Vibe Coding and Non-Programmer Workflows
- [How to Launch a Startup in 2026 Using Claude Code](https://stormy.ai/blog/claude-code-startup-playbook-2026)
- [Beyond the Chatbox: A Non-Technical Guide to Mastering Claude Code](https://medium.com/@vinayanand2/beyond-the-chatbox-a-non-technical-guide-to-mastering-claude-code-in-2026-8f7acd3a6e7d)
- [Claude Code Isn't Just for Developers](https://www.xda-developers.com/claude-code-isnt-just-for-developers/)
- [A Beginner's Guide to Vibe Coding with Claude Code](https://www.codeitbro.com/blog/claude-code-vibe-coding-guide)
- [Vibe Coding with AI: Best Practices (Towards Data Science)](https://towardsdatascience.com/vibe-coding-with-ai-best-practices-for-human-ai-collaboration-in-software-development/)
- [Vibe Coding 2026 Complete Guide](https://www.gauraw.com/vibe-coding-complete-guide-2026/)
- [Vibe Coding Guide 2025 (Appwrite)](https://appwrite.io/blog/post/the-complete-vibe-coding-guide-2025)

### Subagents and Multi-Agent Patterns
- [How to Use Claude Code Subagents to Parallelize Development](https://zachwills.net/how-to-use-claude-code-subagents-to-parallelize-development/)
- [Claude Code Sub-Agents: Parallel vs Sequential Patterns](https://claudefa.st/blog/guide/agents/sub-agent-best-practices)
- [The Task Tool: Claude Code's Agent Orchestration System](https://dev.to/bhaidar/the-task-tool-claude-codes-agent-orchestration-system-4bf2)
- [Claude Code: When to Use Task Tool vs Subagents](https://amitkoth.com/claude-code-task-tool-vs-subagents/)
- [Specialized AI Workflows with Claude Code Subagents](https://lgallardo.com/2025/08/02/claude-code-subagents-specialized-workflows/)

### Automated Review and Quality
- [Auto-Reviewing Claude's Code (O'Reilly)](https://www.oreilly.com/radar/auto-reviewing-claudes-code/)
- [Claude Review Loop Plugin](https://github.com/hamelsmu/claude-review-loop)
- [Building Automated Code Review Systems with Claude Code Hooks](https://jangwook.net/en/blog/en/claude-code-hooks-workflow/)
- [Claude Code Hooks: Practical Guide (eesel.ai)](https://www.eesel.ai/blog/hooks-in-claude-code)
- [Claude Code Part 8: Hooks for Automated Quality Checks](https://www.letanure.dev/blog/2025-08-06--claude-code-part-8-hooks-automated-quality-checks)
- [Automate AI Workflows with Claude Code Hooks (GitButler)](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks)

### SDK and Multi-Agent Orchestration
- [Claude Agent SDK Tutorial](https://letsdatascience.com/blog/claude-agent-sdk-tutorial)
- [Claude Agent SDK: Subagents, Sessions and Why It's Worth It](https://www.ksred.com/the-claude-agent-sdk-what-it-is-and-why-its-worth-understanding/)
- [Multi-Agent Orchestration: Running 10+ Claude Instances in Parallel](https://dev.to/bredmond1019/multi-agent-orchestration-running-10-claude-instances-in-parallel-part-3-29da)
- [Claude Code Swarm Orchestration Skill (GitHub Gist)](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Awesome Claude Code (Community Resource List)](https://github.com/hesreallyhim/awesome-claude-code)

### Deployment
- [Deployed a Real Website Using Claude Code + GitHub + Netlify](https://darbyarollins.substack.com/p/i-deployed-a-real-website-using-claude)
- [Claude Code Production Deployment Guide](https://www.hashbuilds.com/articles/claude-code-production-deployment-complete-pipeline-setup-guide)
- [Vercel Integration for Claude Code](https://vercel.com/docs/agent-resources/coding-agents/claude-code)

### Skills and Commands
- [Essential Claude Code Skills and Commands](https://batsov.com/articles/2026/03/11/essential-claude-code-skills-and-commands/)
- [Claude Code Customization Guide](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/)
- [Claude Command Suite (GitHub)](https://github.com/qdhenry/Claude-Command-Suite)
- [Production-Ready Slash Commands (GitHub)](https://github.com/wshobson/commands)
