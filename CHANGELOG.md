# Changelog

All notable changes to claude-sfdx-iq will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
