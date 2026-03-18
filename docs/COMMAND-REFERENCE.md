# Command Reference

All commands are invoked as slash commands within Claude Code (e.g., `/csiq-deploy`).

## Deploy and Retrieve

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-deploy` | Deploy source to target org with validation and tests | `--dry-run`, `--test-level`, `--wait`, `--target-org` | `/csiq-deploy --dry-run` |
| `/csiq-destructive-deploy` | Deploy with destructive changes (delete components) | `--manifest`, `--target-org`, `--dry-run` | `/csiq-destructive-deploy --manifest destructiveChanges.xml` |
| `/csiq-retrieve` | Retrieve metadata from an org to local source | `--target-org`, `--metadata`, `--package-name` | `/csiq-retrieve --metadata ApexClass` |
| `/csiq-validate` | Validate deployment without persisting changes | `--test-level`, `--target-org` | `/csiq-validate --test-level RunLocalTests` |

## Code Review

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-apex-review` | Apex code quality review using apex-reviewer agent | `--file`, `--severity` | `/csiq-apex-review --file AccountService.cls` |
| `/csiq-code-review` | General code review across all file types | `--file`, `--scope` | `/csiq-code-review` |
| `/csiq-lwc-review` | LWC component review for patterns and performance | `--component` | `/csiq-lwc-review --component accountSearch` |
| `/csiq-flow-review` | Flow design review for best practices | `--flow` | `/csiq-flow-review --flow Account_Automation` |
| `/csiq-soql-review` | SOQL query optimization and selectivity analysis | `--query` | `/csiq-soql-review --query "SELECT Id FROM Account"` |

## Testing

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-test` | Run Apex tests with coverage analysis | `--class`, `--suite`, `--coverage-target` | `/csiq-test --class AccountServiceTest` |
| `/csiq-lwc-test` | Run LWC Jest tests | `--component`, `--watch` | `/csiq-lwc-test --component accountSearch` |
| `/csiq-tdd` | Test-driven development workflow (Apex + LWC) | `--type`, `--name` | `/csiq-tdd --type apex --name AccountService` |
| `/csiq-test-data` | Generate test data factory for an sObject | `--sobject` | `/csiq-test-data --sobject Account` |

## Scaffolding

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-scaffold-trigger` | Generate trigger + handler boilerplate | `--sobject`, `--events` | `/csiq-scaffold-trigger --sobject Account` |
| `/csiq-scaffold-lwc` | Generate LWC component boilerplate | `--name`, `--targets` | `/csiq-scaffold-lwc --name accountSearch` |
| `/csiq-scaffold-apex` | Generate Apex class boilerplate | `--name`, `--type` | `/csiq-scaffold-apex --name AccountService --type service` |
| `/csiq-scaffold-batch` | Generate batch/schedulable class | `--name`, `--sobject` | `/csiq-scaffold-batch --name DataCleanupBatch` |
| `/csiq-scaffold-integration` | Generate callout class with Named Credential | `--name`, `--method` | `/csiq-scaffold-integration --name ExternalService` |
| `/csiq-scaffold-flow` | Generate flow metadata skeleton | `--name`, `--type` | `/csiq-scaffold-flow --name Account_Automation` |

## Analysis

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-governor-check` | Governor limit risk analysis | `--file`, `--threshold` | `/csiq-governor-check --file AccountTriggerHandler.cls` |
| `/csiq-security-scan` | CRUD/FLS, sharing, and injection scan | `--file`, `--scope` | `/csiq-security-scan --scope project` |
| `/csiq-metadata-analyze` | Analyze metadata dependencies and complexity | `--type` | `/csiq-metadata-analyze --type CustomObject` |
| `/csiq-data-model` | Analyze object relationships and field usage | `--sobject` | `/csiq-data-model --sobject Account` |
| `/csiq-org-health` | Org-wide health check (limits, technical debt) | `--target-org` | `/csiq-org-health` |

## Utilities

| Command | Description | Key Flags | Example |
|---------|-------------|-----------|---------|
| `/csiq-scratch-org` | Create and configure a scratch org | `--alias`, `--duration`, `--definition` | `/csiq-scratch-org --alias dev1` |
| `/csiq-package` | Package version creation and management | `--action`, `--name` | `/csiq-package --action create --name MyPackage` |
| `/csiq-explain-error` | Explain a Salesforce error message | `--error` | `/csiq-explain-error --error "FIELD_CUSTOM_VALIDATION_EXCEPTION"` |
| `/csiq-sf-help` | General Salesforce CLI help and guidance | `--topic` | `/csiq-sf-help --topic deployment` |

## Cross-References

Commands delegate to specialized agents for execution:

| Command | Primary Agent |
|---------|--------------|
| `/csiq-deploy` | deployment-specialist |
| `/csiq-apex-review` | apex-reviewer |
| `/csiq-test` | test-guide |
| `/csiq-governor-check` | governor-limits-checker |
| `/csiq-security-scan` | security-reviewer |
| `/csiq-lwc-review` | lwc-reviewer |
| `/csiq-soql-review` | soql-optimizer |
| `/csiq-flow-review` | flow-analyst |
| `/csiq-data-model` | data-modeler |
| `/csiq-metadata-analyze` | metadata-analyst |
| `/csiq-org-health` | admin-advisor |
| `/csiq-scaffold-integration` | integration-specialist |
