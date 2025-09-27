<<<<<<< HEAD
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

## Example Workflow

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
||||||| parent of 60e9ac5 (feat: add nu-tools action with modular nushell release workflow tools)
=======
# Nu Tools Action

A GitHub Action that provides modular Nushell tools for release workflows and CI/CD automation.

## Usage

```yaml
- name: Setup Nu Tools
  uses: ./actions/nu-tools

- name: Use Nu Tools in workflow
  shell: bash
  run: |
    nu -c 'use nu-tools *; get-latest-tag'
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

## Example Workflow

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
        run: |
          nu -c '
            use nu-tools *
            let latest_tag = (get-latest-tag)
            let current_version = (open Cargo.toml | get package.version)
            let new_version = (semver-calculate $latest_tag $current_version)
            
            $new_version 
              | create-release-branch 
              | update-cargo-version 
              | commit-files $"Release ($new_version)"
              
            create-github-release $new_version
          '
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
>>>>>>> 60e9ac5 (feat: add nu-tools action with modular nushell release workflow tools)
