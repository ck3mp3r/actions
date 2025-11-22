# Nu Tools Action

A GitHub Action that provides modular Nushell tools for release workflows and CI/CD automation.

## Usage

```yaml
- name: Setup Nu Tools
  uses: ./actions/nu-tools

- name: Use Nu Tools in workflow
  shell: nu {0}
  run: |
    use nu-tools *
    get-latest-tag
```

## Modules

### semver.nu
- `semver-calculate`: Calculate semantic version based on tags

### git.nu  
- `get-latest-tag`: Get the latest git tag
- `create-release-branch`: Create and checkout release branch
- `commit-files`: Commit files with message
- `setup-git-user`: Setup git user for GitHub Actions
- `merge-and-cleanup`: Merge release branch and cleanup

### cargo.nu
- `update-cargo-version`: Update Cargo.toml version

### github.nu
- `create-github-release`: Create GitHub release with changelog
- `upload-release-artifacts`: Upload artifacts to release

### artifacts.nu
- `generate-platform-data`: Generate per-architecture data files
- `generate-platform-data-for`: Generate platform data for specific version

### homebrew.nu
- `update-homebrew-formula`: Update Homebrew formula with new version and architecture-specific hashes (accepts piped input)

### cachix.nu
- `publish-to-cachix`: Build flake and push missing store paths to Cachix cache
- `get-flake-dependencies`: Get all recursive dependencies for a flake output
- `check-cache-status`: Check cache status for store paths (accepts piped input)
- `get-missing-paths`: Get paths missing from both upstream and cachix caches (accepts piped input)
- `push-paths`: Push store paths to Cachix cache (accepts piped input)

## Example Workflows

### Release Workflow

```yaml
name: Release
on:
  push:
    branches: [main]
    
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Nu Tools
        uses: ./actions/nu-tools
        
      - name: Create Release
        shell: nu {0}
        run: |
          use nu-tools *
          let latest_tag = (get-latest-tag)
          let current_version = (open Cargo.toml | get package.version)
          let new_version = (semver-calculate $latest_tag $current_version)
          
          $new_version 
            | create-release-branch 
            | update-cargo-version 
            | commit-files $"Release ($new_version)"
            
          create-github-release $new_version
```

### Homebrew Formula Update

```yaml
- name: Update Homebrew Formula
  shell: nu {0}
  run: |
    use nu-tools *
    
    # Define architecture-specific hashes
    let architectures = [
      {name: "aarch64-apple-darwin", hash: "abc123..."},
      {name: "x86_64-apple-darwin", hash: "def456..."},
      {name: "aarch64-unknown-linux-gnu", hash: "ghi789..."},
      {name: "x86_64-unknown-linux-gnu", hash: "jkl012..."}
    ]
    
    # Update formula with piped input
    open formula.rb 
      | update-homebrew-formula "1.2.3" "my-binary" $architectures
      | save formula.rb
```

### Cachix Publishing

```yaml
- name: Publish to Cachix
  shell: nu {0}
  env:
    CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}
  run: |
    use nu-tools *
    
    # Simple: Build and push missing paths to cachix
    publish-to-cachix "ck3mp3r" --flake ".#mypackage"
    
    # Advanced: Custom pipeline with explicit steps
    get-flake-dependencies ".#myapp"
      | check-cache-status "ck3mp3r" --upstream "https://cache.nixos.org"
      | get-missing-paths "ck3mp3r"
      | push-paths "ck3mp3r"
```

## Requirements

- GitHub Actions runner (Linux or macOS)
- Git repository with proper permissions
- Nix package manager (automatically installed by the action)
- For Cargo integration: Rust project with Cargo.toml
- For GitHub integration: `gh` CLI or `GITHUB_TOKEN`

## Features

- **Nix-based Installation**: Uses nix for reliable, reproducible Nushell installation
- **Modular Design**: Organized into focused modules (semver, git, cargo, github, artifacts)
- **Release Management**: Complete release workflow automation
- **Cargo Integration**: Automatic version updates for Rust projects
- **GitHub Integration**: Release creation with automatic changelogs
- **Artifact Management**: Platform data generation for multi-architecture releases