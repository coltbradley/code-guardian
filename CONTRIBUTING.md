# Contributing to Code Guardian

## Project Structure

```
.claude-plugin/          # Plugin metadata (plugin.json, marketplace.json)
agents/                  # 12 agent definitions (.md files)
skills/                  # 8 skill definitions (each in its own directory)
hooks/                   # Hook configuration and shell scripts
  scripts/               # Executable hook scripts (bash)
docs/                    # Research and design documents
package.json             # npm metadata (name, version, files list)
```

## Configuration Files

Three JSON files serve different purposes:

| File | Purpose |
|------|---------|
| `package.json` | npm package metadata — defines name, version, author, and which directories are included |
| `.claude-plugin/plugin.json` | Claude Code plugin descriptor — name, version, description, author |
| `.claude-plugin/marketplace.json` | Marketplace listing — owner, plugin name, source URL for remote install |

When releasing a new version, update the `version` field in both `package.json` and `.claude-plugin/plugin.json`.

## Testing Changes Locally

1. Clone the repo and make your changes
2. Point Claude Code at your local copy:
   ```bash
   claude --plugin-dir /path/to/claude-code-agents-review
   ```
3. Test hook scripts directly:
   ```bash
   chmod +x hooks/scripts/*.sh
   # Test secret detection
   echo '{"tool_name":"Bash"}' | bash hooks/scripts/detect-secrets.sh
   # Test env file blocking
   echo '{"tool_name":"Bash"}' | bash hooks/scripts/check-env-files.sh
   ```
4. Run a skill to verify agent changes:
   ```
   /code-guardian:quick-check
   ```

## Making Changes

### Agent definitions (`agents/*.md`)

- Each agent is a markdown file with YAML frontmatter
- Grep commands must use `grep -rEn` (extended regex) for macOS compatibility
- All grep commands must include `--exclude-dir` flags for: `node_modules`, `venv`, `.venv`, `__pycache__`, `dist`, `build`, `vendor`, `.git`
- Use `[[:space:]]` instead of `\s` in regex patterns (POSIX compatible)
- Severity labels must be: **Critical**, **Important**, **Minor**
- Status block fields must include: `critical_count`, `important_count`, `minor_count`

### Hook scripts (`hooks/scripts/*.sh`)

- Use `while IFS= read -r -d '' FILE; do ... done < <(git diff --cached --name-only -z)` for file iteration (handles spaces in filenames)
- Use `grep -E` instead of `grep -P` (BSD/macOS compatible)
- Pre-commit hooks exit with code 2 to block commits
- Post-tool hooks always exit 0 (advisory only)

### Skills (`skills/*/SKILL.md`)

- Reference agents by their exact filename (without `.md`): e.g., `code-quality-auditor`, not `code-auditor`
- The 9 auditors are: `security-auditor`, `bug-auditor`, `code-quality-auditor`, `dependency-auditor`, `documentation-auditor`, `infrastructure-auditor`, `performance-auditor`, `database-auditor`, `api-auditor`

## Publishing

1. Update `version` in `package.json` and `.claude-plugin/plugin.json`
2. Commit and push to the `main` branch
3. The marketplace entry in `.claude-plugin/marketplace.json` points to the GitHub repo URL — no separate publish step is needed

## Code Style

- Shell scripts: bash, POSIX-compatible where possible
- Agent/skill definitions: markdown with embedded bash in fenced code blocks
- No hardcoded rules in agents — all patterns go in the grep commands section
