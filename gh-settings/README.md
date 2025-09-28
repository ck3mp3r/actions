# GitHub Settings Manager Action

A GitHub Action that idempotently manages repository settings including branch protection, merge policies, and security configurations. Perfect for enforcing organizational standards and maintaining compliance across repositories.

## Features

- **🔒 Branch Protection**: Configure linear history, required reviews, status checks
- **🔀 Merge Settings**: Control merge commits, squash merging, auto-merge
- **🤖 Bot Exceptions**: Allow bots like Renovate and Dependabot to bypass restrictions
- **📋 Idempotent**: Safe to run repeatedly, only applies necessary changes
- **🔍 Drift Detection**: Compare current vs desired settings
- **🧪 Dry Run**: Preview changes before applying
- **⏰ Scheduled Enforcement**: Run on schedule to maintain compliance

## Usage

### Basic Usage

```yaml
name: Manage Repository Settings
on:
  push:
    branches: [main]
    paths: ['.github/repo-config.yaml']
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM

jobs:
  settings:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Apply Repository Settings
        uses: ck3mp3r/actions/gh-settings@main
        with:
          gh-token: ${{ secrets.GITHUB_TOKEN }}
```

### Advanced Usage with Custom Settings

```yaml
- name: Apply Custom Settings
  uses: ck3mp3r/actions/gh-settings@main
  with:
    settings-file: '.github/custom-repo-config.yaml'
    gh-token: ${{ secrets.GITHUB_TOKEN }}
    dry-run: 'false'
```

### Comparison Mode

```yaml
- name: Check Settings Compliance
  uses: ck3mp3r/actions/gh-settings@main
  with:
    compare-only: 'true'
    gh-token: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

Create a `.github/repo-config.yaml` file in your repository:

> **Note**: This configuration format is **NOT** compatible with the GitHub Safe-Settings app. This is a custom format designed specifically for this action to avoid conflicts.

```yaml
repository:
  allow_merge_commit: false      # Disable merge commits
  allow_rebase_merge: true       # Enable rebase merging
  allow_squash_merge: true       # Enable squash merging
  allow_auto_merge: true         # Enable auto-merge
  delete_branch_on_merge: true   # Auto-delete feature branches
  allow_update_branch: true      # Allow updating PR branches

branch_protection:
  branch: main                   # Protected branch name
  required_pull_request_reviews:
    required_approving_review_count: 1
    dismiss_stale_reviews: true
    require_code_owner_reviews: false
    require_last_push_approval: false
    bypass_pull_request_allowances:
      apps:
        - "renovate[bot]"
        - "dependabot[bot]" 
        - "github-actions[bot]"
      users: []
      teams: []
  
  required_linear_history: true    # Enforce linear history (no merge commits)
  
  required_status_checks:
    strict: true                   # Require branches to be up to date
    contexts:                      # Required status checks
      - "ci/build"
      # - "test-suite"
      
  enforce_admins: true             # Apply rules to administrators
  required_conversation_resolution: true  # Require conversation resolution
  allow_force_pushes: false        # Block force pushes
  allow_deletions: false          # Block branch deletion
  block_creations: false          # Allow new branch creation
  lock_branch: false              # Don't lock the branch
  allow_fork_syncing: false       # Block fork syncing
  restrictions: null              # No push restrictions (rely on PRs)
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `settings-file` | Path to repository configuration file | No | `.github/repo-config.yaml` |
| `gh-token` | GitHub token for API access | No | `${{ github.token }}` |
| `dry-run` | Show what would be changed without applying | No | `false` |
| `compare-only` | Only compare current vs desired settings | No | `false` |

## Behavior

1. **First Run**: If no configuration file exists, generates a default configuration
2. **Subsequent Runs**: Applies settings from your configuration file
3. **Drift Detection**: Compares current repository settings with desired configuration
4. **Idempotent**: Only makes necessary changes, safe to run repeatedly

## Example Workflows

### Weekly Compliance Check

```yaml
name: Weekly Settings Compliance
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check Compliance
        uses: ck3mp3r/actions/gh-settings@main
        with:
          compare-only: 'true'
```

### Settings Enforcement on Changes

```yaml
name: Enforce Repository Settings
on:
  push:
    branches: [main]
    paths: ['.github/repo-config.yaml']

jobs:
  enforce:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Apply Settings
        uses: ck3mp3r/actions/gh-settings@main
```

### Pull Request Validation

```yaml
name: Validate Settings Changes
on:
  pull_request:
    paths: ['.github/repo-config.yaml']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Dry Run Settings
        uses: ck3mp3r/actions/gh-settings@main
        with:
          dry-run: 'true'
```

## Security

- Requires `contents: read` and `administration: write` permissions
- Uses repository's `GITHUB_TOKEN` by default
- All API calls use GitHub's official REST API via the GitHub CLI
- No external dependencies beyond GitHub's infrastructure

## Requirements

- GitHub repository with Actions enabled
- Appropriate permissions for the token used
- Nix package manager (automatically installed by the action)
- GitHub CLI (automatically installed via Nix)

## Troubleshooting

### Permission Errors
Ensure your token has `administration: write` permissions for the repository.

### Settings Not Applied
Check the action logs for specific error messages. Common issues:
- Invalid YAML syntax in settings file
- Missing required permissions
- Invalid configuration values

### No Settings File
The action will generate a default settings file on first run. Customize it for your needs and commit the changes.

## Contributing

This action uses Nushell and the GitHub CLI for configuration management. To contribute:
1. Modify `gh-settings.nu` for core functionality (uses `gh api` commands)
2. Update `action.yaml` for GitHub Actions integration
3. Test with different repository configurations
4. Update documentation as needed