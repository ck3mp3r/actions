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
      - uses: actions/checkout@v5
      
      - name: Generate GitHub App Token
        id: app-token
        uses: actions/create-github-app-token@v2.1.4.1.4
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
          permission-administration: write
          permission-contents: read
      
      - name: Apply Repository Settings
        uses: ck3mp3r/actions/gh-settings@main
        with:
          gh-token: ${{ steps.app-token.outputs.token }}
```

### Advanced Usage with Custom Settings

```yaml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v2.1.4
  with:
    app-id: ${{ vars.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
    permission-administration: write

- name: Apply Custom Settings
  uses: ck3mp3r/actions/gh-settings@main
  with:
    settings-file: '.github/custom-repo-config.yaml'
    gh-token: ${{ steps.app-token.outputs.token }}
    dry-run: 'false'
```

### Comparison Mode

```yaml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v2.1.4
  with:
    app-id: ${{ vars.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
    permission-administration: read

- name: Check Settings Compliance
  uses: ck3mp3r/actions/gh-settings@main
  with:
    compare-only: 'true'
    gh-token: ${{ steps.app-token.outputs.token }}
```

### Centralized Repository Management

Manage multiple repositories from a central management repository:

```yaml
name: Manage Team Repository Settings
on:
  push:
    branches: [main]
    paths: ['configs/**/*.yaml']
  schedule:
    - cron: '0 6 * * 1'  # Weekly enforcement

jobs:
  manage-repositories:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - repository: "myorg/frontend-app"
            config: "configs/frontend-app-config.yaml"
          - repository: "myorg/backend-api" 
            config: "configs/backend-api-config.yaml"
          - repository: "myorg/infrastructure"
            config: "configs/infrastructure-config.yaml"
    
    steps:
      - uses: actions/checkout@v5
      
      - name: Generate GitHub App Token
        id: app-token
        uses: actions/create-github-app-token@v2.1.4
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
          permission-administration: write
          repositories: ${{ matrix.repository }}
      
      - name: Apply Settings to ${{ matrix.repository }}
        uses: ck3mp3r/actions/gh-settings@main
        with:
          repository: ${{ matrix.repository }}
          settings-file: ${{ matrix.config }}
          gh-token: ${{ steps.app-token.outputs.token }}
```

**Repository Structure Example:**
```
management-repo/
├── .github/workflows/manage-repos.yaml
└── configs/
    ├── frontend-app-config.yaml
    ├── backend-api-config.yaml
    └── infrastructure-config.yaml
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
| `repository` | Target repository in format 'owner/repo' | No | Current repository |
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
      - uses: actions/checkout@v5
      
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
      - uses: actions/checkout@v5
      
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
      - uses: actions/checkout@v5
      
      - name: Dry Run Settings
        uses: ck3mp3r/actions/gh-settings@main
        with:
          dry-run: 'true'
```

## Security

- Requires `administration: write` permissions for repository and branch protection management
- Uses repository's `GITHUB_TOKEN` by default (may have limited permissions)
- All API calls use GitHub's official REST API via the GitHub CLI
- No external dependencies beyond GitHub's infrastructure

### Required Permissions

The action requires **repository administration** permissions to manage:
- Branch protection rules
- Repository merge settings
- Security and access policies

### Token Requirements

For full functionality, this action needs a token with `administration: write` permissions:

#### Option 1: GitHub App Token (Recommended)
GitHub Apps provide better security and fine-grained permissions:

```yaml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v2.1.4
  with:
    app-id: ${{ vars.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
    permission-administration: write
    permission-contents: read

- name: Apply Repository Settings
  uses: ck3mp3r/actions/gh-settings@main
  with:
    gh-token: ${{ steps.app-token.outputs.token }}
```

#### Option 2: Fine-grained Personal Access Token
If using a PAT, ensure it has the **Administration** repository permission:
- Scope: Repository access (specific repositories)
- Permissions: Administration (write)

#### Option 3: Workflow Permissions (Limited)
For basic repository settings (not branch protection), you may use `GITHUB_TOKEN` with enhanced permissions:

```yaml
permissions:
  contents: read
  administration: write  # Required for repository settings
```

**Note**: The default `GITHUB_TOKEN` typically lacks administration permissions for security reasons.

## Requirements

- GitHub repository with Actions enabled
- Appropriate permissions for the token used
- Nix package manager (automatically installed by the action)
- GitHub CLI (automatically installed via Nix)

## Troubleshooting

### Permission Errors
Ensure your token has `administration: write` permissions for the repository. The default `GITHUB_TOKEN` does not have administration permissions. Use a GitHub App token or fine-grained PAT with administration permissions.

### Settings Not Applied
Check the action logs for specific error messages. Common issues:
- Invalid YAML syntax in settings file
- Missing required permissions
- Invalid configuration values

### No Settings File
The action will generate a default settings file on first run. Customize it for your needs and commit the changes.

## GitHub App Setup

For the best security and functionality, set up a GitHub App:

1. **Create GitHub App**:
   - Go to your organization/user settings → Developer settings → GitHub Apps
   - Create a new GitHub App with these repository permissions:
     - Administration: Write (required for branch protection)
     - Contents: Read (optional, for reading configuration files)

2. **Install the App**:
   - Install the app on repositories where you want to manage settings
   - Note the App ID and generate a private key

3. **Configure Secrets**:
   - Add `APP_ID` as a repository/organization variable
   - Add `APP_PRIVATE_KEY` as a repository/organization secret (the full PEM content)

4. **Use in Workflows**:
   - Use `actions/create-github-app-token@v2.1.4` to generate tokens
   - Pass the token to the `gh-token` input

## Contributing

This action uses Nushell and the GitHub CLI for configuration management. To contribute:
1. Modify `gh-settings.nu` for core functionality (uses `gh api` commands)
2. Update `action.yaml` for GitHub Actions integration
3. Test with different repository configurations
4. Update documentation as needed