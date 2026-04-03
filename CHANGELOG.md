# Changelog

All notable changes to claude-sfdx-iq will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.5.6] - 2026-04-03

### Fixed
- Hook command paths now use `${CLAUDE_PLUGIN_ROOT}` so scripts resolve correctly after plugin installation. Previously all 5 PostToolUse hooks used CWD-relative paths (`node scripts/hooks/<script>.js`) that broke when Claude Code was opened from a directory other than the plugin root.

### Removed
- `hooks/pre-commit.json` — used `PreToolUse` on `Bash` which fired on every bash command, not just git commits. The lint checks it ran (apex-lint, trigger-lint, lwc-lint) are already covered by PostToolUse hooks that fire on each file edit, making this hook redundant with unnecessary overhead on every bash invocation.
- Removed `pre-commit` from all 5 install manifests (`default`, `apex-only`, `minimal`, `admin`, `lwc-only`)

### Added
- `hooks/governor-scan.json` — PostToolUse on `**/*.cls`. Catches governor limit risks that apex-lint misses: `Database.query()`/`Database.insert()` dynamic DML variants, `System.enqueueJob()` in loops, HTTP callouts in loops, nested loop detection (stack-based tracker), and unbounded collection warnings.
- `hooks/destructive-warn.json` — PreToolUse on `Bash`. Intercepts destructive deploy commands, parses the destructiveChanges manifest, and lists exactly what metadata will be permanently deleted before the command executes. Near-zero overhead for non-destructive commands.
- `hooks/security-scan.json` — PostToolUse on `**/*.cls`. Adds hardcoded credentials/secrets detection, unjustified `without sharing` checks (requires inline justification comment), hardcoded URL detection, and deeper SOQL injection pattern analysis beyond what soql-check provides.
- `governor-scan` added to `default`, `apex-only`, and `minimal` manifests
- `destructive-warn` added to `default` and `admin` manifests
- `security-scan` added to `default` and `apex-only` manifests

## [1.5.5] - 2026-04-01

### Fixed
- Hook scripts now read file path from Claude Code's stdin JSON payload (`tool_input.file_path`) instead of relying on `$FILE` shell variable, which Claude Code does not set. Falls back to `process.argv[2]` for direct CLI use.
- Removed `"$FILE"` argument from all 5 PostToolUse hook commands (`apex-post-edit.json`, `trigger-post-edit.json`, `lwc-post-edit.json`, `soql-check.json`, `flow-post-edit.json`)

### Changed
- Updated `hooks/README.md` to list the actual 16 hook scripts (6 active, 10 available) replacing the outdated list of 8 non-existent script names

## [1.5.0] - 2026-03-23

### Changed
- Rewrote README.md for admin-friendly documentation
- Restructured installation guide with two clear paths (terminal vs Claude Code)
- Added dedicated "Commands for Admins" section
- Added "Who Is This For?" section with admin/developer/devops personas

### Added
- SECURITY.md for vulnerability reporting
- CODE_OF_CONDUCT.md for community standards
- GitHub issue and PR templates
- CHANGELOG.md for version tracking
- Salesforce trademark disclaimer in README

## [1.4.0] - 2026-03-22

### Changed
- Made skills non-user-invocable
- Updated setup-project script and command

## [1.3.0] - 2026-03-21

### Added
- setup-project command for per-project rule installation
- CLI tools available as slash commands

## [1.0.0] - Initial Release

### Added
- 14 specialized Salesforce agents
- 36 domain skills
- 53 slash commands
- 44 rules with dynamic loading via context-assigner
- 16 automated hook scripts
- 5 installation manifests (default, minimal, apex-only, lwc-only, admin)
- CLI tooling (doctor, repair, status, list, tokens)
- MCP server configurations
